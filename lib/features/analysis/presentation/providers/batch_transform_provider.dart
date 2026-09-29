import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/style_profile_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../di/analysis_providers.dart';

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
  /// 실행 세대. reset()이나 새 startBatch()가 올리면, 이전 루프는 자기 세대가
  /// 아님을 보고 state 쓰기·다음 요청을 멈춘다.
  int _generation = 0;
  CancelToken? _cancelToken;

  @override
  BatchTransformState build() {
    ref.onDispose(_cancelRunning);
    return const BatchTransformState();
  }

  void _cancelRunning() {
    _generation++;
    _cancelToken?.cancel('batch cancelled');
    _cancelToken = null;
  }

  /// 배치 처리 시작: 여러 장의 사진을 순차적으로 분석+변형
  Future<void> startBatch(List<File> files) async {
    _cancelRunning();
    final generation = _generation;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    bool isStale() => generation != _generation || cancelToken.isCancelled;

    state = BatchTransformState(
      imageFiles: files,
      results: [],
      currentIndex: 0,
      completedCount: 0,
      status: BatchStatus.processing,
    );

    final repo = ref.read(analysisRepositoryDIProvider);
    final styleProfile = ref.read(userStyleProfileProvider);

    String userId = '';
    try {
      final authState = ref.read(instagramAuthProvider);
      userId = authState.userId ?? '';
    } catch (_) {}

    // 설정의 '피부 보정' — 꺼 두었으면 서버가 잡티 제거·피부 스무딩을 뺀다.
    bool skinRetouchEnabled = true;
    try {
      skinRetouchEnabled =
          await ref.read(skinRetouchEnabledSettingProvider.future);
    } catch (_) {}
    // 설정의 '얼굴/체형 보정' — 예전에는 배치가 이 값을 넘기지 않아 항상 꺼짐이었다.
    bool reshapeEnabled = false;
    try {
      reshapeEnabled = await ref.read(reshapeEnabledSettingProvider.future);
    } catch (_) {}
    if (isStale()) return;

    final results = <BatchItemResult>[];

    for (int i = 0; i < files.length; i++) {
      if (isStale()) return;
      state = state.copyWith(currentIndex: i);

      try {
        final result = await repo.analyzeAndTransform(
          imageFile: files[i],
          styleProfile: styleProfile,
          userId: userId,
          reshapeEnabled: reshapeEnabled,
          skinRetouchEnabled: skinRetouchEnabled,
          cancelToken: cancelToken,
        );
        if (isStale()) return;

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
        if (isStale()) return;
        developer.log('Batch item $i failed: $e', name: 'BatchTransform');
        final msg = e is ApiException ? e.userMessage : '분석에 실패했습니다';
        results.add(BatchItemResult(
          originalFile: files[i],
          errorMessage: msg,
        ));
      }

      state = state.copyWith(
        results: List.from(results),
        completedCount: results.length,
      );
    }

    if (isStale()) return;
    if (identical(_cancelToken, cancelToken)) _cancelToken = null;
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
  ///
  /// 검토 중일 때만 저장한다. 저장이 끝난(done) 뒤 다시 누르면 같은 사진이
  /// 갤러리에 한 번 더 들어가므로 0을 돌려준다.
  Future<int> saveAll() async {
    if (state.status != BatchStatus.reviewing) return 0;
    final generation = _generation;
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
          // 저장 중 화면을 나가 reset됐다면 남은 사진은 저장하지 않는다.
          if (generation != _generation) return savedCount;
        } catch (e) {
          developer.log('Failed to save batch item $i: $e',
              name: 'BatchTransform');
        }
      }

      if (generation != _generation) return savedCount;
      state = state.copyWith(status: BatchStatus.done);
      developer.log('Batch save complete: $savedCount/${state.results.length}',
          name: 'BatchTransform');
    } catch (e) {
      if (generation != _generation) return savedCount;
      developer.log('Batch saveAll failed: $e', name: 'BatchTransform');
      final msg = e is ApiException ? e.userMessage : '저장에 실패했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: BatchStatus.error,
        errorMessage: msg,
      );
    }

    return savedCount;
  }

  /// 상태 초기화. 진행 중인 배치가 있으면 요청을 취소하고 루프를 멈춘다.
  void reset() {
    _cancelRunning();
    state = const BatchTransformState();
  }
}

final batchTransformProvider =
    NotifierProvider<BatchTransformNotifier, BatchTransformState>(() {
  return BatchTransformNotifier();
});
