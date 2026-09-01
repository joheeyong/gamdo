import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/image_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../analysis/presentation/transform_provider.dart';

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

  Future<void> _pickMultiple() async {
    final imageService = ref.read(imageServiceProvider);
    final files = await imageService.pickMultipleFromGallery();
    if (files.isNotEmpty && mounted) {
      context.push(AppRoutes.batchTransform, extra: {'imageFiles': files});
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      // 분석 + 변형을 한 번에 수행
      final notifier = ref.read(transformProvider.notifier);
      final result = await notifier.analyzeAndTransform(_selectedImage!);
      if (!mounted) return;

      if (result != null) {
        // 분석 & 변형 완료 → 변형 화면으로 이동 (이미 변형된 이미지 포함)
        context.push(AppRoutes.transform, extra: {
          'analysisJson': result.analysisJson,
          'imagePath': result.imagePath,
        });
      } else {
        final state = ref.read(transformProvider);
        _showError(state.errorMessage);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError([String? detail]) {
    final message = detail != null
        ? '분석 실패: $detail'
        : '분석에 실패했습니다. 다시 시도해 주세요.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transformState = ref.watch(transformProvider);
    final isLoading =
        transformState.status == TransformStatus.loadingAutoTransform ||
            _isProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('새 분석',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: isLoading
            ? null
            : IconButton(
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
                  shaderCallback: (bounds) =>
                      AppColors.instagramGradient.createShader(bounds),
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
        child: isLoading
            ? _AnalysisWaitingView(image: _selectedImage!)
            : _UploadView(
                selectedImage: _selectedImage,
                onPickGallery: _pickFromGallery,
                onPickCamera: _pickFromCamera,
                onPickMultiple: _pickMultiple,
              ),
      ),
    );
  }
}

// ── 업로드 뷰 (기존) ──

class _UploadView extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  final VoidCallback onPickMultiple;

  const _UploadView({
    required this.selectedImage,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickMultiple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: selectedImage != null
              ? Image.file(selectedImage!, fit: BoxFit.contain,
                  width: double.infinity)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      Text(
                        '사진을 선택하세요',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ),
                    ],
                  ),
                ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PickerBtn(
                icon: Icons.photo_library_outlined,
                label: '갤러리',
                onTap: onPickGallery,
              ),
              _PickerBtn(
                icon: Icons.camera_alt_outlined,
                label: '카메라',
                onTap: onPickCamera,
              ),
              _PickerBtn(
                icon: Icons.photo_library_rounded,
                label: '일괄',
                onTap: onPickMultiple,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 분석 대기 뷰 ──

class _AnalysisWaitingView extends StatefulWidget {
  final File image;
  const _AnalysisWaitingView({required this.image});

  @override
  State<_AnalysisWaitingView> createState() => _AnalysisWaitingViewState();
}

class _AnalysisWaitingViewState extends State<_AnalysisWaitingView>
    with SingleTickerProviderStateMixin {
  late final PageController _tipPageController;
  late final Timer _tipTimer;
  int _currentTipIndex = 0;
  int _currentStep = 0;
  late final Timer _stepTimer;

  static const _analysisSteps = [
    (icon: Icons.palette_outlined, text: '색감을 분석하고 있어요'),
    (icon: Icons.grid_on, text: '구도를 파악하고 있어요'),
    (icon: Icons.tune, text: '톤앤매너를 분석하고 있어요'),
    (icon: Icons.auto_fix_high, text: '스타일에 맞는 보정법을 찾고 있어요'),
    (icon: Icons.check_circle_outline, text: '최종 결과를 정리하고 있어요'),
  ];

  static const _tips = [
    (
      icon: Icons.grid_3x3,
      title: '삼분법 활용하기',
      body: '화면을 가로·세로 3등분하는 선의 교차점에\n피사체를 배치하면 안정적인 구도가 만들어져요.',
    ),
    (
      icon: Icons.wb_sunny_outlined,
      title: '골든아워 촬영',
      body: '해 뜨고 1시간, 해 지기 1시간 전의 빛은\n따뜻하고 부드러워 인물·풍경 모두 잘 어울려요.',
    ),
    (
      icon: Icons.contrast,
      title: '명암 대비 활용',
      body: '밝은 부분과 어두운 부분의 차이를 강조하면\n사진에 깊이감과 드라마틱한 분위기가 생겨요.',
    ),
    (
      icon: Icons.colorize,
      title: '색감 통일하기',
      body: '하나의 색 계열로 톤을 통일하면\n피드 전체가 일관된 무드를 가질 수 있어요.',
    ),
    (
      icon: Icons.blur_on,
      title: '배경 흐림 효과',
      body: '피사체와 배경의 거리를 두고 촬영하면\n자연스러운 보케 효과로 주인공이 돋보여요.',
    ),
    (
      icon: Icons.straighten,
      title: '수평 맞추기',
      body: '수평선이나 건물의 선을 기울지 않게 맞추면\n사진이 훨씬 안정적이고 깔끔해 보여요.',
    ),
    (
      icon: Icons.photo_size_select_large,
      title: '여백의 미',
      body: '피사체 주변에 적절한 여백을 두면\n시선이 자연스럽게 주인공에게 집중돼요.',
    ),
    (
      icon: Icons.filter_vintage,
      title: '필터보다 개별 보정',
      body: '필터를 그대로 쓰기보다 밝기·채도·대비를\n개별 조절하면 나만의 톤을 만들 수 있어요.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tipPageController = PageController();

    // 팁 자동 슬라이드: 4초마다
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
      });
      _tipPageController.animateToPage(
        _currentTipIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    // 분석 단계 진행: 3초마다
    _stepTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_currentStep < _analysisSteps.length - 1) {
        setState(() => _currentStep++);
      }
    });
  }

  @override
  void dispose() {
    _tipTimer.cancel();
    _stepTimer.cancel();
    _tipPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _analysisSteps[_currentStep];

    return Column(
      children: [
        // 상단: 사진 + 분석 단계 오버레이
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 사진
              Image.file(widget.image, fit: BoxFit.contain),

              // 반투명 오버레이
              Container(color: Colors.black.withValues(alpha: 0.5)),

              // 분석 단계 표시
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 원형 진행 표시
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: (_currentStep + 1) /
                                  _analysisSteps.length,
                              strokeWidth: 3,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              step.icon,
                              key: ValueKey(_currentStep),
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 단계 텍스트
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        step.text,
                        key: ValueKey(_currentStep),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 단계 인디케이터
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _analysisSteps.length,
                        (i) => Container(
                          width: i <= _currentStep ? 20 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i <= _currentStep
                                ? AppColors.primary
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 하단: 사진 팁 카드 슬라이드
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.instagramGradient.createShader(bounds),
                  child: const Text(
                    '잠깐, 알고 계셨나요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _tipPageController,
                    itemCount: _tips.length,
                    onPageChanged: (i) =>
                        setState(() => _currentTipIndex = i),
                    itemBuilder: (context, index) {
                      final tip = _tips[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(tip.icon, color: AppColors.primary,
                                  size: 28),
                              const SizedBox(height: 10),
                              Text(
                                tip.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tip.body,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 팁 페이지 인디케이터
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _tips.length,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _currentTipIndex
                              ? AppColors.primary
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 공통 위젯 ──

class _PickerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerBtn(
      {required this.icon, required this.label, required this.onTap});

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
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
