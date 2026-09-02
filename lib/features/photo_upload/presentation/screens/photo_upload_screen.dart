import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../analysis/presentation/transform_provider.dart';

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
        context.push(
          AppRoutes.transform,
          extra: {
            'analysisJson': result.analysisJson,
            'imagePath': result.imagePath,
          },
        );
      } else {
        final state = ref.read(transformProvider);
        _showError(state.errorMessage);
      }
    } catch (e) {
      _showError(e is ApiException ? e.userMessage : null);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError([String? detail]) {
    final message = detail != null
        ? '\uBD84\uC11D \uC2E4\uD328: $detail'
        : '\uBD84\uC11D\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.';
    showInstaToast(context, message, icon: Icons.error_outline, isError: true);
  }

  Future<void> _cancelAnalysis() async {
    final confirmed = await showInstaConfirm(
      context,
      title: '\uBD84\uC11D \uCDE8\uC18C',
      message:
          '\uC9C4\uD589 \uC911\uC778 \uBD84\uC11D\uC744 \uCDE8\uC18C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
      confirmLabel: '\uCDE8\uC18C',
      cancelLabel: '\uACC4\uC18D',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      // 실제 API 요청도 취소
      ref.read(transformProvider.notifier).cancelAutoTransform();
      setState(() => _isProcessing = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transformState = ref.watch(transformProvider);
    final isLoading =
        transformState.status == TransformStatus.loadingAutoTransform ||
        _isProcessing;

    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isLoading) {
          _cancelAnalysis();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          // 검정 배경에는 라이트 테마의 밝은 헤어라인 대신 어두운 선을 쓴다
          shape: const Border(
            bottom: BorderSide(color: AppColors.dividerDark, width: 0.5),
          ),
          title: const Text(
            '\uC0C8 \uBD84\uC11D',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          leading: isLoading
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelAnalysis,
                )
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
                      '\uBD84\uC11D',
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
              ? _AnalysisWaitingView(
                  image: _selectedImage!,
                  onCancel: _cancelAnalysis,
                )
              : _UploadView(
                  selectedImage: _selectedImage,
                  onPickGallery: _pickFromGallery,
                  onPickCamera: _pickFromCamera,
                  onPickMultiple: _pickMultiple,
                ),
        ),
      ),
    );
  }
}

