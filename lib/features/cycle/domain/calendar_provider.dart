import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../../profile/domain/profile_notifier.dart';
import '../data/cycle_log_repository.dart';
import '../domain/cycle_log.dart';
import '../domain/cycle_prediction_service.dart';

part 'calendar_provider.g.dart';

// ---------------------------------------------------------------------------
// Which month the calendar is currently showing
// ---------------------------------------------------------------------------

@riverpod
class CalendarFocusedMonth extends _$CalendarFocusedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void set(DateTime month) => state = DateTime(month.year, month.month);
}

// ---------------------------------------------------------------------------
// Loaded logs for the visible month (± 1 month buffer)
// ---------------------------------------------------------------------------

/// Maps a normalised date (year/month/day, no time component)
/// to the set of [CycleLogType]s logged on that day.
typedef DayLogMap = Map<DateTime, List<CycleLogType>>;

@riverpod
Future<DayLogMap> calendarLogs(CalendarLogsRef ref) async {
  final focusedMonth = ref.watch(calendarFocusedMonthProvider);
  final userId = ref.watch(currentUserIdProvider);

  // Load a 3-month window centred on the focused month
  final from = DateTime(focusedMonth.year, focusedMonth.month - 1);
  final to = DateTime(focusedMonth.year, focusedMonth.month + 2, 0); // last day of month+1

  final logs = await ref
      .read(cycleLogRepositoryProvider)
      .getLogsForRange(userId: userId, from: from, to: to);

  final map = <DateTime, List<CycleLogType>>{};
  for (final log in logs) {
    final key = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
    map.putIfAbsent(key, () => []).add(log.logType);
  }
  return map;
}

// ---------------------------------------------------------------------------
// Predicted date ranges derived from CyclePredictor
// ---------------------------------------------------------------------------

class CalendarPrediction {
  const CalendarPrediction({
    required this.periodDays,
    required this.fertileDays,
    required this.ovulationDay,
  });

  final Set<DateTime> periodDays;
  final Set<DateTime> fertileDays;
  final DateTime? ovulationDay;

  bool isPeriod(DateTime d) => periodDays.contains(_norm(d));
  bool isFertile(DateTime d) => fertileDays.contains(_norm(d));
  bool isOvulation(DateTime d) =>
      ovulationDay != null && _norm(d) == _norm(ovulationDay!);

  static DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);
}

@riverpod
Future<CalendarPrediction> calendarPrediction(
    CalendarPredictionRef ref) async {
  final profile = await ref.watch(profileNotifierProvider.future);
  final userId = ref.watch(currentUserIdProvider);

  final lastPeriod = await ref
      .read(cycleLogRepositoryProvider)
      .getLastPeriodStartDate(userId);

  final prediction = const CyclePredictionService().predict(
    lastPeriodStart: lastPeriod,
    cycleLength: profile.cycleLength,
    periodLength: profile.periodLength,
  );

  if (prediction == null) {
    return const CalendarPrediction(
      periodDays: {},
      fertileDays: {},
      ovulationDay: null,
    );
  }

  // Build the predicted period window (next period only)
  final periodDays = <DateTime>{};
  for (var i = 0; i < profile.periodLength; i++) {
    final d = prediction.nextPeriodDate.add(Duration(days: i));
    periodDays.add(DateTime(d.year, d.month, d.day));
  }

  // Fertile window
  final fertileDays = <DateTime>{};
  final fertileStart = prediction.fertileWindowStart;
  final fertileEnd = prediction.fertileWindowEnd;
  for (var d = fertileStart;
      !d.isAfter(fertileEnd);
      d = d.add(const Duration(days: 1))) {
    fertileDays.add(DateTime(d.year, d.month, d.day));
  }

  return CalendarPrediction(
    periodDays: periodDays,
    fertileDays: fertileDays,
    ovulationDay: prediction.ovulationDay,
  );
}
