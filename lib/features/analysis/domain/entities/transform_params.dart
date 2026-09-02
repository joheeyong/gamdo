/// 사진 변형 파라미터 — 색감, 톤, 보정 슬라이더 값.
class TransformParams {
  final double brightness;
  final double contrast;
  final double clarity;
  final double dehaze;
  final double highlights;
  final double shadows;
  final double saturation;
  final double temperature;
  final double blemishRemoval;
  final double skinSmoothing;
  final double vignette;
  final double sharpness;
  final double grain;
  final String toneCurvePreset;
  final double toneCurveStrength;
  final double splitShadowHue;
  final double splitShadowStrength;
  final double splitHighlightHue;
  final double splitHighlightStrength;
  final Map<String, Map<String, double>>? hslAdjust;
  // ── 얼굴/체형 보정 ──
  final double faceSlim;
  final double jawSharpen;
  final double eyeEnlarge;
  final double legStretch;
  final double shoulderWidth;
  final double waistSlim;

  const TransformParams({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.clarity = 0.0,
    this.dehaze = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.saturation = 0.0,
    this.temperature = 0.0,
    this.blemishRemoval = 0.0,
    this.skinSmoothing = 0.0,
    this.vignette = 0.0,
    this.sharpness = 0.0,
    this.grain = 0.0,
    this.toneCurvePreset = 'linear',
    this.toneCurveStrength = 0.0,
    this.splitShadowHue = 0.0,
    this.splitShadowStrength = 0.0,
    this.splitHighlightHue = 0.0,
    this.splitHighlightStrength = 0.0,
    this.hslAdjust,
    this.faceSlim = 0.0,
    this.jawSharpen = 0.0,
    this.eyeEnlarge = 0.0,
    this.legStretch = 0.0,
    this.shoulderWidth = 0.0,
    this.waistSlim = 0.0,
  });

  TransformParams copyWith({
    double? brightness,
    double? contrast,
    double? clarity,
    double? dehaze,
    double? highlights,
    double? shadows,
    double? saturation,
    double? temperature,
    double? blemishRemoval,
    double? skinSmoothing,
    double? vignette,
    double? sharpness,
    double? grain,
    String? toneCurvePreset,
    double? toneCurveStrength,
    double? splitShadowHue,
    double? splitShadowStrength,
    double? splitHighlightHue,
    double? splitHighlightStrength,
    Map<String, Map<String, double>>? hslAdjust,
    double? faceSlim,
    double? jawSharpen,
    double? eyeEnlarge,
    double? legStretch,
    double? shoulderWidth,
    double? waistSlim,
  }) {
    return TransformParams(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      clarity: clarity ?? this.clarity,
      dehaze: dehaze ?? this.dehaze,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      saturation: saturation ?? this.saturation,
      temperature: temperature ?? this.temperature,
      blemishRemoval: blemishRemoval ?? this.blemishRemoval,
      skinSmoothing: skinSmoothing ?? this.skinSmoothing,
      vignette: vignette ?? this.vignette,
      sharpness: sharpness ?? this.sharpness,
      grain: grain ?? this.grain,
      toneCurvePreset: toneCurvePreset ?? this.toneCurvePreset,
      toneCurveStrength: toneCurveStrength ?? this.toneCurveStrength,
      splitShadowHue: splitShadowHue ?? this.splitShadowHue,
      splitShadowStrength: splitShadowStrength ?? this.splitShadowStrength,
      splitHighlightHue: splitHighlightHue ?? this.splitHighlightHue,
      splitHighlightStrength: splitHighlightStrength ?? this.splitHighlightStrength,
      hslAdjust: hslAdjust ?? this.hslAdjust,
      faceSlim: faceSlim ?? this.faceSlim,
      jawSharpen: jawSharpen ?? this.jawSharpen,
      eyeEnlarge: eyeEnlarge ?? this.eyeEnlarge,
      legStretch: legStretch ?? this.legStretch,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      waistSlim: waistSlim ?? this.waistSlim,
    );
  }

