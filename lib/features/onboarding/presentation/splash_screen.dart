import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ShaderMask(
            shaderCallback: (bounds) => AppColors.instagramGradient.createShader(bounds),
            child: const Text(
              '감도',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                fontFamily: 'Pretendard',
                letterSpacing: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
