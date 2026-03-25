import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// Provides the global [SupabaseClient] instance.
/// Always use this provider — never instantiate SupabaseClient directly.
@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}

/// Convenience extension to access the current authenticated user's ID.
/// Throws [AuthException] if not authenticated.
extension SupabaseClientX on SupabaseClient {
  String get currentUserId {
    final uid = auth.currentUser?.id;
    if (uid == null) throw const AuthException('User is not authenticated.');
    return uid;
  }
}
