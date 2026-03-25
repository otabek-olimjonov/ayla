extension DateTimeExtensions on DateTime {
  /// Returns today's date with time zeroed out.
  static DateTime get today => DateTime.now().toMidnight;

  /// Strips time component.
  DateTime get toMidnight => DateTime(year, month, day);

  /// Days between two dates (ignores time).
  int daysUntil(DateTime other) {
    final from = toMidnight;
    final to = other.toMidnight;
    return to.difference(from).inDays;
  }

  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Formats as "dd.MM.yyyy" (app standard short format).
  String toShortDate() =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';
}
