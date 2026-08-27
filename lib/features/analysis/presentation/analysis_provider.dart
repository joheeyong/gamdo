import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AnalysisNotifier extends Notifier<AsyncValue<AnalysisResult?>> {
  @override
  AsyncValue<AnalysisResult?> build() => const AsyncData(null);

  Future<void> analyze(File imageFile) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(analysisRepositoryProvider);
      final result = await repo.analyzePhoto(imageFile);
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
