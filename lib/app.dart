import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/domain/profile_notifier.dart';
import 'l10n/l10n.dart';

class AylaApp extends ConsumerWidget {
  const AylaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Derive locale from user's saved language preference; null = follow system
    final locale = ref.watch(profileNotifierProvider).maybeWhen(
      data: (p) => _localeFromLang(p.language),
      orElse: () => null,
    );

    return MaterialApp.router(
      title: 'Ayla',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Locale _localeFromLang(String lang) {
    if (lang == 'uz_CY') return const Locale('uz', 'CY');
    return Locale(lang);
  }
}
