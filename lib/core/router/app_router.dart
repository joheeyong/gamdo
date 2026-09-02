import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/instagram_login_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/photo_upload/presentation/photo_upload_screen.dart';
import '../../features/analysis/presentation/analysis_result_screen.dart';
import '../../features/analysis/presentation/batch_transform_screen.dart';
import '../../features/analysis/presentation/transform_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/insta_ui.dart';
import '../widgets/instagram_widgets.dart';

part 'app_router.g.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String instagramLogin = '/instagram-login';
  static const String home = '/home';
  static const String photoUpload = '/photo-upload';
  static const String analysisResult = '/analysis-result';
  static const String transform = '/transform';
  static const String batchTransform = '/batch-transform';
  static const String history = '/history';
  static const String settings = '/settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
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
      GoRoute(
        path: AppRoutes.transform,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TransformScreen(
            imagePath: extra?['imagePath'] as String? ?? '',
            analysisJson: extra?['analysisJson'] as String? ?? '{}',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.batchTransform,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final files = extra?['imageFiles'] as List<File>? ?? [];
          return BatchTransformScreen(imageFiles: files);
        },
      ),
    ],
  );
}

/// Instagram-style bottom navigation shell
class _InstaNavShell extends ConsumerStatefulWidget {
  final Widget child;
  const _InstaNavShell({required this.child});

  @override
  ConsumerState<_InstaNavShell> createState() => _InstaNavShellState();
}

class _InstaNavShellState extends ConsumerState<_InstaNavShell> {
  DateTime? _lastBackPress;

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
    final isHome = idx == 0;
    final isConnected = ref.watch(instagramAuthProvider).isConnected;

    return PopScope(
      canPop: !isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // 홈 화면: 2초 내 더블 클릭으로 앱 종료
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        showInstaToast(context, '뒤로 한번 더 누르면 앱이 종료됩니다');
      },
      child: Scaffold(
        body: widget.child,
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
              // 인스타그램 '만들기' 탭: 모서리 둥근 사각 플러스
              const NavigationDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box),
                label: '만들기',
              ),
              // 인스타그램 프로필 탭: 선택 시 스토리 링이 감싼 아바타
              NavigationDestination(
                icon: _ProfileTabIcon(selected: false, isConnected: isConnected),
                selectedIcon:
                    _ProfileTabIcon(selected: true, isConnected: isConnected),
                label: '프로필',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 탭의 프로필 아이콘.
///
/// Instagram 연결 시 스토리 링을 두른 아바타로, 미연결 시 사람 아이콘으로 표시한다.
class _ProfileTabIcon extends StatelessWidget {
  final bool selected;
  final bool isConnected;

  const _ProfileTabIcon({required this.selected, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Icon(selected ? Icons.person : Icons.person_outline);
    }

    final avatar = CircleAvatar(
      radius: 11,
      backgroundColor: context.instaDivider,
      child: Icon(Icons.person, size: 14, color: context.instaSecondary),
    );

    if (!selected) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.instaSecondary, width: 1),
        ),
        child: Padding(padding: const EdgeInsets.all(1.5), child: avatar),
      );
    }

    return InstagramGradientAvatar(
      size: 28,
      borderWidth: 2,
      child: Padding(padding: const EdgeInsets.all(1), child: avatar),
    );
  }
}