  factory TransformParams.fromJson(Map<String, dynamic> json) {
    // toneCurve는 중첩 객체 또는 평탄화된 키로 올 수 있음
    String tcPreset = 'linear';
    double tcStrength = 0.0;
    final toneCurve = json['toneCurve'];
    if (toneCurve is Map<String, dynamic>) {
      tcPreset = (toneCurve['preset'] as String?) ?? 'linear';
      tcStrength = (toneCurve['strength'] as num?)?.toDouble() ?? 0.0;
    } else {
      tcPreset = (json['tone_curve_preset'] as String?) ?? 'linear';
      tcStrength = (json['tone_curve_strength'] as num?)?.toDouble() ?? 0.0;
    }

    // splitToning도 중첩 객체 또는 평탄화된 키로 올 수 있음
    double shHue = 0.0, shStr = 0.0, hlHue = 0.0, hlStr = 0.0;
    final splitToning = json['splitToning'];
    if (splitToning is Map<String, dynamic>) {
      final shadow = splitToning['shadow'];
      final highlight = splitToning['highlight'];
      if (shadow is Map<String, dynamic>) {
        shHue = (shadow['hue'] as num?)?.toDouble() ?? 0.0;
        shStr = (shadow['strength'] as num?)?.toDouble() ?? 0.0;
      }
      if (highlight is Map<String, dynamic>) {
        hlHue = (highlight['hue'] as num?)?.toDouble() ?? 0.0;
        hlStr = (highlight['strength'] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      shHue = (json['split_shadow_hue'] as num?)?.toDouble() ?? 0.0;
      shStr = (json['split_shadow_strength'] as num?)?.toDouble() ?? 0.0;
      hlHue = (json['split_highlight_hue'] as num?)?.toDouble() ?? 0.0;
      hlStr = (json['split_highlight_strength'] as num?)?.toDouble() ?? 0.0;
    }

    // hslAdjust 파싱
    Map<String, Map<String, double>>? hslParsed;
    final hslRaw = json['hslAdjust'] ?? json['hsl_adjust'];
    if (hslRaw is Map<String, dynamic>) {
      final parsed = <String, Map<String, double>>{};
      for (final entry in hslRaw.entries) {
        if (entry.value is Map<String, dynamic>) {
          final adj = <String, double>{};
          for (final k in ['hue', 'saturation', 'lightness']) {
            adj[k] = (entry.value[k] as num?)?.toDouble() ?? 0.0;
          }
          if (adj.values.any((v) => v.abs() >= 0.01)) {
            parsed[entry.key] = adj;
          }
        }
      }
      if (parsed.isNotEmpty) hslParsed = parsed;
    }

    // reshapeParams 파싱
    final reshape = json['reshapeParams'] as Map<String, dynamic>?;
    double faceSlim = 0.0, jawSharpen = 0.0, eyeEnlarge = 0.0;
    double legStretch = 0.0, shoulderWidth = 0.0, waistSlim = 0.0;
    if (reshape != null) {
      faceSlim = (reshape['face_slim'] as num?)?.toDouble() ?? 0.0;
      jawSharpen = (reshape['jaw_sharpen'] as num?)?.toDouble() ?? 0.0;
      eyeEnlarge = (reshape['eye_enlarge'] as num?)?.toDouble() ?? 0.0;
      legStretch = (reshape['leg_stretch'] as num?)?.toDouble() ?? 0.0;
      shoulderWidth = (reshape['shoulder_width'] as num?)?.toDouble() ?? 0.0;
      waistSlim = (reshape['waist_slim'] as num?)?.toDouble() ?? 0.0;
    } else {
      faceSlim = (json['face_slim'] as num?)?.toDouble() ?? 0.0;
      jawSharpen = (json['jaw_sharpen'] as num?)?.toDouble() ?? 0.0;
      eyeEnlarge = (json['eye_enlarge'] as num?)?.toDouble() ?? 0.0;
      legStretch = (json['leg_stretch'] as num?)?.toDouble() ?? 0.0;
      shoulderWidth = (json['shoulder_width'] as num?)?.toDouble() ?? 0.0;
      waistSlim = (json['waist_slim'] as num?)?.toDouble() ?? 0.0;
    }

    return TransformParams(
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      clarity: (json['clarity'] as num?)?.toDouble() ?? 0.0,
      dehaze: (json['dehaze'] as num?)?.toDouble() ?? 0.0,
      highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
      shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      blemishRemoval: (json['blemish_removal'] as num?)?.toDouble() ?? 0.0,
      skinSmoothing: (json['skin_smoothing'] as num?)?.toDouble() ?? 0.0,
      vignette: (json['vignette'] as num?)?.toDouble() ?? 0.0,
      sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0.0,
      grain: (json['grain'] as num?)?.toDouble() ?? 0.0,
      toneCurvePreset: tcPreset,
      toneCurveStrength: tcStrength,
      splitShadowHue: shHue,
      splitShadowStrength: shStr,
      splitHighlightHue: hlHue,
      splitHighlightStrength: hlStr,
      hslAdjust: hslParsed,
      faceSlim: faceSlim,
      jawSharpen: jawSharpen,
      eyeEnlarge: eyeEnlarge,
      legStretch: legStretch,
      shoulderWidth: shoulderWidth,
      waistSlim: waistSlim,
    );
  }

  Map<String, double> toMap() => {
        'brightness': brightness,
        'contrast': contrast,
        'clarity': clarity,
        'dehaze': dehaze,
        'highlights': highlights,
        'shadows': shadows,
        'saturation': saturation,
        'temperature': temperature,
        'blemishRemoval': blemishRemoval,
        'skinSmoothing': skinSmoothing,
        'vignette': vignette,
        'sharpness': sharpness,
        'grain': grain,
        'toneCurveStrength': toneCurveStrength,
        'splitShadowStrength': splitShadowStrength,
        'splitHighlightStrength': splitHighlightStrength,
        'faceSlim': faceSlim,
        'jawSharpen': jawSharpen,
        'eyeEnlarge': eyeEnlarge,
        'legStretch': legStretch,
        'shoulderWidth': shoulderWidth,
        'waistSlim': waistSlim,
      };

  /// AI 추천값과 최종 사용값의 차이(delta) 계산
  Map<String, double> deltaFrom(TransformParams other) {
    final thisMap = toMap();
    final otherMap = other.toMap();
    return {
      for (final key in thisMap.keys) key: thisMap[key]! - otherMap[key]!,
    };
  }
}
