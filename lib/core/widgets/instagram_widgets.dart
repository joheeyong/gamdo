import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 앰버 링 아바타.
///
/// [size]로 전체 크기, [borderWidth]로 링 두께를 조절하고,
/// [child]에 내부 콘텐츠(아이콘, CircleAvatar 등)를 넣는다.
class InstagramGradientAvatar extends StatelessWidget {
  final double size;
  final double borderWidth;
  final Widget child;

  /// 링 색. 기본은 앱의 라임 링, 인스타그램 연결 화면은 인스타그램 링.
  final Gradient gradient;

  const InstagramGradientAvatar({
    super.key,
    required this.size,
    this.borderWidth = 2,
    required this.child,
    this.gradient = AppColors.ringGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: child,
      ),
    );
  }
}

/// 앰버 두 톤 배경의 주 버튼 (흰 글자).
///
/// [isLoading]이 true이면 로딩 스피너를 표시하고 onPressed를 무시한다.
class InstagramGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;
  final double height;
  final double borderRadius;

  /// 버튼 바탕. 기본은 앱 강조색, 인스타그램 연결 버튼은 [AppColors.instagramGradient].
  final Gradient gradient;

  /// true면 가로를 가득 채우고, false면 내용 폭만큼만 차지하는 작은 알약이 된다.
  final bool expand;

  const InstagramGradientButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.child,
    this.height = 48,
    this.borderRadius = 999,
    this.gradient = AppColors.brandGradient,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            // 높이가 고정이라 테마의 위아래 여백을 쓰면 글자가 잘린다
            padding: EdgeInsets.symmetric(horizontal: expand ? 16 : 18),
            minimumSize: Size(0, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
