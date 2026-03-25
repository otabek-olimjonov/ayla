import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/health_log.dart';

part 'health_log_repository.g.dart';

@riverpod
HealthLogRepository healthLogRepository(HealthLogRepositoryRef ref) {
  return HealthLogRepository(ref.watch(supabaseClientProvider));
}

class HealthLogRepository {
  HealthLogRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'health_logs';

  Future<List<HealthLog>> getLogsForRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('log_date', from.toIso8601String().split('T').first)
          .lte('log_date', to.toIso8601String().split('T').first)
          .order('log_date');

      return (data as List).map((e) => HealthLog.fromJson(e)).toList();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> upsertLog(HealthLog log) async {
    try {
      await _client.from(_table).upsert(log.toInsertJson());
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
