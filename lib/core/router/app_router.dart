import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/instagram_login_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/photo_upload/presentation/photo_upload_screen.dart';
import '../../features/analysis/presentation/analysis_result_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../theme/app_colors.dart';

part 'app_router.g.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String instagramLogin = '/instagram-login';
  static const String home = '/home';
  static const String photoUpload = '/photo-upload';
  static const String analysisResult = '/analysis-result';
  static const String history = '/history';
  static const String settings = '/settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.instagramLogin,
        builder: (context, state) => const InstagramLoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _InstaNavShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.photoUpload,
        builder: (context, state) => const PhotoUploadScreen(),
      ),
      GoRoute(
        path: AppRoutes.analysisResult,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnalysisResultScreen(
            analysisId: extra?['analysisId'] as int?,
            analysisJson: extra?['analysisJson'] as String?,
            imagePath: extra?['imagePath'] as String?,
          );
        },
      ),
    ],
  );
}

/// Instagram-style bottom navigation shell
class _InstaNavShell extends StatelessWidget {
  final Widget child;
  const _InstaNavShell({required this.child});

  static int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith(AppRoutes.history)) return 1;
    if (loc.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          height: 56,
          selectedIndex: idx > 2 ? 3 : idx,
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.home);
              case 1: context.go(AppRoutes.history);
              case 2: context.push(AppRoutes.photoUpload); // 중앙 버튼 → 업로드
              case 3: context.go(AppRoutes.settings);
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_on_outlined),
              selectedIcon: Icon(Icons.grid_on),
              label: '기록',
            ),
            NavigationDestination(
              icon: ShaderMask(
                shaderCallback: (bounds) => AppColors.instagramGradient.createShader(bounds),
                child: const Icon(Icons.add_circle_outline, size: 32, color: Colors.white),
              ),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => AppColors.instagramGradient.createShader(bounds),
                child: const Icon(Icons.add_circle, size: 32, color: Colors.white),
              ),
              label: '',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
