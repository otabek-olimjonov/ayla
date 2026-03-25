/// Pure domain service — no Supabase, no Flutter, no side effects.
/// All computation happens here; widgets never calculate predictions.
class CyclePredictionService {
  const CyclePredictionService();

  /// Returns prediction data, or null if no period has been logged yet.
  CyclePrediction? predict({
    required DateTime? lastPeriodStart,
    required int cycleLength,
    required int periodLength,
  }) {
    if (lastPeriodStart == null) return null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastStart = DateTime(
      lastPeriodStart.year,
      lastPeriodStart.month,
      lastPeriodStart.day,
    );

    final nextPeriod = lastStart.add(Duration(days: cycleLength));
    final fertileStart = nextPeriod.subtract(const Duration(days: 18));
    final fertileEnd = nextPeriod.subtract(const Duration(days: 11));
    final ovulationDay = nextPeriod.subtract(const Duration(days: 14));
    final rawCycleDay = todayDate.difference(lastStart).inDays + 1;
    final cycleDay = rawCycleDay < 1 ? 1 : rawCycleDay;
    final daysSinceLastPeriod = todayDate.difference(lastStart).inDays;
    final isIrregular = daysSinceLastPeriod > cycleLength + 14;

    return CyclePrediction(
      nextPeriodDate: nextPeriod,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      ovulationDay: ovulationDay,
      currentCycleDay: cycleDay,
      phase: _resolvePhase(cycleDay, cycleLength, periodLength),
      isIrregularWarning: isIrregular,
    );
  }

  CyclePhase _resolvePhase(int cycleDay, int cycleLength, int periodLength) {
    if (cycleDay <= periodLength) return CyclePhase.menstrual;
    final ovulationDay = cycleLength - 14;
    if (cycleDay < ovulationDay - 4) return CyclePhase.follicular;
    if (cycleDay <= ovulationDay + 1) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }
}

class CyclePrediction {
  const CyclePrediction({
    required this.nextPeriodDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.ovulationDay,
    required this.currentCycleDay,
    required this.phase,
    required this.isIrregularWarning,
  });

  final DateTime nextPeriodDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime ovulationDay;
  final int currentCycleDay;
  final CyclePhase phase;
  final bool isIrregularWarning;

  int get daysUntilNextPeriod {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return nextPeriodDate.difference(todayDate).inDays;
  }
}

enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal;

  String get label {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }
}
