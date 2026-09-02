import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/widgets/instagram_widgets.dart';
import '../../../analysis/presentation/analysis_provider.dart';

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
                      '\uB098\uC911\uC5D0 \uD558\uAE30',
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: context.instaSecondary),
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
              Text(
                'Instagram \uC5F0\uACB0',
                style: context.textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                '\uC778\uC2A4\uD0C0\uADF8\uB7A8 \uACC4\uC815\uC744 \uC5F0\uACB0\uD558\uBA74\n\uAC8C\uC2DC\uAE00\uC744 \uBD84\uC11D\uD558\uC5EC \uB098\uB9CC\uC758 \uC2A4\uD0C0\uC77C \uD504\uB85C\uD544\uC744\n\uC790\uB3D9\uC73C\uB85C \uB9CC\uB4E4\uC5B4 \uB4DC\uB9BD\uB2C8\uB2E4.',
                style: context.textTheme.bodyLarge
                    ?.copyWith(color: context.instaSecondary),
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
                      'Instagram\uC73C\uB85C \uACC4\uC18D\uD558\uAE30',
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
                  '\uC5F0\uACB0\uC740 \uC124\uC815\uC5D0\uC11C \uC5B8\uC81C\uB4E0 \uD574\uC81C\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.instaSecondary),
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
