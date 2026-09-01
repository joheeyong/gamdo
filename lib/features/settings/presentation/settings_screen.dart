import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/instagram_widgets.dart';
import '../../analysis/presentation/analysis_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);
    final reshapeAsync = ref.watch(reshapeEnabledSettingProvider);
    final isReshapeEnabled = reshapeAsync.value ?? false;
    final styleProfile = ref.watch(userStyleProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark mode
          Card(
            child: SwitchListTile(
              title: Text(context.l10n.darkMode),
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              value: isDarkMode,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 8),

          // 얼굴/체형 보정
          Card(
            child: SwitchListTile(
              title: const Text('얼굴/체형 보정'),
              subtitle: const Text(
                'AI가 인물 사진에서 자동 추천',
                style: TextStyle(fontSize: 12),
              ),
              secondary: const Icon(Icons.face_retouching_natural),
              value: isReshapeEnabled,
              onChanged: (_) {
                ref.read(reshapeEnabledSettingProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 16),

          // Instagram
          _InstagramSection(),
          const SizedBox(height: 16),

          // Style Profile
          if (styleProfile != null) _StyleProfileSection(profile: styleProfile),
          if (styleProfile != null) const SizedBox(height: 16),

          const SizedBox(height: 8),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  '감도 v1.0.0',
                  style: context.textTheme.bodySmall?.copyWith(
                    color:
                        context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Claude Vision',
                  style: context.textTheme.bodySmall?.copyWith(
                    color:
                        context.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleProfileSection extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _StyleProfileSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final primaryStyle = profile['primaryStyle'] as String? ?? '';
    final secondaryStyles =
        (profile['secondaryStyles'] as List<dynamic>?)?.cast<String>() ?? [];
    final moodKeywords =
        (profile['moodKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final colorPref = profile['colorPreference'] as Map<String, dynamic>?;
    final preferredTones = colorPref?['preferredTones'] as String?;
    final saturation = colorPref?['saturationTendency'] as String?;
    final brightness = colorPref?['brightnessTendency'] as String?;
    final editingStyle = profile['editingStyle'] as Map<String, dynamic>?;
    final editingDesc = editingStyle?['description'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.instagramGradient.createShader(bounds),
                  child: const Icon(Icons.auto_awesome, size: 22,
                      color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '나의 스타일 프로필',
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Primary style
            if (primaryStyle.isNotEmpty) ...[
              Text(
                '대표 스타일',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.instagramGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  primaryStyle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Secondary styles + mood keywords
            if (secondaryStyles.isNotEmpty || moodKeywords.isNotEmpty) ...[
              Text(
                '스타일 키워드',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...secondaryStyles.map((s) => _Chip(label: s)),
                  ...moodKeywords.map((k) => _Chip(
                        label: k,
                        color: AppColors.accent,
                      )),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Color preference
            if (preferredTones != null || saturation != null ||
                brightness != null) ...[
              Text(
                '색감 성향',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (preferredTones != null)
                    _Chip(
                      label: _toneLabel(preferredTones),
                      color: _toneColor(preferredTones),
                    ),
                  if (saturation != null)
                    _Chip(label: '채도 ${_levelLabel(saturation)}'),
                  if (brightness != null)
                    _Chip(label: '밝기 ${_levelLabel(brightness)}'),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Editing description
            if (editingDesc != null && editingDesc.isNotEmpty) ...[
              Text(
                '보정 성향',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                editingDesc,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _toneLabel(String tone) => switch (tone) {
        'warm' => '따뜻한 톤',
        'cool' => '차가운 톤',
        'neutral' => '중성 톤',
        'mixed' => '혼합 톤',
        _ => tone,
      };

  Color _toneColor(String tone) => switch (tone) {
        'warm' => AppColors.warmColor,
        'cool' => AppColors.coolColor,
        _ => AppColors.primary,
      };

  String _levelLabel(String level) => switch (level) {
        'high' => '높음',
        'medium' => '보통',
        'low' => '낮음',
        _ => level,
      };
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _InstagramSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(instagramAuthProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.instagramGradient.createShader(bounds),
                  child:
                      const Icon(Icons.camera_alt, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Instagram',
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (auth.isConnected) ...[
              Row(
                children: [
                  InstagramGradientAvatar(
                    size: 36,
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.username != null
                              ? '@${auth.username}'
                              : '연결됨',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '계정이 연결되어 있습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Instagram 연결 해제'),
                        content: const Text('정말로 Instagram 계정 연결을 해제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('해제'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ref.read(instagramAuthProvider.notifier).logout();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('연결 해제'),
                ),
              ),
            ] else ...[
              Text(
                '인스타그램 계정을 연결하면 게시글을 분석하여\n스타일 프로필을 자동으로 생성합니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              InstagramGradientButton(
                height: 40,
                isLoading: auth.isLoading,
                onPressed: () async {
                  final success = await ref
                      .read(instagramAuthProvider.notifier)
                      .login();
                  if (success && context.mounted) {
                    // 스타일 분석 파이프라인 트리거
                    final authState =
                        ref.read(instagramAuthProvider);
                    if (authState.accessToken != null &&
                        authState.userId != null) {
                      ref
                          .read(styleAnalysisPipelineProvider.notifier)
                          .analyzeInstagramProfile(
                            accessToken: authState.accessToken!,
                            userId: authState.userId!,
                          );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Instagram 계정이 연결되었습니다!'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Instagram 연결하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  auth.error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
