import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/services/image_service.dart';
import '../../domain/entities/transform_params.dart';
import '../../domain/repositories/transform_repository.dart';
import '../datasources/gamdo_agent_datasource.dart';

/// [TransformRepository] 구현체 — GamdoAgentDatasource + ImageService.
class TransformRepositoryImpl implements TransformRepository {
  final GamdoAgentDatasource _datasource;
  final ImageService _imageService;

  TransformRepositoryImpl({
    required GamdoAgentDatasource datasource,
    required ImageService imageService,
  })  : _datasource = datasource,
        _imageService = imageService;

  @override
  Future<Map<String, dynamic>> applyManualTransform({
    File? imageFile,
    String? imageBase64,
    bool preview = false,
    required TransformParams params,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    List<dynamic>? toneCurvePoints,
    CancelToken? cancelToken,
  }) async {
    final base64 = imageBase64 ?? await _compressToBase64(imageFile!);

    return _datasource.applyTransform(
      imageBase64: base64,
      preview: preview,
      autoEdits: autoEdits,
      regionParams: regionParams,
      toneCurvePoints: toneCurvePoints,
      brightness: params.brightness,
      contrast: params.contrast,
      clarity: params.clarity,
      dehaze: params.dehaze,
      highlights: params.highlights,
      shadows: params.shadows,
      saturation: params.saturation,
      temperature: params.temperature,
      blemishRemoval: params.blemishRemoval,
      skinSmoothing: params.skinSmoothing,
      vignette: params.vignette,
      sharpness: params.sharpness,
      grain: params.grain,
      autoWb: params.autoWb,
      denoise: params.denoise,
      backgroundBlur: params.backgroundBlur,
      toneCurvePreset: params.toneCurvePreset,
      toneCurveStrength: params.toneCurveStrength,
      splitShadowHue: params.splitShadowHue,
      splitShadowStrength: params.splitShadowStrength,
      splitHighlightHue: params.splitHighlightHue,
      splitHighlightStrength: params.splitHighlightStrength,
      hslAdjust: params.hslAdjust,
      faceSlim: params.faceSlim,
      jawSharpen: params.jawSharpen,
      eyeEnlarge: params.eyeEnlarge,
      legStretch: params.legStretch,
      shoulderWidth: params.shoulderWidth,
      waistSlim: params.waistSlim,
      cancelToken: cancelToken,
    );
  }

  /// 압축해 base64만 쓰고 임시 압축 파일은 바로 지운다.
  Future<String> _compressToBase64(File imageFile) async {
    final processed = await _imageService.processImage(imageFile);
    await _imageService.deleteTempFile(processed.file);
    return processed.base64;
  }
}
