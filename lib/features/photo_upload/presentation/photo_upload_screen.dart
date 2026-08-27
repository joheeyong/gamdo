import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/image_service.dart';
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
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _pickFromCamera() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickFromCamera();
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final analysisNotifier = ref.read(analysisProvider.notifier);
      await analysisNotifier.analyze(_selectedImage!);

      if (!mounted) return;
      final result = ref.read(analysisProvider);
      result.when(
        data: (data) {
          if (data != null) {
            context.go(
              AppRoutes.analysisResult,
              extra: {
                'analysisJson': data.analysisJson,
                'imagePath': data.imagePath,
                'analysisId': data.id,
              },
            );
          }
        },
        loading: () {},
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorAnalysisFailed)),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorAnalysisFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final isLoading = analysisState is AsyncLoading || _isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.selectPhoto),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Image Preview Area
              Expanded(
                child: _selectedImage != null
                    ? _ImagePreview(image: _selectedImage!)
                    : _ImagePickerArea(
                        onGallery: _pickFromGallery,
                        onCamera: _pickFromCamera,
                      ),
              ),
              const SizedBox(height: 16),

              // Source buttons when image is selected
              if (_selectedImage != null && !isLoading) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(context.l10n.fromGallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(context.l10n.fromCamera),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Analysis button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedImage != null && !isLoading
                      ? _startAnalysis
                      : null,
                  child: isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(context.l10n.analyzing),
                          ],
                        )
                      : Text(context.l10n.startAnalysis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File image;

  const _ImagePreview({required this.image});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Image.file(
          image,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _ImagePickerArea({
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PickerButton(
                  icon: Icons.photo_library_outlined,
                  label: '갤러리',
                  onTap: onGallery,
                ),
                const SizedBox(width: 24),
                _PickerButton(
                  icon: Icons.camera_alt_outlined,
                  label: '카메라',
                  onTap: onCamera,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
