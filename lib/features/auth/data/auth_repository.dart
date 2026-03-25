import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(supabaseClientProvider).auth);
}

class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.ayla://login-callback/',
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw const NetworkFailure();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
