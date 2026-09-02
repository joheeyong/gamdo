import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/insta_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingData(
      icon: Icons.auto_awesome,
      title: '\uC0AC\uC9C4, \uAC10\uAC01\uC73C\uB85C \uC77D\uB2E4',
      description: 'AI\uAC00 \uB2F9\uC2E0\uC758 \uC0AC\uC9C4 \uC18D \uC0C9\uAC10, \uAD6C\uB3C4, \uBD84\uC704\uAE30\uB97C\n\uBD84\uC11D\uD558\uC5EC \uC228\uACA8\uC9C4 \uAC10\uAC01\uC744 \uBC1C\uACAC\uD569\uB2C8\uB2E4.',
    ),
    _OnboardingData(
      icon: Icons.palette_outlined,
      title: '\uB098\uB9CC\uC758 \uD1A4\uC564\uB9E4\uB108',
      description: '\uAC8C\uC2DC\uAE00\uACFC \uD53C\uB4DC\uB97C \uBD84\uC11D\uD574\n\uB2F9\uC2E0\uB9CC\uC758 \uC0AC\uC9C4 \uC2A4\uD0C0\uC77C\uC744 \uD504\uB85C\uD30C\uC77C\uB9C1\uD569\uB2C8\uB2E4.',
    ),
    _OnboardingData(
      icon: Icons.trending_up,
      title: '\uC131\uC7A5\uD558\uB294 \uAC10\uAC01',
      description: '\uB9DE\uCDA4 \uBCF4\uC815 \uAC00\uC774\uB4DC\uC640 \uCD2C\uC601 \uD301\uC73C\uB85C\n\uC0AC\uC9C4 \uAC10\uAC01\uC744 \uD55C \uB2E8\uACC4 \uB04C\uC5B4\uC62C\uB9AC\uC138\uC694.',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final storage = StorageService();
    await storage.setOnboardingComplete();
    if (mounted) context.go(AppRoutes.instagramLogin);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _completeOnboarding,
                  child: Text(
                    '\uAC74\uB108\uB6F0\uAE30',
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.instaSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gradient icon ring (Instagram story style)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.storyGradient,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
                            ),
                            child: Icon(
                              page.icon,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: context.textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          style: context.textTheme.bodyLarge
                              ?.copyWith(color: context.instaSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 4,
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.dividerLight,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Instagram-style gradient button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.instagramGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? '\uC2DC\uC791\uD558\uAE30' : '\uB2E4\uC74C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
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
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
