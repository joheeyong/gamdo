import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/database.dart';
import '../providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/insta_ui.dart';
import '../../../../core/widgets/instagram_widgets.dart';
import '../../../analysis/di/analysis_providers.dart';
import '../../../analysis/presentation/analysis_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../providers/settings_provider.dart';

/// 전체 분석 기록 — 프로필 헤더의 통계에 쓰인다.
final _allAnalysesProvider = StreamProvider<List<AnalysisRecord>>((ref) {
  return ref.watch(historyRepositoryProvider).watchAll();
});

/// 프로필 & 설정 화면.
///
/// 인스타그램 프로필 탭과 같은 구성 — 아바타 + 통계 + 소개(스타일 프로필),
/// 그 아래로 헤어라인으로 나뉜 설정 행들.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);
    final reshapeAsync = ref.watch(reshapeEnabledSettingProvider);
    final isReshapeEnabled = reshapeAsync.value ?? false;
    final styleProfile = ref.watch(userStyleProfileProvider);
    final auth = ref.watch(instagramAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.username != null ? '@${auth.username}' : context.l10n.settings,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(profile: styleProfile),
          const SizedBox(height: 16),
          const InstaHairline(),

          // ── 스타일 프로필 ──
          _StyleProfileSection(profile: styleProfile),
          const InstaHairline(),

          // ── 설정 ──
          const InstaSectionLabel('설정'),
          InstaSettingRow(
            icon: isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            title: context.l10n.darkMode,
            trailing: Switch.adaptive(
              value: isDarkMode,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggle();
                showInstaToast(
                  context,
                  !isDarkMode ? '다크 모드로 변경됨' : '라이트 모드로 변경됨',
                );
              },
            ),
          ),
          const InstaHairline(indent: 16),
          InstaSettingRow(
            icon: Icons.face_retouching_natural_outlined,
            title: '얼굴/체형 보정',
            subtitle: 'AI가 인물 사진에서 자동 추천',
            trailing: Switch.adaptive(
              value: isReshapeEnabled,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              onChanged: (_) =>
                  ref.read(reshapeEnabledSettingProvider.notifier).toggle(),
            ),
          ),
          const InstaHairline(),

          // ── 계정 ──
          const InstaSectionLabel('계정'),
          const _InstagramRow(),
          const InstaHairline(),

          // ── 앱 정보 ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                GradientText(
                  '감도',
                  style: AppTypography.wordmark.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  'v1.0.0  ·  Powered by Claude Vision',
                  style: TextStyle(fontSize: 12, color: context.instaSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 프로필 헤더 ──

class _ProfileHeader extends ConsumerWidget {
  final Map<String, dynamic>? profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(instagramAuthProvider);
    final analyses = ref.watch(_allAnalysesProvider).value ?? const [];

    final count = analyses.length;
    final average = analyses.isEmpty
        ? 0
        : (analyses.map((a) => a.overallScore).reduce((a, b) => a + b) /
                analyses.length)
            .round();
    final styleCount =
        analyses.map((a) => a.styleCategory).toSet().length;

    final primaryStyle = profile?['primaryStyle'] as String? ?? '';
    final moodKeywords =
        (profile?['moodKeywords'] as List<dynamic>?)?.cast<String>() ??
            const <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InstagramGradientAvatar(
                size: 84,
                borderWidth: auth.isConnected ? 2.5 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    backgroundColor: context.instaDivider,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 30,
                      color: context.instaSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InstaStat(value: '$count', label: '분석'),
                      InstaStat(value: '$average', label: '평균 점수'),
                      InstaStat(value: '$styleCount', label: '스타일'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 인스타그램 프로필의 이름/소개 자리
          Text(
            primaryStyle.isNotEmpty ? primaryStyle : '나만의 감각',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.instaPrimaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            moodKeywords.isNotEmpty
                ? moodKeywords.map((k) => '#$k').join(' ')
                : '사진을 분석해 나의 톤앤매너를 찾아보세요',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: moodKeywords.isNotEmpty
                  ? AppColors.actionBlue
                  : context.instaSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 스타일 프로필 섹션 (추가/수정/삭제) ──

class _StyleProfileSection extends ConsumerWidget {
  final Map<String, dynamic>? profile;
  const _StyleProfileSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(instagramAuthProvider);
    final userId = auth.userId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIcon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              Text(
                '나의 스타일 프로필',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.instaPrimaryText,
                ),
              ),
              const Spacer(),
              if (profile != null)
                GestureDetector(
                  onTap: userId == null
                      ? null
                      : () => _showSheet(context, ref, userId),
                  child: Icon(Icons.more_horiz, color: context.instaPrimaryText),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (profile != null) ...[
            _ProfileContent(profile: profile!),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: InstaSecondaryButton(
                label: '스타일 프로필 편집',
                onPressed: userId == null
                    ? null
                    : () => _openEditor(context, ref, userId, profile),
              ),
            ),
          ] else ...[
            Text(
              userId == null
                  ? 'Instagram을 연결하면 게시글을 분석해\n스타일 프로필을 자동으로 만들어 드립니다.'
                  : '아직 스타일 프로필이 없습니다.\nInstagram 분석 또는 직접 입력으로 만들 수 있어요.',
              style: TextStyle(
                fontSize: 13,
                color: context.instaSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: InstaSecondaryButton(
                label: '스타일 프로필 만들기',
                icon: Icons.add,
                onPressed: userId == null
                    ? null
                    : () => _openEditor(context, ref, userId, null),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref, String userId) {
    showInstaSheet(
      context,
      actions: [
        InstaSheetAction(
          icon: Icons.edit_outlined,
          label: '프로필 편집',
          onTap: () => _openEditor(context, ref, userId, profile),
        ),
        InstaSheetAction(
          icon: Icons.delete_outline,
          label: '프로필 삭제',
          isDestructive: true,
          onTap: () => _confirmDelete(context, ref, userId),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await showInstaConfirm(
      context,
      title: '스타일 프로필 삭제',
      message: '스타일 프로필을 삭제하시겠습니까?\n피드백 히스토리도 함께 삭제됩니다.',
      confirmLabel: '삭제',
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(styleRepositoryProvider).deleteStyleProfile(userId);
    ref.read(userStyleProfileProvider.notifier).state = null;
    if (context.mounted) {
      showInstaToast(context, '스타일 프로필이 삭제되었습니다');
    }
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref,
    String userId,
    Map<String, dynamic>? existing,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StyleProfileEditScreen(
          userId: userId,
          existing: existing,
          ref: ref,
        ),
      ),
    );
  }
}

// ── 프로필 내용 표시 (읽기 전용) ──

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final primaryStyle = profile['primaryStyle'] as String? ?? '';
    final trendCategory = profile['trendCategory'] as String?;
    final moodKeywords =
        (profile['moodKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    final colorPref = profile['colorPreference'] as Map<String, dynamic>?;
    final preferredTones = colorPref?['preferredTones'] as String?;
    final saturation = colorPref?['saturationTendency'] as String?;
    final brightness = colorPref?['brightnessTendency'] as String?;
    final contrast = colorPref?['contrast'] as String?;
    final compPref = profile['compositionPreference'] as Map<String, dynamic>?;
    final subject = compPref?['subjectPreference'] as String?;
    final editingStyle = profile['editingStyle'] as Map<String, dynamic>?;
    final filterTendency = editingStyle?['filterTendency'] as String?;
    final grainPref = editingStyle?['grainPreference'] as String?;
    final vignettePref = editingStyle?['vignettePreference'] as String?;
    final skinRetouch = editingStyle?['skinRetouchLevel'] as String?;
    final editingDesc = editingStyle?['description'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary style + trend
        if (primaryStyle.isNotEmpty) ...[
          _label(context, '대표 스타일'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.instagramGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  primaryStyle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trendCategory != null && trendCategory != 'custom')
                _chip(_trendLabel(trendCategory)),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // Mood keywords
        if (moodKeywords.isNotEmpty) ...[
          _label(context, '분위기'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: moodKeywords
                .map((k) => _chip(k, color: AppColors.accent))
                .toList(),
          ),
          const SizedBox(height: 14),
        ],

        // Color preference
        _label(context, '색감 성향'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (preferredTones != null)
              _chip(_toneLabel(preferredTones), color: _toneColor(preferredTones)),
            if (saturation != null) _chip('채도 ${_levelLabel5(saturation)}'),
            if (brightness != null) _chip('밝기 ${_levelLabel5(brightness)}'),
            if (contrast != null) _chip('대비 ${_levelLabel5(contrast)}'),
          ],
        ),
        const SizedBox(height: 14),

        // Subject + editing
        _label(context, '촬영/보정'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (subject != null) _chip('피사체: $subject'),
            if (filterTendency != null) _chip('보정: ${_filterLabel(filterTendency)}', color: filterTendency == 'auto' ? AppColors.accent : AppColors.primary),
            if (grainPref != null && grainPref != 'none') _chip('그레인: ${_grainLabel(grainPref)}', color: grainPref == 'auto' ? AppColors.accent : AppColors.primary),
            if (vignettePref != null && vignettePref != 'none') _chip('비네팅: ${_vignetteLabel(vignettePref)}', color: vignettePref == 'auto' ? AppColors.accent : AppColors.primary),
            if (skinRetouch != null && skinRetouch != 'none') _chip('피부보정: ${_skinLabel(skinRetouch)}', color: skinRetouch == 'auto' ? AppColors.accent : AppColors.primary),
          ],
        ),

        // Editing description
        if (editingDesc != null && editingDesc.isNotEmpty) ...[
          const SizedBox(height: 14),
          _label(context, '보정 성향'),
          const SizedBox(height: 6),
          Text(editingDesc, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: context.instaSecondary,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _chip(String label, {Color color = AppColors.primary}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      );

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

  String _trendLabel(String trend) => switch (trend) {
        'warm_film' => '웜 필름',
        'korean_gamsung' => '한국 감성',
        'cinematic_moody' => '시네마틱',
        'bright_airy' => '밝은 감성',
        'golden_hour' => '골든아워',
        'clean_minimal' => '클린 미니멀',
        _ => trend,
      };

  String _filterLabel(String filter) => switch (filter) {
        'auto' => '자동',
        'none' => '무보정',
        'minimal' => '약하게',
        'moderate' => '보통',
        'strong' => '강하게',
        'very_strong' => '매우 강하게',
        _ => filter,
      };

  String _grainLabel(String v) => switch (v) {
        'auto' => '자동',
        'subtle' => '미세',
        'moderate' => '보통',
        'heavy' => '강함',
        'film' => '필름',
        _ => v,
      };

  String _vignetteLabel(String v) => switch (v) {
        'auto' => '자동',
        'subtle' => '미세',
        'moderate' => '보통',
        'strong' => '강함',
        _ => v,
      };

  String _skinLabel(String v) => switch (v) {
        'auto' => '자동',
        'light' => '가볍게',
        'moderate' => '보통',
        'heavy' => '강하게',
        _ => v,
      };

  String _levelLabel5(String level) => switch (level) {
        'very_high' => '매우 높음',
        'high' => '높음',
        'medium' => '보통',
        'low' => '낮음',
        'very_low' => '매우 낮음',
        _ => _levelLabel(level),
      };
}

// ── 스타일 프로필 편집 화면 ──

class _StyleProfileEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existing;
  final WidgetRef ref;

  const _StyleProfileEditScreen({
    required this.userId,
    required this.existing,
    required this.ref,
  });

  @override
  State<_StyleProfileEditScreen> createState() => _StyleProfileEditScreenState();
}

class _StyleProfileEditScreenState extends State<_StyleProfileEditScreen> {
  late TextEditingController _moodKeywordsController;
  late TextEditingController _editingDescController;

  String _primaryStyle = '미니멀';
  String _trendCategory = 'clean_minimal';
  String _subjectPreference = '혼합';
  String _preferredTones = 'neutral';
  String _saturationTendency = 'medium';
  String _brightnessTendency = 'medium';
  String _contrastTendency = 'medium';
  String _filterTendency = 'auto';
  String _grainPreference = 'auto';
  String _vignettePreference = 'auto';
  String _skinRetouchLevel = 'auto';

  bool _saving = false;

  static const _primaryStyles = [
    '미니멀', '빈티지', '모던', '내추럴', '드라마틱',
    '파스텔', '다크', '필름', '감성', '시네마틱',
  ];

  static const _trendCategories = {
    'warm_film': '웜 필름',
    'korean_gamsung': '한국 감성',
    'cinematic_moody': '시네마틱',
    'bright_airy': '밝은 감성',
    'golden_hour': '골든아워',
    'clean_minimal': '클린 미니멀',
    'custom': '기타',
  };

  static const _subjects = ['인물', '풍경', '음식', '사물', '혼합'];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;

    _primaryStyle = p?['primaryStyle'] as String? ?? '미니멀';
    if (!_primaryStyles.contains(_primaryStyle)) _primaryStyle = '미니멀';

    _trendCategory = p?['trendCategory'] as String? ?? 'clean_minimal';
    if (!_trendCategories.containsKey(_trendCategory)) _trendCategory = 'clean_minimal';

    final compPref = p?['compositionPreference'] as Map<String, dynamic>?;
    _subjectPreference = compPref?['subjectPreference'] as String? ?? '혼합';
    if (!_subjects.contains(_subjectPreference)) _subjectPreference = '혼합';

    final moodList =
        (p?['moodKeywords'] as List<dynamic>?)?.cast<String>() ?? [];
    _moodKeywordsController =
        TextEditingController(text: moodList.join(', '));

    final colorPref = p?['colorPreference'] as Map<String, dynamic>?;
    _preferredTones = colorPref?['preferredTones'] as String? ?? 'neutral';
    _saturationTendency = colorPref?['saturationTendency'] as String? ?? 'medium';
    _brightnessTendency = colorPref?['brightnessTendency'] as String? ?? 'medium';
    _contrastTendency = colorPref?['contrast'] as String? ?? 'medium';

    final editingStyle = p?['editingStyle'] as Map<String, dynamic>?;
    _filterTendency = editingStyle?['filterTendency'] as String? ?? 'auto';
    _grainPreference = editingStyle?['grainPreference'] as String? ?? 'auto';
    _vignettePreference = editingStyle?['vignettePreference'] as String? ?? 'auto';
    _skinRetouchLevel = editingStyle?['skinRetouchLevel'] as String? ?? 'auto';
    _editingDescController =
        TextEditingController(text: editingStyle?['description'] as String? ?? '');
  }

  @override
  void dispose() {
    _moodKeywordsController.dispose();
    _editingDescController.dispose();
    super.dispose();
  }

  List<String> _splitTags(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final profile = <String, dynamic>{
        'primaryStyle': _primaryStyle,
        'trendCategory': _trendCategory,
        'secondaryStyles': <String>[], // 자동 분석 시 채워짐
        'moodKeywords': _splitTags(_moodKeywordsController.text),
        'colorPreference': {
          'preferredTones': _preferredTones,
          'saturationTendency': _saturationTendency,
          'brightnessTendency': _brightnessTendency,
          'contrast': _contrastTendency,
        },
        'compositionPreference': {
          'subjectPreference': _subjectPreference,
        },
        'editingStyle': {
          'filterTendency': _filterTendency,
          'grainPreference': _grainPreference,
          'vignettePreference': _vignettePreference,
          'skinRetouchLevel': _skinRetouchLevel,
          'description': _editingDescController.text.trim(),
        },
      };

      // 기존 targetParams, feedCohesion 등 보존
      final preserve = ['targetParams', 'feedCohesion', 'dominantColors'];
      for (final key in preserve) {
        if (widget.existing?[key] != null) {
          profile[key] = widget.existing![key];
        }
      }
      // colorPreference 내 기존 dominantColors 보존
      final existingColorPref = widget.existing?['colorPreference'] as Map<String, dynamic>?;
      if (existingColorPref?['dominantColors'] != null) {
        (profile['colorPreference'] as Map<String, dynamic>)['dominantColors'] =
            existingColorPref!['dominantColors'];
      }

      final styleRepo = widget.ref.read(styleRepositoryProvider);
      await styleRepo.saveStyleProfile(
        userId: widget.userId,
        styleProfile: profile,
      );

      widget.ref.read(userStyleProfileProvider.notifier).state = profile;

      if (mounted) {
        showInstaToast(context, '스타일 프로필이 저장되었습니다',
            icon: Icons.check_circle_outline);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showInstaToast(context, '저장 실패: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isNew ? '스타일 프로필 만들기' : '스타일 프로필 수정',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // 인스타그램 편집 화면의 그래디언트 '완료' 액션
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GradientText(
                        '완료',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── 스타일 ──
          const InstaSectionLabel('스타일'),

          _fieldLabel('대표 스타일'),
          _PillWrap(
            options: {for (final s in _primaryStyles) s: s},
            value: _primaryStyle,
            onChanged: (v) => setState(() => _primaryStyle = v),
          ),
          const SizedBox(height: 18),

          _fieldLabel('트렌드 카테고리'),
          _PillWrap(
            options: _trendCategories,
            value: _trendCategory,
            onChanged: (v) => setState(() => _trendCategory = v),
          ),
          const SizedBox(height: 18),

          _fieldLabel('분위기 키워드 (쉼표로 구분)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _moodKeywordsController,
              style: AppTypography.input,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '예: 따뜻한, 차분한, 감성적',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const InstaHairline(),

          // ── 색감 ──
          const InstaSectionLabel('색감 성향'),

          _fieldLabel('선호 색온도'),
          _PillWrap(
            value: _preferredTones,
            options: const {
              'cool': '차가운',
              'slightly_cool': '약간 차가운',
              'neutral': '중성',
              'slightly_warm': '약간 따뜻한',
              'warm': '따뜻한',
            },
            onChanged: (v) => setState(() => _preferredTones = v),
          ),
          const SizedBox(height: 14),

          _fieldLabel('채도'),
          _PillWrap(
            value: _saturationTendency,
            options: _levels,
            onChanged: (v) => setState(() => _saturationTendency = v),
          ),
          const SizedBox(height: 14),

          _fieldLabel('밝기'),
          _PillWrap(
            value: _brightnessTendency,
            options: _levels,
            onChanged: (v) => setState(() => _brightnessTendency = v),
          ),
          const SizedBox(height: 14),

          _fieldLabel('대비'),
          _PillWrap(
            value: _contrastTendency,
            options: _levels,
            onChanged: (v) => setState(() => _contrastTendency = v),
          ),
          const SizedBox(height: 8),
          const InstaHairline(),

          // ── 촬영 ──
          const InstaSectionLabel('촬영 성향'),

          _fieldLabel('주로 찍는 피사체'),
          _PillWrap(
            options: {for (final s in _subjects) s: s},
            value: _subjectPreference,
            onChanged: (v) => setState(() => _subjectPreference = v),
          ),
          const SizedBox(height: 8),
          const InstaHairline(),

          // ── 보정 ──
          const InstaSectionLabel('보정 성향'),

          _fieldLabel('보정 강도'),
          _PillWrap(
            value: _filterTendency,
            options: const {
              'auto': '자동',
              'none': '무보정',
              'minimal': '약하게',
              'moderate': '보통',
              'strong': '강하게',
              'very_strong': '매우 강하게',
            },
            onChanged: (v) => setState(() => _filterTendency = v),
          ),
          const SizedBox(height: 14),

          _fieldLabel('그레인(필름 질감)'),
          _PillWrap(
            value: _grainPreference,
            options: const {
              'auto': '자동',
              'none': '없음',
              'subtle': '미세',
              'moderate': '보통',
              'heavy': '강함',
              'film': '필름',
            },
            onChanged: (v) => setState(() => _grainPreference = v),
          ),
          const SizedBox(height: 14),

          _fieldLabel('비네팅(가장자리 어둡게)'),
          _PillWrap(
            value: _vignettePreference,
            options: const {
              'auto': '자동',
              'none': '없음',
              'subtle': '미세',
              'moderate': '보통',
              'strong': '강함',
            },
            onChanged: (v) => setState(() => _vignettePreference = v),
          ),
          const SizedBox(height: 14),

          _fieldLabel('피부 보정 (인물 사진)'),
          _PillWrap(
            value: _skinRetouchLevel,
            options: const {
              'auto': '자동',
              'none': '없음',
              'light': '가볍게',
              'moderate': '보통',
              'heavy': '강하게',
            },
            onChanged: (v) => setState(() => _skinRetouchLevel = v),
          ),
          const SizedBox(height: 18),

          _fieldLabel('보정 성향 설명 (선택)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _editingDescController,
              maxLines: 3,
              style: AppTypography.input,
              decoration: const InputDecoration(
                hintText: '예: 약간 어둡고 톤다운된 필름 느낌을 선호합니다',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, String> _levels = {
    'very_low': '매우 낮음',
    'low': '낮음',
    'medium': '보통',
    'high': '높음',
    'very_high': '매우 높음',
  };

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.instaPrimaryText,
          ),
        ),
      );
}

// ── 선택 알약 묶음 ──

class _PillWrap extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const _PillWrap({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.entries
            .map((e) => InstaPill(
                  label: e.value,
                  selected: value == e.key,
                  dense: true,
                  onTap: () => onChanged(e.key),
                ))
            .toList(),
      ),
    );
  }
}

// ── Instagram 계정 행 ──

class _InstagramRow extends ConsumerWidget {
  const _InstagramRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(instagramAuthProvider);

    if (auth.isConnected) {
      return Column(
        children: [
          InstaSettingRow(
            icon: Icons.camera_alt_outlined,
            title: auth.username != null ? '@${auth.username}' : 'Instagram',
            subtitle: '계정이 연결되어 있습니다',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.instagramGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '연결됨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const InstaHairline(indent: 16),
          InstaSettingRow(
            icon: Icons.link_off,
            title: 'Instagram 연결 해제',
            titleColor: AppColors.error,
            onTap: () async {
              final confirmed = await showInstaConfirm(
                context,
                title: 'Instagram 연결 해제',
                message: '정말로 Instagram 계정 연결을 해제하시겠습니까?',
                confirmLabel: '해제',
                isDestructive: true,
              );
              if (confirmed) {
                ref.read(instagramAuthProvider.notifier).logout();
              }
            },
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인스타그램 계정을 연결하면 게시글을 분석하여\n스타일 프로필을 자동으로 생성합니다.',
            style: TextStyle(
              fontSize: 13,
              color: context.instaSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          InstagramGradientButton(
            height: 40,
            isLoading: auth.isLoading,
            onPressed: () async {
              final success =
                  await ref.read(instagramAuthProvider.notifier).login();
              if (success && context.mounted) {
                final authState = ref.read(instagramAuthProvider);
                if (authState.accessToken != null &&
                    authState.userId != null) {
                  ref
                      .read(styleAnalysisPipelineProvider.notifier)
                      .analyzeInstagramProfile(
                        accessToken: authState.accessToken!,
                        userId: authState.userId!,
                      );
                }
                showInstaToast(context, 'Instagram 계정이 연결되었습니다',
                    icon: Icons.check_circle_outline);
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
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
