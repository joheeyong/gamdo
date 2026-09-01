import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_constants.dart';

part 'image_service.g.dart';

@riverpod
ImageService imageService(Ref ref) => ImageService();

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: ApiConstants.maxImageSize.toDouble(),
      maxHeight: ApiConstants.maxImageSize.toDouble(),
    );
    if (image == null) return null;
    return File(image.path);
  }

  Future<List<File>> pickMultipleFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: ApiConstants.maxImageSize.toDouble(),
      maxHeight: ApiConstants.maxImageSize.toDouble(),
    );
    return images.map((xf) => File(xf.path)).toList();
  }

  Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: ApiConstants.maxImageSize.toDouble(),
      maxHeight: ApiConstants.maxImageSize.toDouble(),
    );
    if (image == null) return null;
    return File(image.path);
  }

  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: ApiConstants.jpegQuality,
      minWidth: ApiConstants.maxImageSize,
      minHeight: ApiConstants.maxImageSize,
    );

    if (result == null) return file;

    File compressedFile = File(result.path);

    // If still over 5MB, compress more aggressively
    if (await compressedFile.length() > ApiConstants.maxFileSizeBytes) {
      final fallbackPath = p.join(
        dir.path,
        'fallback_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final fallbackResult = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        fallbackPath,
        quality: ApiConstants.fallbackJpegQuality,
        minWidth: ApiConstants.fallbackImageSize,
        minHeight: ApiConstants.fallbackImageSize,
      );
      if (fallbackResult != null) {
        compressedFile = File(fallbackResult.path);
      }
    }

    return compressedFile;
  }

  Future<String> imageToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<({File file, String base64})> processImage(File originalFile) async {
    final compressed = await compressImage(originalFile);
    final base64String = await imageToBase64(compressed);
    return (file: compressed, base64: base64String);
  }
}
