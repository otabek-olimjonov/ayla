import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/profile_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _ProfileSection(
              title: 'Cycle settings',
              children: [
                ListTile(
                  title: const Text('Cycle length'),
                  trailing: Text('${profile.cycleLength} days'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Period length'),
                  trailing: Text('${profile.periodLength} days'),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileSection(
              title: 'Plan',
              children: [
                ListTile(
                  title: const Text('Current plan'),
                  trailing: Text(
                    profile.isPaidPlanActive ? 'Premium' : 'Free',
                  ),
                  onTap: () => context.push(AppRoutes.paywall),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileSection(
              title: 'Partner',
              children: [
                ListTile(
                  title: const Text('Partner sharing'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.partner),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileSection(
              title: 'Notifications',
              children: [
                ListTile(
                  title: const Text('Reminder settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(AppRoutes.notificationSettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileSection(
              title: 'Language',
              children: [
                ListTile(
                  title: const Text('App language'),
                  trailing: Text(_languageLabel(profile.language)),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileSection(
              title: 'Reports',
              children: [
                ListTile(
                  title: const Text('Export health report (PDF)'),
                  trailing: const Icon(Icons.picture_as_pdf_outlined),
                  onTap: () => context.push(AppRoutes.report),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(String lang) {
    switch (lang) {
      case 'uz':
        return 'Uzbek';
      case 'uz_CY':
        return 'Ўзбекча';
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return lang;
    }
  }
}

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
          child: Text(title, style: Theme.of(context).textTheme.bodySmall),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
