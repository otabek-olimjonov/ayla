import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/l10n.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_profile.dart';
import '../domain/profile_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // ── Plan ──────────────────────────────────────
            _ProfileSection(
              title: l.plusPlan,
              children: [
                ListTile(
                  leading: Icon(
                    profile.isPaidPlanActive
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.primary,
                  ),
                  title: Text(l.currentPlan),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.isPaidPlanActive
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.divider,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.chipRadius),
                    ),
                    child: Text(
                      profile.isPaidPlanActive ? l.plusPlan : l.free,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: profile.isPaidPlanActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () => context.push(AppRoutes.paywall),
                ),
                if (profile.planExpiresAt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Expires: ${_dateLabel(profile.planExpiresAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Mode ──────────────────────────────────────
            _ProfileSection(
              title: l.trackingMode,
              children: [
                ListTile(
                  leading: Icon(
                    profile.mode == AppMode.pregnancy
                        ? Icons.child_friendly_outlined
                        : profile.mode == AppMode.planPregnancy
                            ? Icons.favorite_border_outlined
                            : Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(l.modeLabel),
                  trailing: Text(
                    switch (profile.mode) {
                      AppMode.pregnancy => l.pregnancyMode,
                      AppMode.planPregnancy => l.planPregnancyMode,
                      AppMode.cycle => l.cycleMode,
                    },
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  onTap: () =>
                      _showModePicker(context, ref, profile, l),
                ),
                if (profile.mode == AppMode.pregnancy &&
                    profile.pregnancyStart != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'LMP: ${_dateLabel(profile.pregnancyStart!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Cycle settings ────────────────────────────
            _ProfileSection(
              title: l.cycleSettingsTitle,
              children: [
                ListTile(
                  leading: const Icon(Icons.loop, color: AppColors.primary),
                  title: Text(l.cycleLength),
                  trailing: Text(
                    '${profile.cycleLength} ${l.days}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  onTap: () =>
                      _showDaysPicker(context, ref, profile, l, isCycle: true),
                ),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined,
                      color: AppColors.periodRed),
                  title: Text(l.periodLength),
                  trailing: Text(
                    '${profile.periodLength} ${l.days}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  onTap: () => _showDaysPicker(context, ref, profile, l,
                      isCycle: false),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Language ──────────────────────────────────
            _ProfileSection(
              title: l.appLanguage,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.language, color: AppColors.primary),
                  title: Text(l.appLanguage),
                  trailing: Text(
                    _languageLabel(profile.language),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  onTap: () =>
                      _showLanguagePicker(context, ref, profile),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Partner ───────────────────────────────────
            _ProfileSection(
              title: l.partnerSharing,
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite_outline,
                      color: AppColors.secondary),
                  title: Text(l.partnerSharing),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.partner),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Notifications ─────────────────────────────
            _ProfileSection(
              title: l.notifications,
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary),
                  title: Text(l.notifications),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(AppRoutes.notificationSettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Reports ───────────────────────────────────
            _ProfileSection(
              title: l.healthReport,
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.primary),
                  title: Text(l.exportPdf),
                  subtitle: Text(l.healthReport),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.report),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Sign out ──────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              label: Text(l.signOut),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _languageLabel(String lang) {
    const labels = {
      'uz': 'Uzbek (Lotin)',
      'uz_CY': 'Ўзбекча (Кирилл)',
      'ru': 'Русский',
      'en': 'English',
    };
    return labels[lang] ?? lang;
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _showDaysPicker(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    AppLocalizations l, {
    required bool isCycle,
  }) async {
    final current = isCycle ? profile.cycleLength : profile.periodLength;
    final range = isCycle
        ? List.generate(35 - 20 + 1, (i) => i + 20)
        : List.generate(10 - 2 + 1, (i) => i + 2);
    final title = isCycle ? l.cycleLength : l.periodLength;

    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _PickerDialog(
        title: title,
        values: range,
        selected: current,
        unit: l.days,
        saveLabel: l.save,
        cancelLabel: l.cancel,
      ),
    );
    if (picked == null) return;
    await ref.read(profileNotifierProvider.notifier).updateCycleSettings(
          cycleLength: isCycle ? picked : null,
          periodLength: isCycle ? null : picked,
        );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    const langs = {
      'uz': 'Uzbek (Lotin)',
      'uz_CY': 'Ўзбекча (Кирилл)',
      'ru': 'Русский',
      'en': 'English',
    };
    final l = AppLocalizations.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.appLanguage),
        children: langs.entries.map((e) {
          final isSelected = e.key == profile.language;
          return ListTile(
            title: Text(e.value),
            trailing: isSelected
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(ctx, e.key),
          );
        }).toList(),
      ),
    );
    if (picked == null || picked == profile.language) return;
    final updated = profile.copyWith(language: picked);
    await ref.read(profileNotifierProvider.notifier).saveProfile(updated);
  }

  Future<void> _showModePicker(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    AppLocalizations l,
  ) async {
    final isPaid = profile.isPaidPlanActive;
    final picked = await showDialog<AppMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.trackingMode),
        children: [
          ListTile(
            leading: const Text('🔄', style: TextStyle(fontSize: 20)),
            title: Text(l.cycleMode),
            subtitle: Text(l.cycleModeHint),
            trailing: profile.mode == AppMode.cycle
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(ctx, AppMode.cycle),
          ),
          ListTile(
            leading: const Text('🌱', style: TextStyle(fontSize: 20)),
            title: Row(
              children: [
                Text(l.planPregnancyMode),
                if (!isPaid) ...[
                  const SizedBox(width: 8),
                  _PlusBadge(),
                ],
              ],
            ),
            subtitle: Text(l.planPregnancyModeHint),
            trailing: profile.mode == AppMode.planPregnancy
                ? const Icon(Icons.check, color: AppColors.fertileGreen)
                : null,
            enabled: isPaid,
            onTap: isPaid ? () => Navigator.pop(ctx, AppMode.planPregnancy) : null,
          ),
          ListTile(
            leading: const Text('👶', style: TextStyle(fontSize: 20)),
            title: Row(
              children: [
                Text(l.pregnancyMode),
                if (!isPaid) ...[
                  const SizedBox(width: 8),
                  _PlusBadge(),
                ],
              ],
            ),
            subtitle: Text(l.pregnancyModeHint),
            trailing: profile.mode == AppMode.pregnancy
                ? const Icon(Icons.check, color: AppColors.pregnancyBlue)
                : null,
            enabled: isPaid,
            onTap: isPaid ? () => Navigator.pop(ctx, AppMode.pregnancy) : null,
          ),
        ],
      ),
    );
    if (picked == null || picked == profile.mode) return;

    if (picked == AppMode.pregnancy) {
      // Ask for LMP date
      if (!context.mounted) return;
      final lmp = await showDatePicker(
        context: context,
        initialDate:
            DateTime.now().subtract(const Duration(days: 30)),
        firstDate: DateTime.now().subtract(const Duration(days: 280)),
        lastDate: DateTime.now(),
        helpText: 'Select your last menstrual period (LMP)',
      );
      if (lmp == null) return;
      await ref
          .read(profileNotifierProvider.notifier)
          .switchMode(AppMode.pregnancy, pregnancyStart: lmp);
    } else {
      // cycle or planPregnancy — no extra date needed
      await ref
          .read(profileNotifierProvider.notifier)
          .switchMode(picked);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PickerDialog extends StatefulWidget {
  const _PickerDialog({
    required this.title,
    required this.values,
    required this.selected,
    required this.unit,
    required this.saveLabel,
    required this.cancelLabel,
  });

  final String title;
  final List<int> values;
  final int selected;
  final String unit;
  final String saveLabel;
  final String cancelLabel;

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_current ${widget.unit}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _current.toDouble(),
            min: widget.values.first.toDouble(),
            max: widget.values.last.toDouble(),
            divisions: widget.values.length - 1,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _current = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _current),
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

class _PlusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: const Text(
        'Plus',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

