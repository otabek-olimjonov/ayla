import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../../profile/domain/profile_notifier.dart';
import '../data/cycle_log_repository.dart';
import 'cycle_prediction_service.dart';

part 'cycle_prediction_notifier.g.dart';

/// Provides the live [CyclePrediction] for the current user.
/// Returns null when no period has been logged yet.
///
/// Automatically recomputes when profile settings or logs change.
@riverpod
Future<CyclePrediction?> cyclePrediction(CyclePredictionRef ref) async {
  final profile = await ref.watch(profileNotifierProvider.future);
  final userId = ref.watch(currentUserIdProvider);

  final lastPeriodStart = await ref
      .watch(cycleLogRepositoryProvider)
      .getLastPeriodStartDate(userId);

  return const CyclePredictionService().predict(
    lastPeriodStart: lastPeriodStart,
    cycleLength: profile.cycleLength,
    periodLength: profile.periodLength,
  );
}
