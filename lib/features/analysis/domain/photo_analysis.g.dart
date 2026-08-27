// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoAnalysisResponse _$PhotoAnalysisResponseFromJson(
  Map<String, dynamic> json,
) => _PhotoAnalysisResponse(
  colorAnalysis: ColorAnalysis.fromJson(
    json['colorAnalysis'] as Map<String, dynamic>,
  ),
  compositionAnalysis: CompositionAnalysis.fromJson(
    json['compositionAnalysis'] as Map<String, dynamic>,
  ),
  toneReport: ToneReport.fromJson(json['toneReport'] as Map<String, dynamic>),
  shootingTips: (json['shootingTips'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  editingTips: (json['editingTips'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  overallScore: (json['overallScore'] as num).toInt(),
);

Map<String, dynamic> _$PhotoAnalysisResponseToJson(
  _PhotoAnalysisResponse instance,
) => <String, dynamic>{
  'colorAnalysis': instance.colorAnalysis,
  'compositionAnalysis': instance.compositionAnalysis,
  'toneReport': instance.toneReport,
  'shootingTips': instance.shootingTips,
  'editingTips': instance.editingTips,
  'overallScore': instance.overallScore,
};

_ColorAnalysis _$ColorAnalysisFromJson(Map<String, dynamic> json) =>
    _ColorAnalysis(
      dominantColors: (json['dominantColors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      colorTemperature: json['colorTemperature'] as String,
      saturationLevel: (json['saturationLevel'] as num).toDouble(),
      brightnessLevel: (json['brightnessLevel'] as num).toDouble(),
      colorHarmony: json['colorHarmony'] as String,
      paletteDescription: json['paletteDescription'] as String,
    );

Map<String, dynamic> _$ColorAnalysisToJson(_ColorAnalysis instance) =>
    <String, dynamic>{
      'dominantColors': instance.dominantColors,
      'colorTemperature': instance.colorTemperature,
      'saturationLevel': instance.saturationLevel,
      'brightnessLevel': instance.brightnessLevel,
      'colorHarmony': instance.colorHarmony,
      'paletteDescription': instance.paletteDescription,
    };

_CompositionAnalysis _$CompositionAnalysisFromJson(Map<String, dynamic> json) =>
    _CompositionAnalysis(
      primaryTechnique: json['primaryTechnique'] as String,
      balanceScore: (json['balanceScore'] as num).toDouble(),
      strengths: (json['strengths'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      improvements: (json['improvements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CompositionAnalysisToJson(
  _CompositionAnalysis instance,
) => <String, dynamic>{
  'primaryTechnique': instance.primaryTechnique,
  'balanceScore': instance.balanceScore,
  'strengths': instance.strengths,
  'improvements': instance.improvements,
};

_ToneReport _$ToneReportFromJson(Map<String, dynamic> json) => _ToneReport(
  overallMood: json['overallMood'] as String,
  styleCategory: json['styleCategory'] as String,
  narrative: json['narrative'] as String,
);

Map<String, dynamic> _$ToneReportToJson(_ToneReport instance) =>
    <String, dynamic>{
      'overallMood': instance.overallMood,
      'styleCategory': instance.styleCategory,
      'narrative': instance.narrative,
    };
