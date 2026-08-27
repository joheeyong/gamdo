import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/analysis_repository.dart';

class AnalysisResult {
  final int id;
  final String analysisJson;
  final String imagePath;

  AnalysisResult({
    required this.id,
    required this.analysisJson,
    required this.imagePath,
  });
}

/// 사용자 스타일 프로필을 저장하는 프로바이더
final userStyleProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class AnalysisNotifier extends Notifier<AsyncValue<AnalysisResult?>> {
  @override
  AsyncValue<AnalysisResult?> build() => const AsyncData(null);

  /// 사용자 게시글/피드/스토리 분석
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
  }) async {
    final repo = ref.read(analysisRepositoryProvider);
    final result = await repo.analyzeUser(
      posts: posts,
      feeds: feeds,
      stories: stories,
    );
    // 스타일 프로필 저장
    ref.read(userStyleProfileProvider.notifier).state = result['styleProfile'];
    return result;
  }

  /// 스타일 프로필에 맞춰 사진 변형 분석
  Future<void> transformPhoto(File imageFile, {Map<String, dynamic>? styleProfile}) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(analysisRepositoryProvider);
      final profile = styleProfile ?? ref.read(userStyleProfileProvider) ?? {};

      final result = await repo.transformPhoto(
        imageFile: imageFile,
        styleProfile: profile,
      );

      state = AsyncData(AnalysisResult(
        id: result.id,
        analysisJson: result.analysisJson,
        imagePath: result.imagePath,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final analysisProvider =
    NotifierProvider<AnalysisNotifier, AsyncValue<AnalysisResult?>>(() {
  return AnalysisNotifier();
});
