import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/auth_providers.dart';
import '../../health/data/health_log_repository.dart';
import '../../health/domain/health_log.dart';
import '../../profile/domain/profile_notifier.dart';
import '../data/cycle_log_repository.dart';
import '../domain/cycle_log.dart';
import '../domain/today_logs_notifier.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final dateLabel = '${today.day}/${today.month}/${today.year}';
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.log} — $dateLabel')),
      body: const SingleChildScrollView(child: LogBody()),
    );
  }
}

/// Embeddable log form — renders as a Column so it can live inside any scroll
/// view without nesting scrollables. Use [LogScreen] for a standalone page.
class LogBody extends ConsumerWidget {
  const LogBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = ref
            .watch(profileNotifierProvider)
            .valueOrNull
            ?.isPaidPlanActive ??
        false;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Period (free) ──────────────────────────────────
        _SectionHeader(
          title: l.logPeriod,
          icon: Icons.water_drop_outlined,
          color: AppColors.periodRed,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _LogChipRow(
          types: [
            CycleLogType.periodStart,
            CycleLogType.periodEnd,
            CycleLogType.spotting,
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Symptoms (paid) ───────────────────────────────
        _SectionHeader(
          title: l.symptoms,
          icon: Icons.healing_outlined,
          color: AppColors.secondary,
          isPaid: isPaid,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaidGate(
          isPaid: isPaid,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogChipRow(
                types: [
                  CycleLogType.cramp,
                  CycleLogType.headache,
                  CycleLogType.bloating,
                ],
                showIntensity: true,
              ),
              SizedBox(height: AppSpacing.sm),
              _LogChipRow(
                types: [
                  CycleLogType.dischargeNormal,
                  CycleLogType.dischargeUnusual,
                  CycleLogType.temperature,
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Mood (paid) ───────────────────────────────────
        _SectionHeader(
          title: l.logMood,
          icon: Icons.mood_outlined,
          color: AppColors.accent,
          isPaid: isPaid,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaidGate(
          isPaid: isPaid,
          child: const _LogChipRow(
            types: [
              CycleLogType.moodHappy,
              CycleLogType.moodSad,
              CycleLogType.moodAnxious,
              CycleLogType.moodCalm,
              CycleLogType.moodIrritable,
            ],
            moodMode: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Notes (paid) ──────────────────────────────────
        _SectionHeader(
          title: l.notes,
          icon: Icons.edit_note_outlined,
          color: AppColors.primary,
          isPaid: isPaid,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaidGate(
          isPaid: isPaid,
          child: const _NoteField(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Health (paid) ─────────────────────────────────
        _SectionHeader(
          title: l.healthMetrics,
          icon: Icons.monitor_weight_outlined,
          color: AppColors.fertileGreen,
          isPaid: isPaid,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaidGate(
          isPaid: isPaid,
          child: const _HealthMetricsSection(),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.isPaid = true,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (!isPaid) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            ),
            child: const Text(
              'Plus',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paywall gate — blurs content and shows upgrade CTA for free users
// ─────────────────────────────────────────────────────────────────────────────

class _PaidGate extends StatelessWidget {
  const _PaidGate({required this.isPaid, required this.child});
  final bool isPaid;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isPaid) return child;
    return Stack(
      children: [
        IgnorePointer(
          child: Opacity(opacity: 0.25, child: child),
        ),
        Positioned.fill(
          child: Center(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Builder(
                  builder: (ctx) {
                    final l = AppLocalizations.of(ctx);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline,
                            color: AppColors.primary, size: 22),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l.plusFeature,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                                const Size(140, 36),
                          ),
                          onPressed: () =>
                              context.push(AppRoutes.paywall),
                          child: Text(l.upgradeNow),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip row for cycle log types
// ─────────────────────────────────────────────────────────────────────────────

class _LogChipRow extends ConsumerWidget {
  const _LogChipRow({
    required this.types,
    this.showIntensity = false,
    this.moodMode = false,
  });

  final List<CycleLogType> types;
  final bool showIntensity;
  final bool moodMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayLogsNotifierProvider);
    final notifier = ref.read(todayLogsNotifierProvider.notifier);

    return logsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Text('Could not load logs'),
      data: (_) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: types.map((t) {
          final isLogged = notifier.isLogged(t);
          return FilterChip(
            label: Text(_label(context, t)),
            selected: isLogged,
            avatar: moodMode
                ? Text(_moodEmoji(t),
                    style: const TextStyle(fontSize: 16))
                : null,
            onSelected: (_) async {
              if (showIntensity && !isLogged) {
                final intensity =
                    await _pickIntensity(context);
                await notifier.toggle(t, intensity: intensity);
              } else {
                await notifier.toggle(t);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Future<int?> _pickIntensity(BuildContext context) async {
    final l = AppLocalizations.of(context);
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.severe),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l.mild),
              onTap: () => Navigator.pop(ctx, 1),
            ),
            ListTile(
              title: Text(l.moderate),
              onTap: () => Navigator.pop(ctx, 2),
            ),
            ListTile(
              title: Text(l.severe),
              onTap: () => Navigator.pop(ctx, 3),
            ),
          ],
        ),
      ),
    );
  }

  String _label(BuildContext context, CycleLogType t) {
    final l = AppLocalizations.of(context);
    return switch (t) {
      CycleLogType.periodStart => l.logTypePeriodStart,
      CycleLogType.periodEnd => l.logTypePeriodEnd,
      CycleLogType.spotting => l.logTypeSpotting,
      CycleLogType.cramp => l.logTypeCramp,
      CycleLogType.headache => l.logTypeHeadache,
      CycleLogType.bloating => l.logTypeBloating,
      CycleLogType.moodHappy => l.logTypeMoodHappy,
      CycleLogType.moodSad => l.logTypeMoodSad,
      CycleLogType.moodAnxious => l.logTypeMoodAnxious,
      CycleLogType.moodCalm => l.logTypeMoodCalm,
      CycleLogType.moodIrritable => l.logTypeMoodIrritable,
      CycleLogType.temperature => l.logTypeTemperature,
      CycleLogType.dischargeNormal => l.logTypeDischargeNormal,
      CycleLogType.dischargeUnusual => l.logTypeDischargeUnusual,
      CycleLogType.note => l.logTypeNote,
    };
  }

  String _moodEmoji(CycleLogType t) {
    const emojis = {
      CycleLogType.moodHappy: '😊',
      CycleLogType.moodSad: '😢',
      CycleLogType.moodAnxious: '😰',
      CycleLogType.moodCalm: '😌',
      CycleLogType.moodIrritable: '😤',
    };
    return emojis[t] ?? '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Note text field — persisted as a CycleLog with type = note
// ─────────────────────────────────────────────────────────────────────────────

class _NoteField extends ConsumerStatefulWidget {
  const _NoteField();

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-fill with existing note if any
      final logs = ref.read(todayLogsNotifierProvider).valueOrNull;
      final note =
          logs?.where((l) => l.logType == CycleLogType.note).firstOrNull;
      if (note != null) _ctrl.text = note.value ?? '';
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    final today = DateTime.now();
    await ref.read(cycleLogRepositoryProvider).upsertLog(
          CycleLog(
            id: '',
            userId: userId,
            logDate: DateTime(today.year, today.month, today.day),
            logType: CycleLogType.note,
            value: text,
            createdAt: today,
          ),
        );
    ref.invalidate(todayLogsNotifierProvider);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextField(
      controller: _ctrl,
      minLines: 2,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: l.notePlaceholder,
        suffixIcon: _saving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: _save,
                tooltip: l.save,
              ),
      ),
      onSubmitted: (_) => _save(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health metrics — weight, water, sleep
// ─────────────────────────────────────────────────────────────────────────────

class _HealthMetricsSection extends ConsumerStatefulWidget {
  const _HealthMetricsSection();

  @override
  ConsumerState<_HealthMetricsSection> createState() =>
      _HealthMetricsSectionState();
}

class _HealthMetricsSectionState
    extends ConsumerState<_HealthMetricsSection> {
  final _weightCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _sleepCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use null-safe provider — widget may render blurred before auth settles
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final today = DateTime.now();
    final logs = await ref.read(healthLogRepositoryProvider).getLogsForRange(
          userId: userId,
          from: DateTime(today.year, today.month, today.day),
          to: DateTime(today.year, today.month, today.day),
        );
    for (final l in logs) {
      switch (l.metric) {
        case HealthMetric.weight:
          _weightCtrl.text = l.value.toString();
        case HealthMetric.water:
          _waterCtrl.text = l.value.toString();
        case HealthMetric.sleepHours:
          _sleepCtrl.text = l.value.toString();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save(HealthMetric metric, String raw) async {
    final value = double.tryParse(raw);
    if (value == null) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final today = DateTime.now();
    await ref.read(healthLogRepositoryProvider).upsertLog(
          HealthLog(
            id: '',
            userId: userId,
            logDate: DateTime(today.year, today.month, today.day),
            metric: metric,
            value: value,
            createdAt: today,
          ),
        );
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waterCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        _HealthField(
          ctrl: _weightCtrl,
          label: l.weightKg,
          unit: 'kg',
          icon: Icons.monitor_weight_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          loading: _loading,
          onSave: () => _save(HealthMetric.weight, _weightCtrl.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        _HealthField(
          ctrl: _waterCtrl,
          label: l.waterMl,
          unit: 'ml',
          icon: Icons.water_drop_outlined,
          keyboardType: TextInputType.number,
          loading: _loading,
          onSave: () => _save(HealthMetric.water, _waterCtrl.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        _HealthField(
          ctrl: _sleepCtrl,
          label: l.sleepHours,
          unit: 'hrs',
          icon: Icons.bedtime_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          loading: _loading,
          onSave: () =>
              _save(HealthMetric.sleepHours, _sleepCtrl.text),
        ),
      ],
    );
  }
}

class _HealthField extends StatelessWidget {
  const _HealthField({
    required this.ctrl,
    required this.label,
    required this.unit,
    required this.icon,
    required this.keyboardType,
    required this.loading,
    required this.onSave,
  });

  final TextEditingController ctrl;
  final String label;
  final String unit;
  final IconData icon;
  final TextInputType keyboardType;
  final bool loading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: onSave,
                tooltip: 'Save',
              ),
      ),
      onSubmitted: (_) => onSave(),
    );
  }
}
