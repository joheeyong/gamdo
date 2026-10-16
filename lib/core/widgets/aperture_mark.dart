import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 감도 조리개 마크 (앱 아이콘 C와 같은 그림).
///
/// 원본은 `assets/icon/icon.svg`의 180 좌표계(원 반지름 56)다. 같은 비율로
/// 그려 실행 화면 이미지(assets/splash)와 겹쳐도 어긋나지 않는다.
/// [rotation]은 라디안, [opening]은 가운데 육각형(조리개 구멍)을 키우는 정도로
/// 0이면 아이콘 그대로, 1이면 반지름이 1.5배다. 날이 6개라 60°를 돌면 처음과 같다.
class ApertureMark extends StatelessWidget {
  final double size;
  final double rotation;
  final double opening;

  const ApertureMark({
    super.key,
    required this.size,
    this.rotation = 0,
    this.opening = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AperturePainter(rotation: rotation, opening: opening),
    );
  }
}

class _AperturePainter extends CustomPainter {
  final double rotation;
  final double opening;

  _AperturePainter({required this.rotation, required this.opening});

  // 아이콘 원본 좌표계(180)에서의 치수
  static const double _r = 56; // 렌즈 원
  static const double _hex = 22; // 가운데 육각형 꼭짓점 반지름
  static const double _blade = 6; // 날 선 굵기
  static const double _rim = 2; // 테두리 굵기

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / (_r * 2);
    final c = size.center(Offset.zero);
    final lens = Rect.fromCircle(center: c, radius: _r * s);
    const ink = AppColors.ink;

    canvas.drawCircle(c, _r * s, Paint()..color = AppColors.highlight);

    // 육각형 꼭짓점 k(각 -90°+60k)에서 +120° 방향으로 날 선을 원 밖까지 긋고 원으로 자른다
    final hex = _hex * (1 + 0.5 * opening.clamp(0.0, 1.0)) * s;
    final vertices = [
      for (var k = 0; k < 6; k++)
        c + Offset.fromDirection(_rad(-90 + 60.0 * k) + rotation, hex),
    ];
    canvas.save();
    canvas.clipPath(Path()..addOval(lens));
    final blade = Paint()
      ..color = ink
      ..strokeWidth = _blade * s
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      final dir = _rad(-90 + 60.0 * k + 120) + rotation;
      canvas.drawLine(
        vertices[k],
        vertices[k] + Offset.fromDirection(dir, _r * 2 * s),
        blade,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      c,
      _r * s,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rim * s,
    );
    canvas.drawPath(Path()..addPolygon(vertices, true), Paint()..color = ink);
  }

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(_AperturePainter old) =>
      old.rotation != rotation || old.opening != opening;
}
