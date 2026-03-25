import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

part 'auth_providers.g.dart';

/// The currently authenticated [User], or null when signed out.
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
}

/// The current user's ID. Throws when unauthenticated.
/// Use this in repository calls so they always have a user_id.
@riverpod
String currentUserId(CurrentUserIdRef ref) {
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) throw const AuthException('User is not authenticated.');
  return uid;
}
