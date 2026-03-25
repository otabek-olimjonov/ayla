import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Persistent bottom navigation shell wrapping the main tab screens.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _Tab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home, path: AppRoutes.home),
    _Tab(label: 'Calendar', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, path: AppRoutes.calendar),
    _Tab(label: 'Log', icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note, path: AppRoutes.log),
    _Tab(label: 'Articles', icon: Icons.article_outlined, activeIcon: Icons.article, path: AppRoutes.articles),
    _Tab(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, path: AppRoutes.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                activeIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}
