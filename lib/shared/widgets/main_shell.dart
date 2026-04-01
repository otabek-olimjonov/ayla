import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../l10n/l10n.dart';

/// Persistent bottom navigation shell wrapping the main tab screens.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabPaths = [
    AppRoutes.home,
    AppRoutes.articles,
    AppRoutes.profile,
  ];
  static const _tabIcons = [
    Icons.home_outlined,
    Icons.article_outlined,
    Icons.person_outline,
  ];
  static const _tabActiveIcons = [
    Icons.home,
    Icons.article,
    Icons.person,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabPaths.length; i++) {
      if (location.startsWith(_tabPaths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.home, l10n.articles, l10n.profile];
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabPaths[i]),
        items: List.generate(
          _tabPaths.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[i]),
            activeIcon: Icon(_tabActiveIcons[i]),
            label: labels[i],
          ),
        ),
      ),
    );
  }
}
