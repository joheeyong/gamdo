import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../domain/entities/edit_style.dart';

/// 보정 스타일 선택 시트를 띄운다.
///
/// 고른 값('auto' 또는 trendCategory id)을 돌려준다. 닫으면 null.
/// 저장은 호출한 쪽이 한다 ([EditStyleSetting.select]).
Future<String?> showEditStylePicker(
  BuildContext context, {
  required String current,
  String title = '보정 스타일',
  String? message,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.instaSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, controller) => EditStylePickerList(
        current: current,
        title: title,
        message: message,
        scrollController: controller,
        onSelected: (id) => Navigator.pop(ctx, id),
      ),
    ),
  );
}

/// 시트 본문 — 그랩 핸들, 제목, '자동' + 9가지 스타일 행.
class EditStylePickerList extends StatelessWidget {
  final String current;
  final String title;
  final String? message;
  final ScrollController? scrollController;
  final ValueChanged<String> onSelected;

  const EditStylePickerList({
    super.key,
    required this.current,
    required this.onSelected,
    this.title = '보정 스타일',
    this.message,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final selected = normalizeEditStyle(current);
    return SafeArea(
      top: false,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.instaDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.instaPrimaryText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              message ?? '사진에 입힐 룩을 골라 주세요. 설정에서 언제든 바꿀 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.instaSecondary,
              ),
            ),
          ),
          const InstaHairline(),
          _EditStyleRow(
            swatch: const EditStyleSwatch.auto(),
            name: kEditStyleAutoName,
            description: kEditStyleAutoDescription,
            selected: selected == kEditStyleAuto,
            onTap: () => onSelected(kEditStyleAuto),
          ),
          for (final style in kEditStyles) ...[
            const InstaHairline(indent: 88),
            _EditStyleRow(
              swatch: EditStyleSwatch(style: style),
              name: style.name,
              description: style.description,
              selected: selected == style.id,
              onTap: () => onSelected(style.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditStyleRow extends StatelessWidget {
  final Widget swatch;
  final String name;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _EditStyleRow({
    required this.swatch,
    required this.name,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            swatch,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: context.instaPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: context.instaSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (selected)
              const GradientIcon(Icons.check_circle, size: 22)
            else
              Icon(Icons.circle_outlined, size: 22, color: context.instaDivider),
          ],
        ),
      ),
    );
  }
}

/// 룩을 떠올리게 하는 작은 색 띠 (네트워크 이미지 없이 그래디언트로).
class EditStyleSwatch extends StatelessWidget {
  final EditStyle? style;
  final double width;
  final double height;

  const EditStyleSwatch({
    super.key,
    required EditStyle this.style,
    this.width = 56,
    this.height = 40,
  });

  /// '자동' — 앱 그래디언트.
  const EditStyleSwatch.auto({super.key, this.width = 56, this.height = 40})
      : style = null;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final Gradient gradient = s == null
        ? AppColors.brandGradient
        : LinearGradient(
            colors: [for (final c in s.swatch) Color(c)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.instaDivider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: s == null
          ? const Icon(Icons.auto_awesome, size: 18, color: Colors.white)
          : s.grain
              ? CustomPaint(painter: _GrainPainter(seed: s.id.hashCode))
              : null,
    );
  }
}

/// 필름 그레인 느낌의 점 무늬 (고정 시드라 매번 같게 그린다).
class _GrainPainter extends CustomPainter {
  final int seed;
  const _GrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.22);
    final count = (size.width * size.height / 14).round();
    for (var i = 0; i < count; i++) {
      final o = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawCircle(o, 0.6, rnd.nextBool() ? light : dark);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.seed != seed;
}
