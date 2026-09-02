import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/services/image_service.dart';
import '../../domain/entities/transform_params.dart';
import '../../domain/repositories/transform_repository.dart';
import '../claude_datasource.dart';

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
  Future<TransformResult> autoTransform({
    required File imageFile,
    required Map<String, dynamic> analysis,
    Map<String, dynamic>? styleProfile,
  }) async {
    final processed = await _imageService.processImage(imageFile);
    final result = await _datasource.autoTransform(
      imageBase64: processed.base64,
      analysis: analysis,
      styleProfile: styleProfile,
    );

    final imageB64 = result['image_base64'] as String;
    final paramsMap = result['params'] as Map<String, dynamic>?;
    final params = paramsMap != null
        ? TransformParams.fromJson(paramsMap)
        : const TransformParams();

    return TransformResult(
      imageBytes: Uri.parse('data:;base64,$imageB64').data!.contentAsBytes(),
      params: params,
    );
  }

  @override
  Future<Map<String, dynamic>> applyManualTransform({
    File? imageFile,
    String? imageBase64,
    bool preview = false,
    required TransformParams params,
    Map<String, dynamic>? autoEdits,
    Map<String, dynamic>? regionParams,
    CancelToken? cancelToken,
  }) async {
    final base64 = imageBase64 ??
        (await _imageService.processImage(imageFile!)).base64;

    return _datasource.applyTransform(
      imageBase64: base64,
      preview: preview,
      autoEdits: autoEdits,
      regionParams: regionParams,
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
}
