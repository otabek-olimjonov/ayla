import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/supabase/supabase_client_provider.dart';

part 'payment_repository.g.dart';

@riverpod
PaymentRepository paymentRepository(PaymentRepositoryRef ref) {
  return PaymentRepository(ref.watch(supabaseClientProvider));
}

class PaymentRepository {
  PaymentRepository(this._client);

  final SupabaseClient _client;

  /// Inserts a payment request into the `payment_requests` table.
  /// The admin will review and manually activate the plan within 24 hours.
  Future<void> submitPaymentRequest({
    required String userId,
    required String email,
  }) async {
    try {
      await _client.from('payment_requests').insert({
        'user_id': userId,
        'email': email,
        'status': 'pending',
      });
    } catch (_) {
      throw const NetworkFailure();
    }
  }
}
