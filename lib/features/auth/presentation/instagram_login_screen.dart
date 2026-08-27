import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/instagram_widgets.dart';
import '../../analysis/presentation/analysis_provider.dart';

class InstagramLoginScreen extends ConsumerWidget {
  const InstagramLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(instagramAuthProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: Text(
                      '나중에 하기',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Instagram icon with gradient ring
              InstagramGradientAvatar(
                size: 100,
                borderWidth: 3,
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Instagram 연결',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '인스타그램 계정을 연결하면\n게시글을 분석하여 나만의 스타일 프로필을\n자동으로 만들어 드립니다.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Login button
              InstagramGradientButton(
                isLoading: auth.isLoading,
                onPressed: () => _onLogin(context, ref),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Instagram으로 계속하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  auth.error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              // Footer info
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  '연결은 설정에서 언제든 해제할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(instagramAuthProvider.notifier).login();
    if (success && context.mounted) {
      // 스타일 분석 파이프라인 트리거
      final auth = ref.read(instagramAuthProvider);
      if (auth.accessToken != null && auth.userId != null) {
        ref.read(styleAnalysisPipelineProvider.notifier).analyzeInstagramProfile(
              accessToken: auth.accessToken!,
              userId: auth.userId!,
            );
      }
      context.go(AppRoutes.home);
    }
  }
}
