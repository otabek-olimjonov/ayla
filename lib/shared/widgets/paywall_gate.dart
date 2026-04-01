import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../features/profile/domain/profile_notifier.dart';

/// Blurs [child] and shows an upgrade card overlay when the user is on the
/// free plan. Renders [child] directly when the user has an active paid plan.
class PaywallGate extends ConsumerWidget {
  const PaywallGate({
    super.key,
    required this.child,
    this.blurSigma = 4.0,
    this.message = 'This feature requires Ayla Plus',
  });

  final Widget child;
  final double blurSigma;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid =
        ref.watch(profileNotifierProvider).valueOrNull?.isPaidPlanActive ??
            false;
    if (isPaid) return child;

    return Stack(
      children: [
        IgnorePointer(
          child: Opacity(opacity: 0.2, child: child),
        ),
        Positioned.fill(
          child: Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ayla Plus',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Upgrade now'),
                      onPressed: () => context.push(AppRoutes.paywall),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
