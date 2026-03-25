/// Represents a single logged event for a given day.
/// Maps to the `cycle_logs` table.
class CycleLog {
  const CycleLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.logType,
    this.value,
    this.intensity,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime logDate;
  final CycleLogType logType;
  final String? value;

  /// 1 = mild, 2 = moderate, 3 = severe. Null when not applicable.
  final int? intensity;
  final DateTime createdAt;

  factory CycleLog.fromJson(Map<String, dynamic> json) {
    return CycleLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      logType: CycleLogType.fromValue(json['log_type'] as String),
      value: json['value'] as String?,
      intensity: json['intensity'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'log_date': logDate.toIso8601String().split('T').first,
        'log_type': logType.value,
        'value': value,
        'intensity': intensity,
      };
}

enum CycleLogType {
  periodStart('period_start'),
  periodEnd('period_end'),
  spotting('spotting'),
  cramp('cramp'),
  headache('headache'),
  bloating('bloating'),
  moodHappy('mood_happy'),
  moodSad('mood_sad'),
  moodAnxious('mood_anxious'),
  moodCalm('mood_calm'),
  moodIrritable('mood_irritable'),
  note('note'),
  temperature('temperature'),
  dischargeNormal('discharge_normal'),
  dischargeUnusual('discharge_unusual');

  const CycleLogType(this.value);
  final String value;

  static CycleLogType fromValue(String value) {
    return CycleLogType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CycleLogType.note,
    );
  }
}
