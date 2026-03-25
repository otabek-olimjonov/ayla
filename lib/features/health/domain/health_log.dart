/// Represents a single health metric entry.
/// Maps to the `health_logs` table.
class HealthLog {
  const HealthLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.metric,
    required this.value,
    this.unit,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime logDate;
  final HealthMetric metric;
  final double value;
  final String? unit;
  final DateTime createdAt;

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    return HealthLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      metric: HealthMetric.fromValue(json['metric'] as String),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'log_date': logDate.toIso8601String().split('T').first,
        'metric': metric.value,
        'value': value,
        'unit': unit ?? metric.defaultUnit,
      };
}

enum HealthMetric {
  weight('weight', 'kg'),
  water('water', 'ml'),
  sleepHours('sleep_hours', 'hours');

  const HealthMetric(this.value, this.defaultUnit);
  final String value;
  final String defaultUnit;

  static HealthMetric fromValue(String value) {
    return HealthMetric.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HealthMetric.weight,
    );
  }
}
