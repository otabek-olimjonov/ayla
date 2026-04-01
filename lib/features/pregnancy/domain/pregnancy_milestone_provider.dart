import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pregnancy_milestone_provider.g.dart';

/// A single weekly pregnancy milestone loaded from the bundled JSON asset.
class PregnancyMilestone {
  const PregnancyMilestone({
    required this.week,
    required this.title,
    required this.babySize,
    required this.description,
    required this.tips,
  });

  final int week;
  final String title;
  final String babySize;
  final String description;
  final List<String> tips;

  factory PregnancyMilestone.fromJson(Map<String, dynamic> json) {
    return PregnancyMilestone(
      week: json['week'] as int,
      title: json['title'] as String,
      babySize: json['babySize'] as String,
      description: json['description'] as String,
      tips: (json['tips'] as List).cast<String>(),
    );
  }
}

/// Loads all milestones from the bundled JSON once and returns the entry
/// closest to (but not exceeding) [gestationalWeeks].
@riverpod
Future<PregnancyMilestone?> pregnancyMilestone(
  PregnancyMilestoneRef ref, {
  required int gestationalWeeks,
}) async {
  final raw = await rootBundle
      .loadString('assets/pregnancy_milestones.json');
  final list = (jsonDecode(raw) as List)
      .map((e) => PregnancyMilestone.fromJson(e as Map<String, dynamic>))
      .toList();

  // Find the milestone whose week is <= gestationalWeeks, taking the highest one
  final candidates =
      list.where((m) => m.week <= gestationalWeeks).toList();
  if (candidates.isEmpty) return list.first;
  candidates.sort((a, b) => b.week.compareTo(a.week));
  return candidates.first;
}
