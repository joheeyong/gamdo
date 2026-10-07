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

  const InstagramGradientAvatar({
    super.key,
    required this.size,
    this.borderWidth = 2,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.ringGradient,
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

  const InstagramGradientButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.child,
    this.height = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
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
