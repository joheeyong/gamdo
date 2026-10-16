import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_analysis.freezed.dart';
part 'photo_analysis.g.dart';

@freezed
sealed class PhotoAnalysisResponse with _$PhotoAnalysisResponse {
  const factory PhotoAnalysisResponse({
    required ColorAnalysis colorAnalysis,
    required CompositionAnalysis compositionAnalysis,
    required ToneReport toneReport,

    /// 서버가 AI 응답의 일부 필드를 채우지 못해 기본값으로 메웠을 때의 설명.
    /// 비어 있지 않으면 분석 화면 일부가 비어 있을 수 있다는 뜻이다
    /// (사진 보정은 서버가 측정으로 계산하므로 영향이 없다).
    @Default(<String>[]) List<String> warnings,
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

/// 화면에 보여 줄 만한 분석 문장인지. 비어 있거나 서버가 채운 자리표시
/// ('분석 불가')면 null.
String? displayableAnalysisText(String? text) {
  final t = text?.trim();
  if (t == null || t.isEmpty || t == '분석 불가') return null;
  return t;
}
