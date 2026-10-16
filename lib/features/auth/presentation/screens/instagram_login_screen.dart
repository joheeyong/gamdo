import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/widgets/instagram_widgets.dart';
import '../../../analysis/presentation/providers/analysis_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/open_url.dart';
import '../../data/instagram_constants.dart';

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
                    onTap: () {
                      AnalyticsService.instance.loginSkipped();
                      context.go(AppRoutes.home);
                    },
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
              // 인스타그램 연결 화면은 인스타그램 브랜드 색을 그대로 쓴다
              InstagramGradientAvatar(
                size: 100,
                borderWidth: 3,
                gradient: AppColors.instagramRingGradient,
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: Color(0xFFE1306C),
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
              const SizedBox(height: 20),
              // Instagram API with Instagram Login은 프로페셔널 계정만 로그인할 수 있다.
              // 개인 계정으로 시도한 사람(심사자 포함)이 고장으로 오해하지 않게 미리 알린다.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.instaSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: context.instaSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '\uBE44\uC988\uB2C8\uC2A4\u00B7\uD06C\uB9AC\uC5D0\uC774\uD130 \uACC4\uC815\uB9CC \uC5F0\uACB0\uD560 \uC218 \uC788\uC5B4\uC694. '
                        '\uAC1C\uC778 \uACC4\uC815\uC740 \uC778\uC2A4\uD0C0\uADF8\uB7A8 \uC571\uC758 \uC124\uC815 > \uACC4\uC815 \uC720\uD615 \uBC0F \uB3C4\uAD6C\uC5D0\uC11C \uBB34\uB8CC\uB85C \uC804\uD658\uD560 \uC218 \uC788\uC5B4\uC694.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.instaSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Login button
              InstagramGradientButton(
                gradient: AppColors.instagramGradient,
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
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      '\uC5F0\uACB0\uC740 \uC124\uC815\uC5D0\uC11C \uC5B8\uC81C\uB4E0 \uD574\uC81C\uD560 \uC218 \uC788\uACE0, '
                      '\uD574\uC81C\uD558\uBA74 \uAC10\uB3C4\uC5D0 \uC800\uC7A5\uB41C \uC778\uC2A4\uD0C0\uADF8\uB7A8 \uB370\uC774\uD130\uB3C4 \uD568\uAED8 \uC0AD\uC81C\uB3FC\uC694.',
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.instaSecondary),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => openExternalUrl(
                          context, InstagramConstants.privacyPolicyUrl),
                      child: const Text('\uAC1C\uC778\uC815\uBCF4\uCC98\uB9AC\uBC29\uCE68'),
                    ),
                  ],
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
