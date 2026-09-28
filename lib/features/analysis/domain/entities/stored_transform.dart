import 'dart:convert';

import 'transform_params.dart';

/// AI 없이 변형 결과를 다시 그리는 데 필요한 값 묶음 (DB `transformJson`).
///
/// `/api/analyze-and-transform`이 한 번 계산한 결과를 그대로 남겨 두고,
/// 기록에서 다시 열 때 `/api/apply-transform`에 되돌려 보낸다 — 저장·공유
/// (`renderForExport`)가 보내는 것과 같은 값이다. 분석 결과(피사체 종류,
/// 피드 적합도 등)는 기록의 analysisJson에 이미 있으므로 여기 두지 않는다.
class StoredTransform {
  /// 인코딩 형식 버전. 읽을 수 없는(더 새로운) 버전이면 [tryDecode]가 null.
  static const int currentVersion = 1;

  final int version;

  /// 서버가 돌려준 params 맵 그대로. [TransformParams.fromJson]으로 푼다.
  final Map<String, dynamic> params;

  /// 수평 보정·크롭 등 기하 편집 (analysis.autoEdits).
  final Map<String, dynamic>? autoEdits;

  /// 하늘/얼굴/배경·국소 영역 보정 (analysis.regionParams).
  final Map<String, dynamic>? regionParams;

  /// 대표 사진에서 뽑은 톤 커브 제어점 (params.tone_curve_points).
  final List<dynamic>? toneCurvePoints;

  /// "왜 이렇게 보정했는지" 한 문장.
  final String? paramsComment;

  const StoredTransform({
    this.version = currentVersion,
    required this.params,
    this.autoEdits,
    this.regionParams,
    this.toneCurvePoints,
    this.paramsComment,
  });

  /// analyze-and-transform 응답에서 재현 정보를 뽑는다.
  ///
  /// 변형 화면이 상태에 담는 것과 같은 출처(analysis.autoEdits 등)를 쓴다.
  factory StoredTransform.fromServerResult(Map<String, dynamic> result) {
    final params = _map(result['params']) ?? <String, dynamic>{};
    final analysis = _map(result['analysis']);
    return StoredTransform(
      params: params,
      autoEdits: _map(analysis?['autoEdits']),
      regionParams: _map(analysis?['regionParams']),
      toneCurvePoints: params['tone_curve_points'] as List<dynamic>?,
      paramsComment: result['params_comment'] as String?,
    );
  }

  /// 화면 슬라이더·요청에 쓰는 형태.
  TransformParams get transformParams => TransformParams.fromJson(params);

  Map<String, dynamic> toJson() => {
        'version': version,
        'params': params,
        'autoEdits': ?autoEdits,
        'regionParams': ?regionParams,
        'toneCurvePoints': ?toneCurvePoints,
        'paramsComment': ?paramsComment,
      };

  String encode() => jsonEncode(toJson());

  /// DB 값을 푼다. null·깨진 JSON·모르는 버전이면 null — 호출부는 v3 이전
  /// 기록처럼 분석을 다시 돌린다.
  static StoredTransform? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final version = (json['version'] as num?)?.toInt() ?? 0;
      if (version < 1 || version > currentVersion) return null;
      final params = _map(json['params']);
      if (params == null) return null;
      return StoredTransform(
        version: version,
        params: params,
        autoEdits: _map(json['autoEdits']),
        regionParams: _map(json['regionParams']),
        toneCurvePoints: json['toneCurvePoints'] as List<dynamic>?,
        paramsComment: json['paramsComment'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : null;
}
