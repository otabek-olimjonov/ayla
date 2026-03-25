import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../profile/domain/profile_notifier.dart';
import '../domain/calendar_provider.dart';
import '../domain/cycle_log.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final logsAsync = ref.watch(calendarLogsProvider);
    final predictionAsync = ref.watch(calendarPredictionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          final isPaid = profile.isPaidPlanActive;
          final logs = logsAsync.valueOrNull ?? {};
          final prediction = predictionAsync.valueOrNull;

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                // Provide events so markers are rendered
                eventLoader: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  return logs[key] ?? [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    return _buildDayMarkers(
                      day: day,
                      logTypes: events.cast<CycleLogType>(),
                      prediction: prediction,
                      isPaid: isPaid,
                    );
                  },
                  // Blur future days for free users
                  defaultBuilder: isPaid
                      ? null
                      : (context, day, focusedDay) {
                          if (day.isAfter(DateTime.now())) {
                            return _BlurredDay(day: day);
                          }
                          return null; // use default rendering
                        },
                  outsideBuilder: null,
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _showDaySheet(
                    context,
                    selected,
                    logs[DateTime(selected.year, selected.month, selected.day)] ?? [],
                  );
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  ref
                      .read(calendarFocusedMonthProvider.notifier)
                      .set(focusedDay);
                },
              ),
              // Paywall banner for free users
              if (!isPaid)
                _PaywallBanner(
                  onUpgrade: () => Navigator.of(context)
                      .pushNamed(AppRoutes.paywall),
                ),
              // Legend
              const _CalendarLegend(),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildDayMarkers({
    required DateTime day,
    required List<CycleLogType> logTypes,
    required CalendarPrediction? prediction,
    required bool isPaid,
  }) {
    final dots = <Color>[];

    // Actual logged period
    if (logTypes.any((t) =>
        t == CycleLogType.periodStart || t == CycleLogType.periodEnd)) {
      dots.add(AppColors.periodRed);
    }
    // Actual mood logged
    if (logTypes.any((t) => t.value.startsWith('mood_'))) {
      dots.add(AppColors.secondary);
    }
    // Actual symptoms logged
    if (logTypes.any((t) =>
        t == CycleLogType.cramp ||
        t == CycleLogType.headache ||
        t == CycleLogType.bloating)) {
      dots.add(AppColors.textSecondary);
    }

    // Predictions (paid only)
    if (isPaid && prediction != null && day.isAfter(DateTime.now())) {
      if (prediction.isOvulation(day)) {
        dots.add(AppColors.accent);
      } else if (prediction.isFertile(day)) {
        dots.add(AppColors.fertileGreen);
      } else if (prediction.isPeriod(day)) {
        dots.add(AppColors.periodRed.withValues(alpha: 0.5));
      }
    }

    if (dots.isEmpty) return null;

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: dots.take(3).map((c) => _dot(c)).toList(),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  void _showDaySheet(
    BuildContext context,
    DateTime day,
    List<CycleLogType> types,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _DayLogsSheet(day: day, logTypes: types),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blurred day cell for free users
// ---------------------------------------------------------------------------

class _BlurredDay extends StatelessWidget {
  const _BlurredDay({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Center(
          child: Text(
            '${day.day}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend row
// ---------------------------------------------------------------------------

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _LegendItem(color: AppColors.periodRed, label: 'Period'),
          _LegendItem(color: AppColors.fertileGreen, label: 'Fertile'),
          _LegendItem(color: AppColors.accent, label: 'Ovulation'),
          _LegendItem(color: AppColors.secondary, label: 'Mood'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paywall banner
// ---------------------------------------------------------------------------

class _PaywallBanner extends StatelessWidget {
  const _PaywallBanner({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Upgrade to see future predictions',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day logs bottom sheet
// ---------------------------------------------------------------------------

class _DayLogsSheet extends StatelessWidget {
  const _DayLogsSheet({required this.day, required this.logTypes});

  final DateTime day;
  final List<CycleLogType> logTypes;

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${monthNames[day.month]} ${day.day}, ${day.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (logTypes.isEmpty)
            Text(
              'Nothing logged on this day.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: logTypes.map((t) {
                return Chip(
                  label: Text(_label(t)),
                  backgroundColor: _chipColor(t).withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _chipColor(t)),
                  side: BorderSide(color: _chipColor(t).withValues(alpha: 0.4)),
                );
              }).toList(),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  String _label(CycleLogType t) {
    return t.value.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  Color _chipColor(CycleLogType t) {
    if (t == CycleLogType.periodStart || t == CycleLogType.periodEnd) {
      return AppColors.periodRed;
    }
    if (t.value.startsWith('mood_')) return AppColors.secondary;
    return AppColors.primary;
  }
}
