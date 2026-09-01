import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_analysis.freezed.dart';
part 'photo_analysis.g.dart';

@freezed
sealed class PhotoAnalysisResponse with _$PhotoAnalysisResponse {
  const factory PhotoAnalysisResponse({
    required ColorAnalysis colorAnalysis,
    required CompositionAnalysis compositionAnalysis,
    required ToneReport toneReport,
    required List<String> shootingTips,
    required List<String> editingTips,
    required int overallScore,
    @Default([]) List<String> hashtags,
  }) = _PhotoAnalysisResponse;

  factory PhotoAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$PhotoAnalysisResponseFromJson(json);
}

@freezed
sealed class ColorAnalysis with _$ColorAnalysis {
  const factory ColorAnalysis({
    required List<String> dominantColors,
    required String colorTemperature,
    required double saturationLevel,
    required double brightnessLevel,
    required String colorHarmony,
    required String paletteDescription,
  }) = _ColorAnalysis;

  factory ColorAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ColorAnalysisFromJson(json);
}

@freezed
sealed class CompositionAnalysis with _$CompositionAnalysis {
  const factory CompositionAnalysis({
    required String primaryTechnique,
    required double balanceScore,
    required List<String> strengths,
    required List<String> improvements,
  }) = _CompositionAnalysis;

  factory CompositionAnalysis.fromJson(Map<String, dynamic> json) =>
      _$CompositionAnalysisFromJson(json);
}

@freezed
sealed class ToneReport with _$ToneReport {
  const factory ToneReport({
    required String overallMood,
    required String styleCategory,
    required String narrative,
  }) = _ToneReport;

  factory ToneReport.fromJson(Map<String, dynamic> json) =>
      _$ToneReportFromJson(json);
}
