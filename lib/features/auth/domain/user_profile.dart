/// Represents a user's extended profile stored in `profiles` table.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.birthYear,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.language = 'uz',
    this.planExpiresAt,
    this.mode = AppMode.cycle,
    this.pregnancyStart,
    this.partnerCode,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? birthYear;
  final int cycleLength;
  final int periodLength;
  final String language;
  final DateTime? planExpiresAt;
  final AppMode mode;
  final DateTime? pregnancyStart;
  final String? partnerCode;

  bool get isPaidPlanActive =>
      planExpiresAt != null && planExpiresAt!.isAfter(DateTime.now());

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      birthYear: json['birth_year'] as int?,
      cycleLength: (json['cycle_length'] as int?) ?? 28,
      periodLength: (json['period_length'] as int?) ?? 5,
      language: (json['language'] as String?) ?? 'uz',
      planExpiresAt: json['plan_expires_at'] != null
          ? DateTime.parse(json['plan_expires_at'] as String)
          : null,
      mode: AppMode.fromString(json['mode'] as String? ?? 'cycle'),
      pregnancyStart: json['pregnancy_start'] != null
          ? DateTime.parse(json['pregnancy_start'] as String)
          : null,
      partnerCode: json['partner_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'birth_year': birthYear,
        'cycle_length': cycleLength,
        'period_length': periodLength,
        'language': language,
        'mode': mode.value,
        'pregnancy_start': pregnancyStart?.toIso8601String().split('T').first,
      };

  UserProfile copyWith({
    int? birthYear,
    int? cycleLength,
    int? periodLength,
    String? language,
    DateTime? planExpiresAt,
    AppMode? mode,
    DateTime? pregnancyStart,
    String? partnerCode,
  }) {
    return UserProfile(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      birthYear: birthYear ?? this.birthYear,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      language: language ?? this.language,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      mode: mode ?? this.mode,
      pregnancyStart: pregnancyStart ?? this.pregnancyStart,
      partnerCode: partnerCode ?? this.partnerCode,
    );
  }
}

enum AppMode {
  cycle('cycle'),
  pregnancy('pregnancy');

  const AppMode(this.value);
  final String value;

  static AppMode fromString(String value) {
    return AppMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppMode.cycle,
    );
  }
}
