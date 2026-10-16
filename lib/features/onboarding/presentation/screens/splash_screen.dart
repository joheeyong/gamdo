import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/aperture_mark.dart';

/// 실행 화면 조리개 지름. 네이티브 실행 화면 이미지(assets/splash, 112dp/pt)와 같아야
/// 실행 화면 → 스플래시가 끊김 없이 이어진다.
const double _markSize = 112;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // 0~0.55: 조리개가 60° 돌며 가운데가 열렸다 닫힘 (끝나면 처음 모양과 같다)
  // 0.4~1.0: 아래에서 '감도'가 떠오름
  late final AnimationController _controller;
  late final Animation<double> _turn;
  late final Animation<double> _wordmark;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _turn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeInOutCubic),
    );
    _wordmark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 움직임 줄이기 설정이면 돌리지 않고 글자만 바로 보인다
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });

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
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: background,
          ),
      child: Scaffold(
        backgroundColor: background,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _turn.value;
            final reduce = MediaQuery.of(context).disableAnimations;
            // 화면 전체를 차지해야 가운데 정렬된다 (Stack은 자식 크기로 줄어든다)
            return SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 조리개는 정확히 화면 가운데 — 네이티브 실행 화면과 같은 자리
                  ApertureMark(
                    size: _markSize,
                    rotation: reduce ? 0 : t * math.pi / 3,
                    opening: reduce ? 0 : math.sin(t * math.pi),
                  ),
                  Transform.translate(
                    offset: Offset(
                      0,
                      _markSize / 2 + 44 + 12 * (1 - _wordmark.value),
                    ),
                    child: Opacity(
                      opacity: _wordmark.value,
                      child: Text(
                        '\uAC10\uB3C4',
                        style: AppTypography.wordmark.copyWith(
                          fontSize: 36,
                          letterSpacing: 2,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
