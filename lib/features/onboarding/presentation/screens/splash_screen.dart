import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _navigate();
    });
  }

  Future<void> _navigate() async {
    try {
      // Instagram 토큰 복원 + Firebase 스타일 프로필 로드 (실패해도 네비게이션 진행)
      try {
        await ref.read(instagramAuthProvider.notifier).init();
      } catch (_) {
        // Instagram 초기화 실패는 무시 — 앱 사용에 필수가 아님
      }

      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_complete') ?? false;
      if (!mounted) return;
      context.go(done ? AppRoutes.home : AppRoutes.onboarding);
    } catch (_) {
      if (mounted) context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 스플래시는 앱 내 테마 설정이 아니라 '시스템' 밝기를 따른다.
    // 네이티브 실행 화면(Android values-night / iOS LaunchBackground 색 에셋)은
    // 앱 설정을 읽을 수 없고 시스템 다크 모드만 따르므로, 여기서도 시스템 기준으로
    // 같은 종이/먹색을 써야 실행 화면 → 스플래시 사이에 색이 튀지 않는다.
    // (스플래시 → 첫 화면 전환부터는 앱 설정을 따른다.)
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: background,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              '\uAC10\uB3C4',
              style: AppTypography.wordmark.copyWith(
                fontSize: 44,
                letterSpacing: 2,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
