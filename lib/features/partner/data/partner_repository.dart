import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/partner_link.dart';

part 'partner_repository.g.dart';

@riverpod
PartnerRepository partnerRepository(PartnerRepositoryRef ref) {
  return PartnerRepository(ref.watch(supabaseClientProvider));
}

class PartnerRepository {
  PartnerRepository(this._client);

  final SupabaseClient _client;

  static const _linksTable = 'partner_links';
  static const _profilesTable = 'profiles';

  // --------------------------------------------------------------------------
  // Partner code
  // --------------------------------------------------------------------------

  /// Generates a fresh 6-character alphanumeric code and persists it to the
  /// user's profile. Returns the new code.
  Future<String> generateAndSaveCode(String userId) async {
    final code = _randomCode();
    try {
      await _client
          .from(_profilesTable)
          .update({'partner_code': code})
          .eq('id', userId);
      return code;
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  /// Fetches the partner_code currently stored in the user's profile row.
  /// Returns null if none has been generated yet.
  Future<String?> getPartnerCode(String userId) async {
    try {
      final data = await _client
          .from(_profilesTable)
          .select('partner_code')
          .eq('id', userId)
          .single();
      return data['partner_code'] as String?;
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  // --------------------------------------------------------------------------
  // Linking
  // --------------------------------------------------------------------------

  /// Links the current user (partner) to the woman identified by [partnerCode].
  /// Returns the created [PartnerLink].
  Future<PartnerLink> linkByCode({
    required String currentUserId,
    required String partnerCode,
  }) async {
    try {
      // Look up the woman's user_id from her partner_code
      final profileData = await _client
          .from(_profilesTable)
          .select('id')
          .eq('partner_code', partnerCode)
          .single();

      final womanUserId = profileData['id'] as String;

      if (womanUserId == currentUserId) {
        throw const ValidationFailure('You cannot link to your own account.');
      }

      final result = await _client
          .from(_linksTable)
          .upsert({
            'user_id': womanUserId,
            'partner_user_id': currentUserId,
            'status': 'active',
          })
          .select()
          .single();

      return PartnerLink.fromJson(result);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const NotFoundFailure(); // partner code not found
      }
      throw const NetworkFailure();
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  /// Returns the active [PartnerLink] for [userId] (as the woman), or null.
  Future<PartnerLink?> getActiveLink(String userId) async {
    try {
      final data = await _client
          .from(_linksTable)
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (data == null) return null;
      return PartnerLink.fromJson(data);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  /// Revokes an active partner link by setting status → 'revoked'.
  Future<void> revokeLink(String linkId) async {
    try {
      await _client
          .from(_linksTable)
          .update({'status': 'revoked'})
          .eq('id', linkId);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  // --------------------------------------------------------------------------

  static String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O,0,I,1 to avoid confusion
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
