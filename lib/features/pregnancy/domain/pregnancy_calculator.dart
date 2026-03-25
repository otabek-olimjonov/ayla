/// Pure domain service for pregnancy calculations.
/// No Flutter, no Supabase — only math.
class PregnancyCalculator {
  const PregnancyCalculator();

  /// Returns pregnancy data based on LMP (Last Menstrual Period) date.
  PregnancyData calculate(DateTime lmpDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lmp = DateTime(lmpDate.year, lmpDate.month, lmpDate.day);

    final dueDate = lmp.add(const Duration(days: 280));
    final gestationalDays = todayDate.difference(lmp).inDays;
    final gestationalWeeks = (gestationalDays / 7).floor();
    final daysRemaining = dueDate.difference(todayDate).inDays;

    return PregnancyData(
      lmpDate: lmp,
      dueDate: dueDate,
      gestationalWeeks: gestationalWeeks.clamp(0, 42),
      daysRemaining: daysRemaining,
      trimester: _resolveTrimester(gestationalWeeks),
    );
  }

  Trimester _resolveTrimester(int weeks) {
    if (weeks < 13) return Trimester.first;
    if (weeks < 27) return Trimester.second;
    return Trimester.third;
  }
}

class PregnancyData {
  const PregnancyData({
    required this.lmpDate,
    required this.dueDate,
    required this.gestationalWeeks,
    required this.daysRemaining,
    required this.trimester,
  });

  final DateTime lmpDate;
  final DateTime dueDate;
  final int gestationalWeeks;
  final int daysRemaining;
  final Trimester trimester;

  bool get isOverdue => daysRemaining < 0;
}

enum Trimester {
  first,
  second,
  third;

  String get label {
    switch (this) {
      case Trimester.first:
        return 'First Trimester';
      case Trimester.second:
        return 'Second Trimester';
      case Trimester.third:
        return 'Third Trimester';
    }
  }
}
