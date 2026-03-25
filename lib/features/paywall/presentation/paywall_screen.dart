import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Ayla Plus')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              '✨ Unlock everything',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PriceCard(
            label: 'Monthly',
            price: '15,000 UZS / month',
            onTap: () => _showPaymentInstructions(context, monthly: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PriceCard(
            label: 'Yearly (save 33%)',
            price: '120,000 UZS / year',
            highlighted: true,
            onTap: () => _showPaymentInstructions(context, monthly: false),
          ),
        ],
      ),
    );
  }

  void _showPaymentInstructions(BuildContext context, {required bool monthly}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentSheet(monthly: monthly),
    );
  }

  static const _features = [
    'Period & ovulation predictions',
    'Fertile window indicator',
    'Full calendar view',
    'Symptom & mood logging',
    'Health tracking (weight, water, sleep)',
    'Pregnancy mode',
    'Partner sharing',
    'AI health assistant',
    'Premium articles',
    'Notifications & reminders',
    'Community posting',
  ];
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.label,
    required this.price,
    required this.onTap,
    this.highlighted = false,
  });
  final String label;
  final String price;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: highlighted ? AppColors.primary : AppColors.divider,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(price, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.monthly});
  final bool monthly;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text("We've received your request! Our team will activate your plan within 24 hours.",
                    style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment instructions', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Transfer ${widget.monthly ? '15,000' : '120,000'} UZS to card:\n\n'
                  '8600 0000 0000 0000\n\n'
                  'Comment: your registered email address.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Insert into payment_requests via PaymentRepository
                    setState(() => _submitted = true);
                  },
                  child: const Text("I've paid — notify us"),
                ),
              ],
            ),
    );
  }
}
