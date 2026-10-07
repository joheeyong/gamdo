import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Before/After 사진을 전체 화면으로 크게 본다.
///
/// - 두 손가락으로 확대/이동, 두 번 탭하면 그 지점 확대 ↔ 원래 크기
/// - Before/After를 바꿔도 확대 위치는 그대로 — 같은 곳을 비교하기 좋다
/// - After에서 길게 누르고 있으면 그동안만 원본을 보여 준다
/// - 한 번 탭하면 상단 바·안내를 숨기거나 다시 보인다
class PhotoViewerScreen extends StatefulWidget {
  final File originalImage;
  final Uint8List? transformedBytes;

  /// 0 = Before, 1 = After
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.originalImage,
    required this.transformedBytes,
    this.initialIndex = 1,
  });

  static Future<void> open(
    BuildContext context, {
    required File originalImage,
    required Uint8List? transformedBytes,
    int initialIndex = 1,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => PhotoViewerScreen(
          originalImage: originalImage,
          transformedBytes: transformedBytes,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoomAnim;
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapAt = Offset.zero;

  late int _index;
  bool _peeking = false;
  bool _chromeVisible = true;

  bool get _hasBoth => widget.transformedBytes != null;

  /// 실제로 보여 줄 쪽 — 길게 누르는 동안은 반대쪽(원본).
  int get _shown {
    if (!_hasBoth) return 0;
    return _peeking ? 1 - _index : _index;
  }

  @override
  void initState() {
    super.initState();
    _index = _hasBoth ? widget.initialIndex.clamp(0, 1) : 0;
    _zoomAnim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final tween = _zoomTween;
          if (tween != null) _transform.value = tween.value;
        });
  }

  @override
  void dispose() {
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final current = _transform.value;
    final Matrix4 target;
    if (current.getMaxScaleOnAxis() > 1.01) {
      target = Matrix4.identity();
    } else {
      // 탭한 지점이 제자리에 머물도록 확대
      const s = _doubleTapScale;
      target = Matrix4.diagonal3Values(s, s, 1)
        ..setTranslationRaw(
          -_doubleTapAt.dx * (s - 1),
          -_doubleTapAt.dy * (s - 1),
          0,
        );
    }
    _zoomTween = Matrix4Tween(
      begin: current,
      end: target,
    ).animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic));
    _zoomAnim.forward(from: 0);
  }

  Widget _image(int which) {
    final Widget img = which == 1
        ? Image.memory(
            widget.transformedBytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          )
        : Image.file(
            widget.originalImage,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
    return SizedBox.expand(child: img);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _chromeVisible = !_chromeVisible),
                onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                onDoubleTap: _toggleZoom,
                onLongPressStart: _hasBoth
                    ? (_) => setState(() => _peeking = true)
                    : null,
                onLongPressEnd: _hasBoth
                    ? (_) => setState(() => _peeking = false)
                    : null,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 6,
                  child: _image(_shown),
                ),
              ),
            ),
            // 길게 누르는 동안 무엇을 보고 있는지 표시
            if (_peeking)
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 0,
                right: 0,
                child: Center(
                  child: _Pill(text: _shown == 0 ? 'Before (원본)' : 'After'),
                ),
              ),
            // 상단 바 + 하단 안내
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: AnimatedOpacity(
                  opacity: _chromeVisible && !_peeking ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Stack(
                    children: [
                      _TopBar(
                        hasBoth: _hasBoth,
                        index: _index,
                        onClose: () => Navigator.of(context).pop(),
                        onSelect: (i) => setState(() => _index = i),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                        child: Center(
                          child: _Pill(
                            text: _hasBoth
                                ? '두 손가락으로 확대 · 두 번 탭 · 길게 눌러 비교'
                                : '두 손가락으로 확대 · 두 번 탭',
                            subtle: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool hasBoth;
  final int index;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;

  const _TopBar({
    required this.hasBoth,
    required this.index,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 4,
        right: 4,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: '닫기',
            onPressed: onClose,
          ),
          const Spacer(),
          if (hasBoth)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Segment(
                    label: 'Before',
                    selected: index == 0,
                    onTap: () => onSelect(0),
                  ),
                  _Segment(
                    label: 'After',
                    selected: index == 1,
                    onTap: () => onSelect(1),
                  ),
                ],
              ),
            ),
          const Spacer(),
          const SizedBox(width: 48), // 닫기 버튼과 균형
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool subtle;

  const _Pill({required this.text, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: subtle ? 0.45 : 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: subtle ? 0.85 : 1),
          fontSize: subtle ? 12 : 14,
          fontWeight: subtle ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
  }
}
