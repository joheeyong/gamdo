import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Instagram 계열 공통 UI 요소 모음.
///
/// Material 기본 위젯(SnackBar / AlertDialog / Chip / ListTile)은
/// 그림자·물결·체크마크가 많아 인스타그램 톤과 어긋난다.
/// 이 파일의 요소들은 모두 그림자 없이 0.5px 헤어라인과
/// 흑/백 대비만으로 구성해 인스타그램 UI와 결을 맞춘다.

// ── 색 유틸 ──

extension InstaThemeX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// 보조 텍스트(회색 #8E8E8E) — 인스타그램 secondary label.
  Color get instaSecondary =>
      _isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  /// 0.5px 헤어라인 구분선 색.
  Color get instaDivider =>
      _isDark ? AppColors.dividerDark : AppColors.dividerLight;

  /// 기본 텍스트 색.
  Color get instaPrimaryText =>
      _isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  /// 카드/시트 표면 색.
  Color get instaSurface =>
      _isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
}

// ── 그래디언트 텍스트/아이콘 ──

/// 인스타그램 그래디언트로 마스킹한 텍스트.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppColors.instagramGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: (style ?? const TextStyle()).copyWith(
        color: Colors.white,
      )),
    );
  }
}

/// 인스타그램 그래디언트로 마스킹한 아이콘.
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;

  const GradientIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.gradient = AppColors.instagramGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

// ── 헤어라인 ──

/// 인스타그램식 0.5px 구분선.
class InstaHairline extends StatelessWidget {
  final double indent;
  final double endIndent;

  const InstaHairline({super.key, this.indent = 0, this.endIndent = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(height: 0.5, color: context.instaDivider),
    );
  }
}

// ── 섹션 라벨 ──

/// 설정/프로필 화면의 그룹 헤더.
class InstaSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const InstaSectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.instaSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── 필터 알약(Pill) ──

/// 인스타그램 탐색 탭의 필터 알약.
///
/// 선택 시 흑/백 반전으로 채우고, 비선택은 헤어라인 테두리만 남긴다.
/// Material [FilterChip]의 체크마크·물결 효과를 쓰지 않는다.
class InstaPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  const InstaPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.instaSurface : context.instaPrimaryText;
    final bg = selected ? context.instaPrimaryText : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 14,
          vertical: dense ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : context.instaDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: dense ? 12 : 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ── 설정 행 ──

/// 인스타그램 설정 화면의 한 줄(아이콘 + 제목 + 트레일링).
class InstaSettingRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const InstaSettingRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: titleColor ?? context.instaPrimaryText),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      fontSize: 15,
                      color: titleColor ?? context.instaPrimaryText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.instaSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── 토스트 ──

/// 인스타그램식 토스트(어두운 알약, 하단 부유).
///
/// Material SnackBar의 기본 모양 대신 사용한다.
void showInstaToast(
  BuildContext context,
  String message, {
  IconData? icon,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? AppColors.error : const Color(0xFF262626),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
}

// ── 확인 다이얼로그 ──

/// 인스타그램식 확인 다이얼로그.
///
/// 가운데 정렬 제목/본문 + 헤어라인으로 나뉜 버튼 두 개.
/// 파괴적 동작은 빨간 볼드로 표시한다.
Future<bool> showInstaConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: ctx.instaSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ctx.instaPrimaryText,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: ctx.instaSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const InstaHairline(),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  Container(width: 0.5, color: ctx.instaDivider),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      color: isDestructive ? AppColors.error : AppColors.actionBlue,
                      bold: true,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool bold;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color ?? context.instaPrimaryText,
          ),
        ),
      ),
    );
  }
}

// ── 액션 시트 ──

/// [showInstaSheet]의 한 항목.
class InstaSheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const InstaSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// 인스타그램식 하단 액션 시트(그랩 핸들 + 아이콘 행).
Future<void> showInstaSheet(
  BuildContext context, {
  String? title,
  required List<InstaSheetAction> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.instaSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.instaDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ctx.instaSecondary,
                  ),
                ),
              ),
              const InstaHairline(),
            ] else
              const SizedBox(height: 4),
            for (final action in actions)
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  action.onTap();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        action.icon,
                        size: 22,
                        color: action.isDestructive
                            ? AppColors.error
                            : ctx.instaPrimaryText,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: action.isDestructive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: action.isDestructive
                              ? AppColors.error
                              : ctx.instaPrimaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

// ── 통계 열(프로필 헤더) ──

/// 인스타그램 프로필의 게시물/팔로워 카운터 한 칸.
class InstaStat extends StatelessWidget {
  final String value;
  final String label;

  const InstaStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.instaPrimaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.instaSecondary),
        ),
      ],
    );
  }
}

// ── 보조 버튼 ──

/// 인스타그램 프로필의 '프로필 편집' 류 회색 버튼.
class InstaSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foreground;

  const InstaSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = foreground ?? context.instaPrimaryText;

    return SizedBox(
      height: 34,
      child: Material(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppTypography.button.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
