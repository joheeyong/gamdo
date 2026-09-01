import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers/auth_provider.dart';
import '../data/analysis_repository.dart';
import 'analysis_provider.dart';

enum BatchStatus {
  idle,
  processing,
  reviewing,
  saving,
  done,
  error,
}

class BatchItemResult {
  final File originalFile;
  final Uint8List? transformedBytes;
  final Map<String, dynamic>? analysis;
  final String? errorMessage;

  const BatchItemResult({
    required this.originalFile,
    this.transformedBytes,
    this.analysis,
    this.errorMessage,
  });

  bool get isSuccess => transformedBytes != null;
}

class BatchTransformState {
  final List<File> imageFiles;
  final List<BatchItemResult> results;
  final int currentIndex;
  final int completedCount;
  final BatchStatus status;
  final String? errorMessage;

  const BatchTransformState({
    this.imageFiles = const [],
    this.results = const [],
    this.currentIndex = 0,
    this.completedCount = 0,
    this.status = BatchStatus.idle,
    this.errorMessage,
  });

  int get totalCount => imageFiles.length;

  BatchTransformState copyWith({
    List<File>? imageFiles,
    List<BatchItemResult>? results,
    int? currentIndex,
    int? completedCount,
    BatchStatus? status,
    String? errorMessage,
  }) {
    return BatchTransformState(
      imageFiles: imageFiles ?? this.imageFiles,
      results: results ?? this.results,
      currentIndex: currentIndex ?? this.currentIndex,
      completedCount: completedCount ?? this.completedCount,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class BatchTransformNotifier extends Notifier<BatchTransformState> {
  @override
  BatchTransformState build() => const BatchTransformState();

  /// 배치 처리 시작: 여러 장의 사진을 순차적으로 분석+변형
  Future<void> startBatch(List<File> files) async {
    state = BatchTransformState(
      imageFiles: files,
      results: [],
      currentIndex: 0,
      completedCount: 0,
      status: BatchStatus.processing,
    );

    final repo = ref.read(analysisRepositoryProvider);
    final styleProfile = ref.read(userStyleProfileProvider);

    String userId = '';
    try {
      final authState = ref.read(instagramAuthProvider);
      userId = authState.userId ?? '';
    } catch (_) {}

    final results = <BatchItemResult>[];

    for (int i = 0; i < files.length; i++) {
      state = state.copyWith(currentIndex: i);

      try {
        final result = await repo.analyzeAndTransform(
          imageFile: files[i],
          styleProfile: styleProfile,
          userId: userId,
        );

        final imageB64 = result.fullResult['image_base64'] as String?;
        final analysis = result.fullResult['analysis'] as Map<String, dynamic>?;

        if (imageB64 != null) {
          results.add(BatchItemResult(
            originalFile: files[i],
            transformedBytes: base64Decode(imageB64),
            analysis: analysis,
          ));
        } else {
          results.add(BatchItemResult(
            originalFile: files[i],
            errorMessage: '변형 이미지 없음',
          ));
        }
      } catch (e) {
        developer.log('Batch item $i failed: $e', name: 'BatchTransform');
        results.add(BatchItemResult(
          originalFile: files[i],
          errorMessage: e.toString(),
        ));
      }

      state = state.copyWith(
        results: List.from(results),
        completedCount: results.length,
      );
    }

    state = state.copyWith(
      status: BatchStatus.reviewing,
      currentIndex: 0,
    );
  }

  /// 현재 보고 있는 사진 인덱스 변경
  void setCurrentIndex(int index) {
    if (index >= 0 && index < state.results.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// 전체 저장
  Future<int> saveAll() async {
    state = state.copyWith(status: BatchStatus.saving);
    int savedCount = 0;

    try {
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < state.results.length; i++) {
        final result = state.results[i];
        if (result.transformedBytes == null) continue;

        try {
          final savePath = p.join(
            tempDir.path,
            'batch_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          await File(savePath).writeAsBytes(result.transformedBytes!);
          await Gal.putImage(savePath, album: 'Gamdo');
          await File(savePath).delete();
          savedCount++;
        } catch (e) {
          developer.log('Failed to save batch item $i: $e',
              name: 'BatchTransform');
        }
      }

      state = state.copyWith(status: BatchStatus.done);
      developer.log('Batch save complete: $savedCount/${state.results.length}',
          name: 'BatchTransform');
    } catch (e) {
      developer.log('Batch saveAll failed: $e', name: 'BatchTransform');
      state = state.copyWith(
        status: BatchStatus.error,
        errorMessage: '저장 실패: $e',
      );
    }

    return savedCount;
  }

  /// 상태 초기화
  void reset() {
    state = const BatchTransformState();
  }
}

final batchTransformProvider =
    NotifierProvider<BatchTransformNotifier, BatchTransformState>(() {
  return BatchTransformNotifier();
});
