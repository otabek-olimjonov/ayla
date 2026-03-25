import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/auth_providers.dart';

part 'notification_settings_notifier.g.dart';

// ---------------------------------------------------------------------------
// Domain model
// ---------------------------------------------------------------------------

class NotificationSettings {
  const NotificationSettings({
    this.periodReminder = true,
    this.periodReminderDays = 2,
    this.ovulationReminder = true,
    this.pregnancyReminder = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  final bool periodReminder;
  final int periodReminderDays;
  final bool ovulationReminder;
  final bool pregnancyReminder;
  final int reminderHour;
  final int reminderMinute;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final timeStr = (json['reminder_time'] as String?) ?? '09:00';
    final parts = timeStr.split(':');
    return NotificationSettings(
      periodReminder: (json['period_reminder'] as bool?) ?? true,
      periodReminderDays: (json['period_reminder_days'] as int?) ?? 2,
      ovulationReminder: (json['ovulation_reminder'] as bool?) ?? true,
      pregnancyReminder: (json['pregnancy_reminder'] as bool?) ?? true,
      reminderHour: int.tryParse(parts.first) ?? 9,
      reminderMinute: int.tryParse(parts.last) ?? 0,
    );
  }

  Map<String, dynamic> toJson(String userId) => {
        'user_id': userId,
        'period_reminder': periodReminder,
        'period_reminder_days': periodReminderDays,
        'ovulation_reminder': ovulationReminder,
        'pregnancy_reminder': pregnancyReminder,
        'reminder_time':
            '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}',
      };

  NotificationSettings copyWith({
    bool? periodReminder,
    int? periodReminderDays,
    bool? ovulationReminder,
    bool? pregnancyReminder,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return NotificationSettings(
      periodReminder: periodReminder ?? this.periodReminder,
      periodReminderDays: periodReminderDays ?? this.periodReminderDays,
      ovulationReminder: ovulationReminder ?? this.ovulationReminder,
      pregnancyReminder: pregnancyReminder ?? this.pregnancyReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  static const _table = 'notification_settings';

  @override
  Future<NotificationSettings> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final client = ref.watch(supabaseClientProvider);
    try {
      final data = await client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .single();
      return NotificationSettings.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return const NotificationSettings();
      throw const NetworkFailure();
    } catch (_) {
      return const NotificationSettings();
    }
  }

  Future<void> save(NotificationSettings settings) async {
    final userId = ref.read(currentUserIdProvider);
    final client = ref.read(supabaseClientProvider);
    await client.from(_table).upsert(settings.toJson(userId));
    state = AsyncData(settings);
  }
}
