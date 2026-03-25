import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/onboarding/onboarding_screen.dart';
import '../../features/cycle/presentation/home_screen.dart';
import '../../features/cycle/presentation/calendar_screen.dart';
import '../../features/cycle/presentation/log_screen.dart';
import '../../features/articles/presentation/articles_screen.dart';
import '../../features/articles/presentation/article_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/ai_assistant/presentation/ai_chat_screen.dart';
import '../../features/community/presentation/community_feed_screen.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/paywall/presentation/paywall_screen.dart';
import '../../features/reports/presentation/report_preview_screen.dart';
import '../../features/partner/presentation/partner_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../supabase/supabase_client_provider.dart';

part 'app_router.g.dart';

/// Route names used for [GoRouter.go] calls. Always use these constants.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const calendar = '/home/calendar';
  static const log = '/home/log';
  static const articles = '/home/articles';
  static const articleDetail = '/home/articles/:id';
  static const profile = '/home/profile';
  static const partner = '/home/profile/partner';
  static const notificationSettings = '/home/profile/notifications';
  static const aiChat = '/ai-chat';
  static const community = '/community';
  static const postDetail = '/community/:id';
  static const paywall = '/paywall';
  static const report = '/report';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final supabase = ref.watch(supabaseClientProvider);

  // Notifies GoRouter whenever auth state changes (login / logout).
  final notifier = _AuthChangeNotifier(supabase);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = supabase.auth.currentSession != null;
      final loc = state.matchedLocation;

      // Always redirect away from the splash screen immediately.
      if (loc == AppRoutes.splash) {
        return isAuth ? AppRoutes.home : AppRoutes.login;
      }

      final isOnLoginFlow = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.onboarding;

      if (!isAuth && !isOnLoginFlow) return AppRoutes.login;
      if (isAuth && isOnLoginFlow) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const _SplashRedirect()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.paywall, builder: (_, __) => const PaywallScreen()),
      GoRoute(path: AppRoutes.aiChat, builder: (_, __) => const AiChatScreen()),
      GoRoute(path: AppRoutes.report, builder: (_, __) => const ReportPreviewScreen()),
      GoRoute(
        path: AppRoutes.community,
        builder: (_, __) => const CommunityFeedScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => PostDetailScreen(postId: state.pathParameters['id']!),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.calendar, builder: (_, __) => const CalendarScreen()),
          GoRoute(path: AppRoutes.log, builder: (_, __) => const LogScreen()),
          GoRoute(
            path: AppRoutes.articles,
            builder: (_, __) => const ArticlesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ArticleDetailScreen(articleId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: AppRoutes.partner,
            builder: (_, __) => const PartnerScreen(),
          ),
          GoRoute(
            path: AppRoutes.notificationSettings,
            builder: (_, __) => const NotificationSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

class _SplashRedirect extends StatelessWidget {
  const _SplashRedirect();

  @override
  Widget build(BuildContext context) {
    // The GoRouter redirect always navigates away from this route immediately.
    // This scaffold is just a blank frame shown for a single frame at most.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Listens to Supabase auth state changes and notifies GoRouter to re-evaluate
/// its redirect logic (e.g. after login or logout).
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(SupabaseClient supabase) {
    _subscription = supabase.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
