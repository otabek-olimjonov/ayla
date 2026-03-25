import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/cycle_log_repository.dart';
import 'cycle_log.dart';

part 'today_logs_notifier.g.dart';

/// Loads today's [CycleLog] entries and allows toggling log types on/off.
/// Persists changes immediately to Supabase.
@riverpod
class TodayLogsNotifier extends _$TodayLogsNotifier {
  @override
  Future<List<CycleLog>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final today = _today;
    return ref.read(cycleLogRepositoryProvider).getLogsForDate(
          userId: userId,
          date: today,
        );
  }

  /// Returns true if [type] is already logged today.
  bool isLogged(CycleLogType type) {
    return state.valueOrNull?.any((l) => l.logType == type) ?? false;
  }

  /// Toggle [type]: creates a log if absent, deletes if present.
  Future<void> toggle(CycleLogType type, {int? intensity}) async {
    final userId = ref.read(currentUserIdProvider);
    final repo = ref.read(cycleLogRepositoryProvider);
    final existing = state.valueOrNull?.where((l) => l.logType == type).firstOrNull;

    if (existing != null) {
      await repo.deleteLog(existing.id);
    } else {
      final log = CycleLog(
        id: '', // Supabase generates the ID on insert
        userId: userId,
        logDate: _today,
        logType: type,
        intensity: intensity,
        createdAt: DateTime.now(),
      );
      await repo.upsertLog(log);
    }
    ref.invalidateSelf();
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
