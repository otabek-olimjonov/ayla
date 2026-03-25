import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/cycle_log.dart';

part 'cycle_log_repository.g.dart';

@riverpod
CycleLogRepository cycleLogRepository(CycleLogRepositoryRef ref) {
  return CycleLogRepository(ref.watch(supabaseClientProvider));
}

class CycleLogRepository {
  CycleLogRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'cycle_logs';

  Future<List<CycleLog>> getLogsForRange({
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

      return (data as List).map((e) => CycleLog.fromJson(e)).toList();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<List<CycleLog>> getLogsForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('log_date', date.toIso8601String().split('T').first);

      return (data as List).map((e) => CycleLog.fromJson(e)).toList();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> upsertLog(CycleLog log) async {
    try {
      await _client.from(_table).upsert(log.toInsertJson());
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  /// Returns the most recent period_start date for the user.
  Future<DateTime?> getLastPeriodStartDate(String userId) async {
    try {
      final data = await _client
          .from(_table)
          .select('log_date')
          .eq('user_id', userId)
          .eq('log_type', CycleLogType.periodStart.value)
          .order('log_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return DateTime.parse(data['log_date'] as String);
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
