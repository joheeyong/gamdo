import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/image_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../analysis/presentation/analysis_provider.dart';

class PhotoUploadScreen extends ConsumerStatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  ConsumerState<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends ConsumerState<PhotoUploadScreen> {
  File? _selectedImage;
  bool _isProcessing = false;

  Future<void> _pickFromGallery() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickFromGallery();
    if (file != null && mounted) setState(() => _selectedImage = file);
  }

  Future<void> _pickFromCamera() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickFromCamera();
    if (file != null && mounted) setState(() => _selectedImage = file);
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(analysisProvider.notifier);
      await notifier.transformPhoto(_selectedImage!);
      if (!mounted) return;

      final result = ref.read(analysisProvider);
      result.when(
        data: (data) {
          if (data != null) {
            context.go(AppRoutes.analysisResult, extra: {
              'analysisJson': data.analysisJson,
              'imagePath': data.imagePath,
              'analysisId': data.id,
            });
          }
        },
        loading: () {},
        error: (e, _) => _showError(),
      );
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('분석에 실패했습니다. 다시 시도해 주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(analysisProvider) is AsyncLoading || _isProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('새 분석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedImage != null && !isLoading)
            GestureDetector(
              onTap: _startAnalysis,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ShaderMask(
                  shaderCallback: (bounds) => AppColors.instagramGradient.createShader(bounds),
                  child: const Text(
                    '분석',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image Preview (Instagram crop style)
            Expanded(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.contain, width: double.infinity)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: Colors.white38),
                          const SizedBox(height: 16),
                          Text(
                            '사진을 선택하세요',
                            style: TextStyle(color: Colors.white60, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
            ),

            // Loading overlay
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.instagramGradient.createShader(bounds),
                      child: const Text(
                        'AI가 사진을 분석하고 있습니다...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom picker bar
            if (!isLoading)
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PickerBtn(
                      icon: Icons.photo_library_outlined,
                      label: '갤러리',
                      onTap: _pickFromGallery,
                    ),
                    _PickerBtn(
                      icon: Icons.camera_alt_outlined,
                      label: '카메라',
                      onTap: _pickFromCamera,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
