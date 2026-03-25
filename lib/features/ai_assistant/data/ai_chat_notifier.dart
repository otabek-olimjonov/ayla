import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/auth_providers.dart';
import '../../cycle/domain/cycle_prediction_notifier.dart';
import '../../profile/domain/profile_notifier.dart';
import 'chat_message.dart';

part 'ai_chat_notifier.g.dart';

@riverpod
class AiChatNotifier extends _$AiChatNotifier {
  static const _table = 'ai_chat_messages';
  static const _edgeFunction = 'ai-chat';
  static const _maxContextMessages = 20;

  @override
  Future<List<ChatMessage>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final client = ref.watch(supabaseClientProvider);
    try {
      final data = await client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at')
          .limit(50);
      final rows = (data as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return rows;
    } catch (_) {
      return [];
    }
  }

  List<ChatMessage> get messages => state.valueOrNull ?? [];

  /// Sends a user message, persists it, calls the edge function and appends
  /// the assistant response.
  Future<void> sendMessage(String text) async {
    final userId = ref.read(currentUserIdProvider);
    final client = ref.read(supabaseClientProvider);

    // Append user message optimistically
    final userMsg = ChatMessage(
      id: '',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    state = AsyncData([...messages, userMsg]);

    // Persist user message
    try {
      await client.from(_table).insert({
        'user_id': userId,
        'role': 'user',
        'content': text,
      });
    } catch (_) {
      // Non-fatal — continue even if persistence fails
    }

    // Build context for the edge function
    final context = await _buildContext();
    final recentHistory = messages
        .where((m) => m.id.isNotEmpty)
        .toList()
        .reversed
        .take(_maxContextMessages)
        .toList()
        .reversed
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // Call edge function
    try {
      final response = await client.functions.invoke(
        _edgeFunction,
        body: {
          'message': text,
          'history': recentHistory,
          'context': context,
        },
      );

      final reply = (response.data as Map<String, dynamic>?)?['reply']
              as String? ??
          'Sorry, I could not process your request.';

      final assistantMsg = ChatMessage(
        id: '',
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );

      state = AsyncData([...messages, assistantMsg]);

      // Persist assistant response
      await client.from(_table).insert({
        'user_id': userId,
        'role': 'assistant',
        'content': reply,
      });
    } on FunctionException catch (_) {
      // Replace optimistic assistant placeholder with error message
      state = AsyncData([
        ...messages,
        ChatMessage(
          id: '',
          role: 'assistant',
          content:
              'I\'m having trouble connecting. Please try again.\n\n⚠️ This is not medical advice.',
          createdAt: DateTime.now(),
        ),
      ]);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<Map<String, dynamic>> _buildContext() async {
    final profile = await ref.read(profileNotifierProvider.future);
    final prediction =
        await ref.read(cyclePredictionProvider.future).catchError((_) => null);

    return {
      'mode': profile.mode.value,
      'cycleLength': profile.cycleLength,
      'phase': prediction?.phase.name,
      'cycleDay': prediction?.currentCycleDay,
      'pregnancyWeek': profile.pregnancyStart != null
          ? (DateTime.now().difference(profile.pregnancyStart!).inDays ~/ 7)
          : null,
      'language': profile.language,
    };
  }
}
