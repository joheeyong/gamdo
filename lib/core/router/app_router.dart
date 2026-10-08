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
import '../services/analytics_service.dart';
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
  final router = GoRouter(
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
            transformedImagePath: extra?['transformedImagePath'] as String?,
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
            recordId: extra?['recordId'] as int?,
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
  _trackScreenViews(router);
  return router;
}

/// 경로가 바뀔 때마다 화면 조회를 기록한다.
///
/// 하단 탭(ShellRoute) 이동도 잡도록 Navigator 관찰자 대신 라우터 상태를 본다.
/// 같은 경로가 연달아 알려지면(상태 갱신·리빌드) 한 번만 남긴다.
void _trackScreenViews(GoRouter router) {
  String? lastPath;
  void report() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path.isEmpty || path == lastPath) return;
    lastPath = path;
    AnalyticsService.instance.screenView(path);
  }

  router.routerDelegate.addListener(report);
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
        // 벤토 탭 바: 흰 알약 안에 탭 세 개 + 오른쪽 라임 분석 버튼
        bottomNavigationBar: _BentoTabBar(
          selected: idx,
          isConnected: isConnected,
          onSelect: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.home);
              case 1: context.go(AppRoutes.history);
              case 3: context.go(AppRoutes.settings);
            }
          },
          onCreate: () => context.push(AppRoutes.photoUpload),
        ),
      ),
    );
  }
}

/// 벤토 하단 탭 바.
///
/// 흰(다크: 짙은 회색) 알약 안에 홈·기록·프로필 세 탭을 두고, 선택된 탭은 먹색
/// 원으로 채운다. 사진 분석(만들기)은 탭이 아니라 오른쪽의 라임 원 버튼이다.
/// [selected]는 기존 탭 번호를 그대로 쓴다 (0 홈, 1 기록, 3 프로필).
class _BentoTabBar extends StatelessWidget {
  final int selected;
  final bool isConnected;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  const _BentoTabBar({
    required this.selected,
    required this.isConnected,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pill = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: pill,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    _tab(context, 0, Icons.home_outlined, Icons.home_rounded, '홈'),
                    _tab(context, 1, Icons.grid_view_outlined, Icons.grid_view_rounded, '기록'),
                    _tab(context, 3, null, null, '프로필'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: '새 사진 분석',
              child: Material(
                color: AppColors.highlight,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onCreate,
                  child: const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.add_rounded, size: 30, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    int index,
    IconData? icon,
    IconData? selectedIcon,
    String label,
  ) {
    final isSelected = selected == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final selectedFg = isDark ? AppColors.ink : Colors.white;
    final fg = isSelected ? selectedFg : context.instaPrimaryText;

    final Widget glyph = icon == null
        ? _ProfileTabIcon(selected: isSelected, isConnected: isConnected, color: fg)
        : Icon(isSelected ? selectedIcon : icon, size: 24, color: fg);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? selectedFill : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: glyph,
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
  final Color? color;

  const _ProfileTabIcon({
    required this.selected,
    required this.isConnected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Icon(
        selected ? Icons.person_rounded : Icons.person_outline_rounded,
        size: 24,
        color: color,
      );
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
