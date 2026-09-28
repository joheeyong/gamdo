import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/image_service.dart';
import 'package:gamdo/features/analysis/data/claude_datasource.dart';
import 'package:gamdo/features/analysis/data/repositories/transform_repository_impl.dart';
import 'package:gamdo/features/analysis/domain/entities/transform_params.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 서버 analyze-and-transform 응답의 params (analysis_to_transform_params 형태, 평탄화).
const _serverParams = <String, dynamic>{
  'brightness': 0.1,
  'contrast': 0.05,
  'auto_wb': 0.6,
  'denoise': 0.4,
  'background_blur': 0.25,
  'tone_curve_preset': 'film',
  'tone_curve_strength': 0.3,
  'tone_curve_points': [
    [0.0, 0.0],
    [1.0, 1.0],
  ],
  'split_shadow_hue': 200.0,
  'split_shadow_strength': 0.2,
  'split_highlight_hue': 40.0,
  'split_highlight_strength': 0.1,
  'hsl_adjust': null,
  'face_slim': 0.0,
};

void main() {
  group('TransformParams 촬영 결함 교정 필드', () {
    test('서버 응답의 auto_wb/denoise/background_blur를 읽는다', () {
      final p = TransformParams.fromJson(_serverParams);
      expect(p.autoWb, 0.6);
      expect(p.denoise, 0.4);
      expect(p.backgroundBlur, 0.25);
      expect(p.toneCurvePreset, 'film');
    });

    test('없으면 0, 범위를 벗어나면 0~1로 묶는다', () {
      expect(TransformParams.fromJson(const {}).autoWb, 0.0);
      final p = TransformParams.fromJson(
          const {'auto_wb': 1.7, 'denoise': -0.2, 'background_blur': 0.5});
      expect(p.autoWb, 1.0);
      expect(p.denoise, 0.0);
      expect(p.backgroundBlur, 0.5);
    });

    test('copyWith/toMap/deltaFrom에 포함된다', () {
      const base = TransformParams(autoWb: 0.3, denoise: 0.2, backgroundBlur: 0.1);
      final copied = base.copyWith(brightness: 0.5);
      expect(copied.autoWb, 0.3);
      expect(copied.denoise, 0.2);
      expect(copied.backgroundBlur, 0.1);
      expect(base.copyWith(denoise: 0.9).denoise, 0.9);

      final map = base.toMap();
      expect(map['autoWb'], 0.3);
      expect(map['denoise'], 0.2);
      expect(map['backgroundBlur'], 0.1);
      expect(base.deltaFrom(base).values.every((v) => v == 0), isTrue);
    });
  });

  group('applyManualTransform → /api/apply-transform 페이로드', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('auto_wb/denoise/background_blur를 서버 키로 보낸다', () async {
      Map<String, dynamic>? sent;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        sent = Map<String, dynamic>.from(options.data as Map);
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'success': true, 'image_base64': 'AA=='},
        ));
      }));

      final repo = TransformRepositoryImpl(
        datasource: GamdoAgentDatasource(dio),
        imageService: ImageService(),
      );
      await repo.applyManualTransform(
        imageBase64: 'AA==',
        params: TransformParams.fromJson(_serverParams),
        toneCurvePoints: _serverParams['tone_curve_points'] as List<dynamic>,
      );

      expect(sent, isNotNull);
      expect(sent!['auto_wb'], 0.6);
      expect(sent!['denoise'], 0.4);
      expect(sent!['background_blur'], 0.25);
      expect(sent!['tone_curve_preset'], 'film');
      expect(sent!['tone_curve_points'], isNotNull);
      // hsl_adjust가 없으면 키 자체를 보내지 않는다 (서버 기본값 None)
      expect(sent!.containsKey('hsl_adjust'), isFalse);
    });
  });
}
