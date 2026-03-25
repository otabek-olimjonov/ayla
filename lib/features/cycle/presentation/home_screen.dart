import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../auth/domain/user_profile.dart';
import '../../profile/domain/profile_notifier.dart';
import '../../pregnancy/domain/pregnancy_calculator.dart';
import '../domain/cycle_log.dart';
import '../domain/cycle_prediction_notifier.dart';
import '../domain/cycle_prediction_service.dart';
import '../domain/today_logs_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) => profile.mode == AppMode.pregnancy
          ? _PregnancyHomeBody(profile: profile)
          : _CycleHomeBody(profile: profile),
    );
  }
}

// ─────────────────────────────── CYCLE MODE ─────────────────────────────────

class _CycleHomeBody extends ConsumerWidget {
  const _CycleHomeBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(cyclePredictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'AI Assistant',
            onPressed: () => context.push(AppRoutes.aiChat),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cyclePredictionProvider);
          ref.invalidate(todayLogsNotifierProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            predictionAsync.when(
              loading: () => const _CycleDayCardSkeleton(),
              error: (_, __) => const _NoPeriodCard(),
              data: (prediction) => prediction == null
                  ? const _NoPeriodCard()
                  : _CycleDayCard(prediction: prediction),
            ),
            const SizedBox(height: AppSpacing.md),
            const _QuickLogRow(),
            const SizedBox(height: AppSpacing.md),
            predictionAsync.maybeWhen(
              data: (p) => p != null ? _InsightCard(prediction: p) : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleDayCardSkeleton extends StatelessWidget {
  const _CycleDayCardSkeleton();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
}

class _NoPeriodCard extends StatelessWidget {
  const _NoPeriodCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log your first period', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap "Period" below to start tracking your cycle.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleDayCard extends StatelessWidget {
  const _CycleDayCard({required this.prediction});
  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'Day\n${prediction.currentCycleDay}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prediction.phase.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${prediction.daysUntilNextPeriod} days until next period',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogRow extends ConsumerWidget {
  const _QuickLogRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayLogsNotifierProvider);
    final notifier = ref.read(todayLogsNotifierProvider.notifier);
    final isPeriodLogged =
        logsAsync.valueOrNull?.any((l) => l.logType == CycleLogType.periodStart) ?? false;

    return Row(
      children: [
        Expanded(
          child: _QuickLogButton(
            label: 'Period',
            icon: Icons.water_drop_outlined,
            color: AppColors.periodRed,
            active: isPeriodLogged,
            loading: logsAsync.isLoading,
            onTap: () => notifier.toggle(CycleLogType.periodStart),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickLogButton(
            label: 'Log',
            icon: Icons.edit_note_outlined,
            color: AppColors.secondary,
            active: false,
            loading: false,
            onTap: () => context.go(AppRoutes.log),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickLogButton(
            label: 'AI Chat',
            icon: Icons.chat_bubble_outline,
            color: AppColors.primary,
            active: false,
            loading: false,
            onTap: () => context.push(AppRoutes.aiChat),
          ),
        ),
      ],
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.active,
    required this.loading,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.25),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            loading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.prediction});
  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (prediction.isIrregularWarning) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Your cycle may be irregular. Consider logging your period or consulting a doctor.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Text(
          '⚠️ Predictions are estimates only. Consult a doctor for medical advice.',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

// ─────────────────────────────── PREGNANCY MODE ─────────────────────────────

class _PregnancyHomeBody extends StatelessWidget {
  const _PregnancyHomeBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = profile.pregnancyStart != null
        ? const PregnancyCalculator().calculate(profile.pregnancyStart!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'AI Assistant',
            onPressed: () => context.push(AppRoutes.aiChat),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (data != null) ...[
            _PregnancyWeekCard(data: data),
            const SizedBox(height: AppSpacing.md),
            _DueDateCard(data: data),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Text(
                  'Set your LMP date in Profile to enable pregnancy tracking.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PregnancyWeekCard extends StatelessWidget {
  const _PregnancyWeekCard({required this.data});
  final PregnancyData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.pregnancyBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'W${data.gestationalWeeks}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppColors.pregnancyBlue),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.trimester.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Week ${data.gestationalWeeks} of pregnancy',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueDateCard extends StatelessWidget {
  const _DueDateCard({required this.data});
  final PregnancyData data;

  @override
  Widget build(BuildContext context) {
    final label = data.isOverdue
        ? 'Due date passed'
        : '${data.daysRemaining} days until due date';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            const Icon(Icons.favorite_outline, color: AppColors.pregnancyBlue),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
