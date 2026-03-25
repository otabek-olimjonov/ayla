/// Base class for all domain-level failures in Ayla.
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

/// Supabase / network errors
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network error. Please try again.']);
}

/// Auth-related failures
final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

/// Data not found
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

/// Plan / paywall gating
final class PlanRequiredFailure extends AppFailure {
  const PlanRequiredFailure([super.message = 'This feature requires an active plan.']);
}

/// Validation errors
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// Unknown / unexpected errors
final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
