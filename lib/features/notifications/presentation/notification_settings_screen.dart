import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../data/notification_settings_notifier.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier =
        ref.read(notificationSettingsNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Period reminder
        SwitchListTile(
          title: const Text('Period reminder'),
          subtitle: const Text('Get reminded before your period starts'),
          value: settings.periodReminder,
          onChanged: (v) =>
              notifier.save(settings.copyWith(periodReminder: v)),
        ),
        if (settings.periodReminder) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                const Text('Days before: '),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<int>(
                  value: settings.periodReminderDays,
                  items: [1, 2, 3, 5, 7]
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d days'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      notifier.save(
                          settings.copyWith(periodReminderDays: v));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        const Divider(),

        // Ovulation reminder
        SwitchListTile(
          title: const Text('Ovulation reminder'),
          subtitle: const Text('Get reminded on your predicted ovulation day'),
          value: settings.ovulationReminder,
          onChanged: (v) =>
              notifier.save(settings.copyWith(ovulationReminder: v)),
        ),
        const Divider(),

        // Pregnancy reminder
        SwitchListTile(
          title: const Text('Pregnancy weekly reminder'),
          subtitle: const Text('Weekly milestone updates during pregnancy'),
          value: settings.pregnancyReminder,
          onChanged: (v) =>
              notifier.save(settings.copyWith(pregnancyReminder: v)),
        ),
        const Divider(),

        // Reminder time
        ListTile(
          title: const Text('Reminder time'),
          trailing: Text(
            '${settings.reminderHour.toString().padLeft(2, '0')}:'
            '${settings.reminderMinute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
              ),
            );
            if (picked != null) {
              notifier.save(settings.copyWith(
                reminderHour: picked.hour,
                reminderMinute: picked.minute,
              ));
            }
          },
        ),
      ],
    );
  }
}