// -- 업로드 뷰 (기존) --

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
              ? Image.file(
                  selectedImage!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '\uC0AC\uC9C4\uC744 \uC120\uD0DD\uD558\uC138\uC694',
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
                label: '\uAC24\uB7EC\uB9AC',
                onTap: onPickGallery,
              ),
              _PickerBtn(
                icon: Icons.camera_alt_outlined,
                label: '\uCE74\uBA54\uB77C',
                onTap: onPickCamera,
              ),
              _PickerBtn(
                icon: Icons.photo_library_rounded,
                label: '\uC77C\uAD04',
                onTap: onPickMultiple,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -- 분석 대기 뷰 --

class _AnalysisWaitingView extends StatefulWidget {
  final File image;
  final VoidCallback onCancel;
  const _AnalysisWaitingView({required this.image, required this.onCancel});

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
    (
      icon: Icons.palette_outlined,
      text: '\uC0C9\uAC10\uC744 \uBD84\uC11D\uD558\uACE0 \uC788\uC5B4\uC694',
    ),
    (
      icon: Icons.grid_on,
      text: '\uAD6C\uB3C4\uB97C \uD30C\uC545\uD558\uACE0 \uC788\uC5B4\uC694',
    ),
    (
      icon: Icons.tune,
      text:
          '\uD1A4\uC564\uB9E4\uB108\uB97C \uBD84\uC11D\uD558\uACE0 \uC788\uC5B4\uC694',
    ),
    (
      icon: Icons.auto_fix_high,
      text:
          '\uC2A4\uD0C0\uC77C\uC5D0 \uB9DE\uB294 \uBCF4\uC815\uBC95\uC744 \uCC3E\uACE0 \uC788\uC5B4\uC694',
    ),
    (
      icon: Icons.check_circle_outline,
      text:
          '\uCD5C\uC885 \uACB0\uACFC\uB97C \uC815\uB9AC\uD558\uACE0 \uC788\uC5B4\uC694',
    ),
  ];

  static const _tips = [
    (
      icon: Icons.grid_3x3,
      title: '\uC0BC\uBD84\uBC95 \uD65C\uC6A9\uD558\uAE30',
      body:
          '\uD654\uBA74\uC744 \uAC00\uB85C\u00B7\uC138\uB85C 3\uB4F1\uBD84\uD558\uB294 \uC120\uC758 \uAD50\uCC28\uC810\uC5D0\n\uD53C\uC0AC\uCCB4\uB97C \uBC30\uCE58\uD558\uBA74 \uC548\uC815\uC801\uC778 \uAD6C\uB3C4\uAC00 \uB9CC\uB4E4\uC5B4\uC838\uC694.',
    ),
    (
      icon: Icons.wb_sunny_outlined,
      title: '\uACE8\uB4E0\uC544\uC6CC \uCD2C\uC601',
      body:
          '\uD574 \uB728\uACE0 1\uC2DC\uAC04, \uD574 \uC9C0\uAE30 1\uC2DC\uAC04 \uC804\uC758 \uBE5B\uC740\n\uB530\uB73B\uD558\uACE0 \uBD80\uB4DC\uB7EC\uC6CC \uC778\uBB3C\u00B7\uD48D\uACBD \uBAA8\uB450 \uC798 \uC5B4\uC6B8\uB824\uC694.',
    ),
    (
      icon: Icons.contrast,
      title: '\uBA85\uC554 \uB300\uBE44 \uD65C\uC6A9',
      body:
          '\uBC1D\uC740 \uBD80\uBD84\uACFC \uC5B4\uB450\uC6B4 \uBD80\uBD84\uC758 \uCC28\uC774\uB97C \uAC15\uC870\uD558\uBA74\n\uC0AC\uC9C4\uC5D0 \uAE4A\uC774\uAC10\uACFC \uB4DC\uB77C\uB9C8\uD2F1\uD55C \uBD84\uC704\uAE30\uAC00 \uC0DD\uACA8\uC694.',
    ),
    (
      icon: Icons.colorize,
      title: '\uC0C9\uAC10 \uD1B5\uC77C\uD558\uAE30',
      body:
          '\uD558\uB098\uC758 \uC0C9 \uACC4\uC5F4\uB85C \uD1A4\uC744 \uD1B5\uC77C\uD558\uBA74\n\uD53C\uB4DC \uC804\uCCB4\uAC00 \uC77C\uAD00\uB41C \uBB34\uB4DC\uB97C \uAC00\uC9C8 \uC218 \uC788\uC5B4\uC694.',
    ),
    (
      icon: Icons.blur_on,
      title: '\uBC30\uACBD \uD750\uB9BC \uD6A8\uACFC',
      body:
          '\uD53C\uC0AC\uCCB4\uC640 \uBC30\uACBD\uC758 \uAC70\uB9AC\uB97C \uB450\uACE0 \uCD2C\uC601\uD558\uBA74\n\uC790\uC5F0\uC2A4\uB7EC\uC6B4 \uBCF4\uCF00 \uD6A8\uACFC\uB85C \uC8FC\uC778\uACF5\uC774 \uB3CB\uBCF4\uC5EC\uC694.',
    ),
    (
      icon: Icons.straighten,
      title: '\uC218\uD3C9 \uB9DE\uCD94\uAE30',
      body:
          '\uC218\uD3C9\uC120\uC774\uB098 \uAC74\uBB3C\uC758 \uC120\uC744 \uAE30\uC6B8\uC9C0 \uC54A\uAC8C \uB9DE\uCD94\uBA74\n\uC0AC\uC9C4\uC774 \uD6E8\uC52C \uC548\uC815\uC801\uC774\uACE0 \uAE54\uB054\uD574 \uBCF4\uC5EC\uC694.',
    ),
    (
      icon: Icons.photo_size_select_large,
      title: '\uC5EC\uBC31\uC758 \uBBF8',
      body:
          '\uD53C\uC0AC\uCCB4 \uC8FC\uBCC0\uC5D0 \uC801\uC808\uD55C \uC5EC\uBC31\uC744 \uB450\uBA74\n\uC2DC\uC120\uC774 \uC790\uC5F0\uC2A4\uB7FD\uAC8C \uC8FC\uC778\uACF5\uC5D0\uAC8C \uC9D1\uC911\uB3FC\uC694.',
    ),
    (
      icon: Icons.filter_vintage,
      title: '\uD544\uD130\uBCF4\uB2E4 \uAC1C\uBCC4 \uBCF4\uC815',
      body:
          '\uD544\uD130\uB97C \uADF8\uB300\uB85C \uC4F0\uAE30\uBCF4\uB2E4 \uBC1D\uAE30\u00B7\uCC44\uB3C4\u00B7\uB300\uBE44\uB97C\n\uAC1C\uBCC4 \uC870\uC808\uD558\uBA74 \uB098\uB9CC\uC758 \uD1A4\uC744 \uB9CC\uB4E4 \uC218 \uC788\uC5B4\uC694.',
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
          flex: 4,
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
                              value: (_currentStep + 1) / _analysisSteps.length,
                              strokeWidth: 3,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
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
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.instagramGradient.createShader(bounds),
                  child: const Text(
                    '\uC7A0\uAE50, \uC54C\uACE0 \uACC4\uC168\uB098\uC694?',
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
                    onPageChanged: (i) => setState(() => _currentTipIndex = i),
                    itemBuilder: (context, index) {
                      final tip = _tips[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          // 스크롤 없이 카드 내용 전체가 한 번에 보이도록
                          // 공간이 부족하면 비율을 유지한 채 축소한다.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tip.icon,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tip.title,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.username.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tip.body,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.secondary.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 팁 페이지 인디케이터 + 취소 버튼
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: Column(
                    children: [
                      Row(
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
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onCancel,
                        child: Text(
                          '\uCDE8\uC18C',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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

// -- 공통 위젯 --

class _PickerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
