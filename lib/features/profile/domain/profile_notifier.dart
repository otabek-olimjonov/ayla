import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/auth_providers.dart';
import '../../auth/domain/user_profile.dart';
import '../data/profile_repository.dart';

part 'profile_notifier.g.dart';

/// Loads and caches the current user's [UserProfile].
/// Use [ProfileNotifier.saveProfile] to persist changes (cycle length, mode, etc).
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<UserProfile> build() async {
    final userId = ref.watch(currentUserIdProvider);
    return ref.read(profileRepositoryProvider).getProfile(userId);
  }

  /// Persist a partial update and refresh the local cache.
  Future<void> saveProfile(UserProfile updated) async {
    await ref.read(profileRepositoryProvider).upsertProfile(updated);
    state = AsyncData(updated);
  }

  /// Switch between cycle and pregnancy mode.
  Future<void> switchMode(AppMode mode, {DateTime? pregnancyStart}) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    final updated = profile.copyWith(
      mode: mode,
      pregnancyStart: pregnancyStart,
    );
    await saveProfile(updated);
  }

  /// Update cycle length and/or period length.
  Future<void> updateCycleSettings({
    int? cycleLength,
    int? periodLength,
  }) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    await saveProfile(profile.copyWith(
      cycleLength: cycleLength,
      periodLength: periodLength,
    ));
  }
}
