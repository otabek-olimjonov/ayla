import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/errors/failures.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/partner_repository.dart';
import '../domain/partner_link.dart';

part 'partner_screen.g.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@riverpod
class PartnerNotifier extends _$PartnerNotifier {
  @override
  Future<({String? code, PartnerLink? link})> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final repo = ref.read(partnerRepositoryProvider);
    final code = await repo.getPartnerCode(userId);
    final link = await repo.getActiveLink(userId);
    return (code: code, link: link);
  }

  Future<void> generateCode() async {
    final userId = ref.read(currentUserIdProvider);
    final newCode = await ref
        .read(partnerRepositoryProvider)
        .generateAndSaveCode(userId);
    final current = state.valueOrNull;
    state = AsyncData((code: newCode, link: current?.link));
  }

  Future<void> revokeLink() async {
    final link = state.valueOrNull?.link;
    if (link == null) return;
    await ref.read(partnerRepositoryProvider).revokeLink(link.id);
    final code = state.valueOrNull?.code;
    state = AsyncData((code: code, link: null));
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PartnerScreen extends ConsumerWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(partnerNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Sharing')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _PartnerBody(code: data.code, link: data.link),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _PartnerBody extends ConsumerWidget {
  const _PartnerBody({required this.code, required this.link});

  final String? code;
  final PartnerLink? link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(partnerNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // --- Your partner code section ---
        Text('Your partner code',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Share this code with your partner. They enter it in the Ayla app to view your cycle updates.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (code != null) ...[
          _CodeCard(code: code!),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => notifier.generateCode(),
            icon: const Icon(Icons.refresh),
            label: const Text('Generate new code'),
          ),
        ] else
          FilledButton(
            onPressed: () => notifier.generateCode(),
            child: const Text('Generate partner code'),
          ),

        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        const SizedBox(height: AppSpacing.md),

        // --- Linked partner section ---
        Text('Linked partner',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (link != null) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Partner connected'),
              subtitle: Text(
                'Since ${link!.createdAt.day}/${link!.createdAt.month}/${link!.createdAt.year}',
              ),
              trailing: TextButton(
                onPressed: () => _confirmRevoke(context, notifier),
                child: const Text(
                  'Revoke',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ] else
          Text(
            'No partner linked yet. Share your code with your partner.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    PartnerNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revoke access?'),
        content: const Text(
          'Your partner will no longer be able to see your cycle information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await notifier.revokeLink();
      } on AppFailure catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Code card widget
// ---------------------------------------------------------------------------

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            code,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            color: AppColors.primary,
            tooltip: 'Copy code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
