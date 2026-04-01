import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_profile.dart';
import '../../pregnancy/domain/pregnancy_calculator.dart';
import '../../pregnancy/domain/pregnancy_milestone_provider.dart';
import '../../profile/domain/profile_notifier.dart';
import '../domain/cycle_log.dart';
import '../domain/cycle_prediction_notifier.dart';
import '../domain/cycle_prediction_service.dart';
import '../domain/today_logs_notifier.dart';
import 'calendar_screen.dart';
import 'log_screen.dart';

String _phaseLabel(AppLocalizations l, CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual => l.phaseMenstrual,
      CyclePhase.follicular => l.phaseFollicular,
      CyclePhase.ovulation => l.phaseOvulation,
      CyclePhase.luteal => l.phaseLuteal,
    };

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile.mode == AppMode.pregnancy) {
          return _PregnancyHomeBody(profile: profile);
        }
        if (profile.mode == AppMode.planPregnancy) {
          return _PlanPregnancyHomeBody(profile: profile);
        }
        return _CycleHomeBody(profile: profile);
      },
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
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

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
          children: [
            // ── Cycle summary ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
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
                    data: (p) => p != null
                        ? _InsightCard(prediction: p)
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // ── Calendar section ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Text(
                l.calendar,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const CalendarBody(),

            // ── Log section ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Text(
                l.log,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const LogBody(),
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
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.logFirstPeriod, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.logFirstPeriodHint,
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
    final l = AppLocalizations.of(context);
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
                l.cycleDay(prediction.currentCycleDay),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_phaseLabel(l, prediction.phase), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l.daysUntilPeriod(prediction.daysUntilNextPeriod),
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
    final l = AppLocalizations.of(context);
    final logsAsync = ref.watch(todayLogsNotifierProvider);
    final notifier = ref.read(todayLogsNotifierProvider.notifier);
    final isPeriodLogged =
        logsAsync.valueOrNull?.any((l) => l.logType == CycleLogType.periodStart) ?? false;

    return Row(
      children: [
        Expanded(
          child: _QuickLogButton(
            label: l.logPeriod,
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
            label: l.aiAssistant,
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
    final l = AppLocalizations.of(context);
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
                  l.irregularCycle,
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
          '⚠️ ${l.predictionDisclaimer}',
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
            const SizedBox(height: AppSpacing.md),
            _MilestoneCard(gestationalWeeks: data.gestationalWeeks),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Text(
                  AppLocalizations.of(context).setLmpHint,
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
    final l = AppLocalizations.of(context);
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
                  Text(l.pregnancyWeek(data.gestationalWeeks),
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
    final l = AppLocalizations.of(context);
    final label = data.isOverdue
        ? l.dueDatePassed
        : l.daysUntilDue(data.daysRemaining);
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

class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({required this.gestationalWeeks});
  final int gestationalWeeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestoneAsync = ref.watch(
      pregnancyMilestoneProvider(gestationalWeeks: gestationalWeeks),
    );
    final theme = Theme.of(context);

    return milestoneAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (milestone) {
        if (milestone == null) return const SizedBox.shrink();
        return Card(
          color: AppColors.pregnancyBlue.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(
                color: AppColors.pregnancyBlue.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👶', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.pregnancyBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.pregnancyBlue.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                      ),
                      child: Text(
                        milestone.babySize,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.pregnancyBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(milestone.description, style: theme.textTheme.bodyMedium),
                if (milestone.tips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ...milestone.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: AppColors.pregnancyBlue,
                                  fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(tip,
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── PLAN PREGNANCY MODE ──────────────────────────────

class _PlanPregnancyHomeBody extends ConsumerWidget {
  const _PlanPregnancyHomeBody({required this.profile});
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
                  : _FertilityStatusCard(prediction: prediction),
            ),
            const SizedBox(height: AppSpacing.md),
            predictionAsync.maybeWhen(
              data: (p) => p != null
                  ? _FertileWindowCard(prediction: p)
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            const _QuickLogRow(),
            const SizedBox(height: AppSpacing.md),
            const _ConceptionTipCard(),
          ],
        ),
      ),
    );
  }
}

class _FertilityStatusCard extends StatelessWidget {
  const _FertilityStatusCard({required this.prediction});
  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final daysUntil = prediction.daysUntilOvulation;
    final isToday = prediction.isOvulationDay;
    final inWindow = prediction.isInFertileWindow;

    final Color accent;
    final String emoji;
    final String title;
    final String subtitle;

    if (isToday) {
      accent = AppColors.fertileGreen;
      emoji = '🌟';
      title = l.ovulationDayTitle;
      subtitle = l.ovulationDaySubtitle;
    } else if (inWindow) {
      accent = AppColors.fertileGreen;
      emoji = '🌱';
      title = l.fertileWindowTitle;
      subtitle = daysUntil > 0
          ? l.inFertileWindow(daysUntil)
          : l.fertileWindowEnding(-daysUntil);
    } else if (daysUntil > 0) {
      accent = AppColors.accent;
      emoji = '⏳';
      title = '${l.cycleDay(prediction.currentCycleDay)} — ${_phaseLabel(l, prediction.phase)}';
      subtitle = l.ovulationCountdown(daysUntil);
    } else {
      accent = AppColors.textSecondary;
      emoji = '🔄';
      title = l.waitingCycle;
      subtitle = l.periodCountdown(prediction.daysUntilNextPeriod);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: accent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FertileWindowCard extends StatelessWidget {
  const _FertileWindowCard({required this.prediction});
  final CyclePrediction prediction;

  String _fmt(DateTime d) => '${d.day}/${d.month}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final p = prediction;

    return Card(
      color: AppColors.fertileGreen.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: AppColors.fertileGreen.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.fertilityCalendar,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: AppColors.fertileGreen, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              color: AppColors.fertileGreen,
              label: l.fertileWindowLabel,
              value: '${_fmt(p.fertileWindowStart)} – ${_fmt(p.fertileWindowEnd)}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.circle,
              color: AppColors.accent,
              label: l.ovulationLabel,
              value: _fmt(p.ovulationDay),
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.water_drop_outlined,
              color: AppColors.periodRed,
              label: AppLocalizations.of(context).nextPeriodLabel,
              value: _fmt(p.nextPeriodDate),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).estimateDisclaimer,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ConceptionTipCard extends StatelessWidget {
  const _ConceptionTipCard();

  static const _tips = [
    'Track cervical mucus — egg-white consistency signals peak fertility.',
    'Basal body temperature rises slightly (0.2–0.5°C) after ovulation.',
    'Have regular intercourse every 1–2 days during your fertile window.',
    'Folic acid (400 mcg/day) is recommended when trying to conceive.',
    'Reduce stress — high cortisol levels can delay or suppress ovulation.',
    'Ovulation test kits detect the LH surge ~24–48 hours before ovulation.',
    'Healthy weight and regular moderate exercise improve fertility outcomes.',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final tip = _tips[dayOfYear % _tips.length];

    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(l.tipOfDay,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(tip, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
