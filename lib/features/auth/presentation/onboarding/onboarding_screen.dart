import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/auth_providers.dart';
import '../../domain/user_profile.dart';
import '../../../notifications/data/notification_service.dart';
import '../../../profile/domain/profile_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  AppMode _selectedMode = AppMode.cycle;
  int _cycleLength = 28;
  int _periodLength = 5;

  Future<void> _next() async {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }
    // Final page — save profile then navigate home
    try {
      final userId = ref.read(currentUserIdProvider);
      final now = DateTime.now();
      final profile = UserProfile(
        id: userId,
        createdAt: now,
        updatedAt: now,
        cycleLength: _cycleLength,
        periodLength: _periodLength,
        language: 'uz',
        mode: _selectedMode,
      );
      await ref.read(profileNotifierProvider.notifier).saveProfile(profile);
      await NotificationService().requestPermissions();
    } catch (_) {
      // Non-fatal — user can configure later from profile screen
    }
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_page + 1) / 3),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _ModeSelectionPage(
                    selected: _selectedMode,
                    onChanged: (m) => setState(() => _selectedMode = m),
                  ),
                  _CycleSetupPage(
                    cycleLength: _cycleLength,
                    periodLength: _periodLength,
                    onCycleChanged: (v) => setState(() => _cycleLength = v),
                    onPeriodChanged: (v) => setState(() => _periodLength = v),
                  ),
                  const _NotificationPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_page < 2 ? 'Continue' : 'Start using Ayla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelectionPage extends StatelessWidget {
  const _ModeSelectionPage({
    required this.selected,
    required this.onChanged,
  });
  final AppMode selected;
  final ValueChanged<AppMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('How do you want to use Ayla?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          _ModeCard(
            title: 'Track my cycle',
            description: 'Period tracking, predictions and symptom logging.',
            selected: selected == AppMode.cycle,
            onTap: () => onChanged(AppMode.cycle),
          ),
          const SizedBox(height: AppSpacing.md),
          _ModeCard(
            title: 'Pregnancy mode',
            description: 'Weekly milestones and pregnancy symptom tracking.',
            selected: selected == AppMode.pregnancy,
            onTap: () => onChanged(AppMode.pregnancy),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _CycleSetupPage extends StatelessWidget {
  const _CycleSetupPage({
    required this.cycleLength,
    required this.periodLength,
    required this.onCycleChanged,
    required this.onPeriodChanged,
  });
  final int cycleLength;
  final int periodLength;
  final ValueChanged<int> onCycleChanged;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Set up your cycle', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Text('Cycle length: $cycleLength days', style: theme.textTheme.titleMedium),
          Slider(
            value: cycleLength.toDouble(),
            min: 21,
            max: 45,
            divisions: 24,
            label: '$cycleLength',
            onChanged: (v) => onCycleChanged(v.round()),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Period length: $periodLength days', style: theme.textTheme.titleMedium),
          Slider(
            value: periodLength.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: '$periodLength',
            onChanged: (v) => onPeriodChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _NotificationPage extends StatelessWidget {
  const _NotificationPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_outlined, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text('Stay informed', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enable notifications to receive period reminders and cycle updates.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
