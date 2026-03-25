import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../domain/cycle_log.dart';
import '../domain/today_logs_notifier.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text('Today', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader('Period'),
          const _LogChipRow(
            types: [CycleLogType.periodStart, CycleLogType.periodEnd, CycleLogType.spotting],
          ),
          const SizedBox(height: AppSpacing.md),
          // Paid features below — TODO: gate behind plan check
          const _SectionHeader('Symptoms'),
          const _LogChipRow(
            types: [CycleLogType.cramp, CycleLogType.headache, CycleLogType.bloating],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader('Mood'),
          const _LogChipRow(
            types: [
              CycleLogType.moodHappy,
              CycleLogType.moodSad,
              CycleLogType.moodAnxious,
              CycleLogType.moodCalm,
              CycleLogType.moodIrritable,
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _LogChipRow extends ConsumerWidget {
  const _LogChipRow({required this.types});
  final List<CycleLogType> types;

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
      error: (e, _) => Text(
        'Could not load logs',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (logs) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: types.map((t) {
          final isLogged = notifier.isLogged(t);
          return FilterChip(
            label: Text(_labelFor(t)),
            selected: isLogged,
            onSelected: (_) => notifier.toggle(t),
          );
        }).toList(),
      ),
    );
  }

  String _labelFor(CycleLogType t) {
    return t.value.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
