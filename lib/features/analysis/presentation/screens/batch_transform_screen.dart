import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../providers/batch_transform_provider.dart';

class BatchTransformScreen extends ConsumerStatefulWidget {
  final List<File> imageFiles;

  const BatchTransformScreen({super.key, required this.imageFiles});

  @override
  ConsumerState<BatchTransformScreen> createState() =>
      _BatchTransformScreenState();
}

class _BatchTransformScreenState extends ConsumerState<BatchTransformScreen> {
  double _dividerPosition = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batchTransformProvider.notifier).startBatch(widget.imageFiles);
    });
  }

  @override
  void dispose() {
    // Don't reset here — let the user navigate back and re-enter
    super.dispose();
  }

  Future<void> _onSaveAll() async {
    final count =
        await ref.read(batchTransformProvider.notifier).saveAll();
    if (mounted) {
      showInstaToast(context, '$count장이 저장되었습니다',
          icon: Icons.check_circle_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchState = ref.watch(batchTransformProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '일괄 변형',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(batchTransformProvider.notifier).reset();
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          if (batchState.status == BatchStatus.reviewing ||
              batchState.status == BatchStatus.done)
            // 인스타그램 편집 화면의 그래디언트 완료 액션
            GestureDetector(
              onTap: batchState.status == BatchStatus.saving
                  ? null
                  : _onSaveAll,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: Center(
                  child: batchState.status == BatchStatus.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const GradientText(
                          '전체 저장',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, batchState),
    );
  }

  Widget _buildBody(BuildContext context, BatchTransformState batchState) {
    switch (batchState.status) {
      case BatchStatus.idle:
        return const Center(child: Text('준비 중...'));

      case BatchStatus.processing:
        return _ProcessingView(
          currentIndex: batchState.currentIndex,
          totalCount: batchState.totalCount,
          completedCount: batchState.completedCount,
          currentFile: batchState.imageFiles.isNotEmpty
              ? batchState.imageFiles[batchState.currentIndex]
              : null,
        );

      case BatchStatus.reviewing:
      case BatchStatus.saving:
      case BatchStatus.done:
        if (batchState.results.isEmpty) {
          return const Center(child: Text('결과가 없습니다'));
        }
        final currentResult = batchState.results[batchState.currentIndex];
        return Column(
          children: [
            // 진행 표시
            _ProgressBar(
              completedCount: batchState.results.where((r) => r.isSuccess).length,
              totalCount: batchState.totalCount,
              isDone: batchState.status == BatchStatus.done,
            ),

            // Before/After 이미지
            Expanded(
              flex: 5,
              child: _BatchBeforeAfterView(
                originalFile: currentResult.originalFile,
                transformedBytes: currentResult.transformedBytes,
                dividerPosition: _dividerPosition,
                errorMessage: currentResult.errorMessage,
                onDividerChanged: (pos) {
                  setState(() => _dividerPosition = pos);
                },
              ),
            ),

            // 하단 썸네일 가로 스크롤
            SizedBox(
              height: 80,
              child: _ThumbnailStrip(
                results: batchState.results,
                currentIndex: batchState.currentIndex,
                onTap: (index) {
                  ref
                      .read(batchTransformProvider.notifier)
                      .setCurrentIndex(index);
                },
              ),
            ),
          ],
        );

      case BatchStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  batchState.errorMessage ?? '오류가 발생했습니다',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 160,
                  child: InstaSecondaryButton(
                    label: '다시 시도',
                    icon: Icons.refresh,
                    onPressed: () {
                      ref
                          .read(batchTransformProvider.notifier)
                          .startBatch(widget.imageFiles);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

// ── 처리 중 뷰 ──

class _ProcessingView extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final int completedCount;
  final File? currentFile;

  const _ProcessingView({
    required this.currentIndex,
    required this.totalCount,
    required this.completedCount,
    this.currentFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentFile != null)
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(currentFile!, fit: BoxFit.contain),
                Container(color: Colors.black.withValues(alpha: 0.5)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: totalCount > 0
                                    ? completedCount / totalCount
                                    : null,
                                strokeWidth: 3,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.primary),
                              ),
                            ),
                            Text(
                              '${completedCount + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$completedCount / $totalCount장 완료',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI가 사진을 분석하고 변형하는 중...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// ── 진행 바 ──

class _ProgressBar extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final bool isDone;

  const _ProgressBar({
    required this.completedCount,
    required this.totalCount,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.photo_library_outlined,
            size: 18,
            color: isDone ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isDone
                ? '전체 저장 완료'
                : '$completedCount / $totalCount장 완료',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                    isDone ? AppColors.success : AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Before/After 뷰 (배치용) ──

class _BatchBeforeAfterView extends StatelessWidget {
  final File originalFile;
  final Uint8List? transformedBytes;
  final double dividerPosition;
  final String? errorMessage;
  final ValueChanged<double> onDividerChanged;

  const _BatchBeforeAfterView({
    required this.originalFile,
    required this.transformedBytes,
    required this.dividerPosition,
    this.errorMessage,
    required this.onDividerChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(originalFile, fit: BoxFit.contain),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '변형 실패',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final newPos = details.localPosition.dx / width;
            onDividerChanged(newPos.clamp(0.0, 1.0));
          },
          child: Stack(
            children: [
              if (transformedBytes != null)
                Positioned.fill(
                  child: Image.memory(transformedBytes!,
                      fit: BoxFit.contain, gaplessPlayback: true),
                )
              else
                Positioned.fill(
                  child: Image.file(originalFile, fit: BoxFit.contain),
                ),
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftClipper(dividerPosition),
                  child: Image.file(originalFile, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                left: width * dividerPosition - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: width * dividerPosition - 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.swap_horiz,
                        size: 18, color: Colors.black54),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _OverlayLabel('Before'),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _OverlayLabel('After'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlayLabel extends StatelessWidget {
  final String text;
  const _OverlayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => fraction != old.fraction;
}

// ── 하단 썸네일 스트립 ──

class _ThumbnailStrip extends StatelessWidget {
  final List<BatchItemResult> results;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ThumbnailStrip({
    required this.results,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 변형된 이미지 또는 원본
                  result.transformedBytes != null
                      ? Image.memory(
                          result.transformedBytes!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Image.file(
                          result.originalFile,
                          fit: BoxFit.cover,
                        ),
                  // 실패 표시
                  if (!result.isSuccess)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child:
                            Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                      ),
                    ),
                  // 인덱스 표시
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
