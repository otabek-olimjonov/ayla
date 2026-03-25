import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/domain/user_profile.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
}

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'profiles';

  Future<UserProfile> getProfile(String userId) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') throw const NotFoundFailure();
      throw const NetworkFailure();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> upsertProfile(UserProfile profile) async {
    try {
      await _client.from(_table).upsert({
        'id': profile.id,
        ...profile.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> updatePartnerCode(String userId, String code) async {
    try {
      await _client
          .from(_table)
          .update({'partner_code': code})
          .eq('id', userId);
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
