import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/style_profile_provider.dart';
export '../../../../core/providers/style_profile_provider.dart';
import '../../../../core/services/instagram_service.dart';
import '../../di/analysis_providers.dart';

class AnalysisResult {
  final int id;
  final String analysisJson;
  final String imagePath;

  AnalysisResult({
    required this.id,
    required this.analysisJson,
    required this.imagePath,
  });
}

class AnalysisNotifier extends Notifier<AsyncValue<AnalysisResult?>> {
  @override
  AsyncValue<AnalysisResult?> build() => const AsyncData(null);

  /// 사용자 게시글/피드/스토리 분석
  Future<Map<String, dynamic>> analyzeUser({
    List<Map<String, dynamic>> posts = const [],
    List<Map<String, dynamic>> feeds = const [],
    List<Map<String, dynamic>> stories = const [],
  }) async {
    final repo = ref.read(analysisRepositoryDIProvider);
    final result = await repo.analyzeUser(
      posts: posts,
      feeds: feeds,
      stories: stories,
    );
    ref.read(userStyleProfileProvider.notifier).state = result['styleProfile'];
    return result;
  }
}

final analysisProvider =
    NotifierProvider<AnalysisNotifier, AsyncValue<AnalysisResult?>>(() {
  return AnalysisNotifier();
});

// ── Style Analysis Pipeline ──

enum StyleAnalysisStatus {
  idle,
  fetchingMedia,
  analyzingStyle,
  savingProfile,
  completed,
  error,
}

class StyleAnalysisState {
  final StyleAnalysisStatus status;
  final String? errorMessage;
  final int mediaCount;

  const StyleAnalysisState({
    this.status = StyleAnalysisStatus.idle,
    this.errorMessage,
    this.mediaCount = 0,
  });

  StyleAnalysisState copyWith({
    StyleAnalysisStatus? status,
    String? errorMessage,
    int? mediaCount,
  }) {
    return StyleAnalysisState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      mediaCount: mediaCount ?? this.mediaCount,
    );
  }

  String get statusMessage => switch (status) {
        StyleAnalysisStatus.idle => '',
        StyleAnalysisStatus.fetchingMedia => '게시글, 피드, 스토리를 가져오는 중...',
        StyleAnalysisStatus.analyzingStyle =>
          '$mediaCount개 콘텐츠의 스타일을 분석하는 중...',
        StyleAnalysisStatus.savingProfile => '프로필을 저장하는 중...',
        StyleAnalysisStatus.completed => '스타일 분석이 완료되었습니다!',
        StyleAnalysisStatus.error => errorMessage ?? '분석 중 오류가 발생했습니다',
      };
}

class StyleAnalysisNotifier extends Notifier<StyleAnalysisState> {
  @override
  StyleAnalysisState build() => const StyleAnalysisState();

  /// Instagram 프로필 분석 파이프라인.
  Future<void> analyzeInstagramProfile({
    required String accessToken,
    required String userId,
  }) async {
    try {
      // 1. 미디어 조회
      state = state.copyWith(status: StyleAnalysisStatus.fetchingMedia);
      developer.log('Fetching media...', name: 'StyleAnalysis');

      final prefs = await SharedPreferences.getInstance();
      final proxyUrl =
          prefs.getString('proxy_url') ?? ApiConstants.defaultProxyUrl;
      final dio = ref.read(dioProvider);
      final instagramService = InstagramService(
        dio: dio,
        serverBaseUrl: proxyUrl,
      );

      // 미디어(게시글+피드) 조회와 스토리 조회를 병렬 실행
      final mediaFuture = instagramService.fetchMedia(accessToken);
      final storiesFuture = instagramService.fetchStories(accessToken)
          .catchError((e) {
        developer.log('Stories fetch failed (계속 진행): $e',
            name: 'StyleAnalysis');
        return <Map<String, dynamic>>[];
      });

      final results = await Future.wait([mediaFuture, storiesFuture]);
      final media = results[0];
      final storiesRaw = results[1];

      // 2. 미디어를 타입별로 분류
      //    - posts: IMAGE (단일 이미지 게시글)
      //    - feeds: CAROUSEL_ALBUM, VIDEO (피드에 올라온 다른 형식)
      //    - stories: 스토리 API에서 별도 조회
      final postItems = media
          .where((m) => m['media_type'] == 'IMAGE')
          .toList();
      final feedItems = media
          .where((m) =>
              m['media_type'] == 'CAROUSEL_ALBUM' ||
              m['media_type'] == 'VIDEO')
          .toList();

      final totalCount = postItems.length + feedItems.length + storiesRaw.length;

      if (totalCount == 0) {
        state = state.copyWith(
          status: StyleAnalysisStatus.error,
          errorMessage: '분석할 게시글이 없습니다',
        );
        return;
      }

      state = state.copyWith(
        status: StyleAnalysisStatus.analyzingStyle,
        mediaCount: totalCount,
      );
      developer.log(
          'Analyzing $totalCount items (posts: ${postItems.length}, '
          'feeds: ${feedItems.length}, stories: ${storiesRaw.length})',
          name: 'StyleAnalysis');

      // 3. 각 타입을 공통 형식으로 변환
      // VIDEO의 media_url은 .mp4다. 썸네일을 먼저 써야 한다 —
      // 동영상 URL을 넘기면 서버가 받아서 열지 못하고 버리는데,
      // 그 사이 분석 장수 한도만 까먹는다.
      Map<String, dynamic> toItem(Map<String, dynamic> m) {
        final isVideo = m['media_type'] == 'VIDEO';
        final url = isVideo
            ? (m['thumbnail_url'] ?? m['media_url'] ?? '')
            : (m['media_url'] ?? m['thumbnail_url'] ?? '');
        return {
          'text': m['caption'] ?? '',
          'image_url': url,
          'timestamp': m['timestamp'] ?? '',
        };
      }

      bool hasImage(Map<String, dynamic> item) =>
          (item['image_url'] as String).isNotEmpty;

      final posts = postItems.map(toItem).where(hasImage).toList();
      final feeds = feedItems.map(toItem).where(hasImage).toList();
      final stories = storiesRaw.map(toItem).where(hasImage).toList();

      // 4. analyzeUser 호출 (게시글 + 피드 + 스토리)
      final repo = ref.read(analysisRepositoryDIProvider);
      final result = await repo.analyzeUser(
        posts: posts,
        feeds: feeds,
        stories: stories,
        userId: userId,
      );

      final styleProfile = result['styleProfile'] as Map<String, dynamic>?;
      final summary = result['summary'] as String?;
      final recommendations = result['recommendations'] as List<dynamic>?;

      if (styleProfile == null) {
        state = state.copyWith(
          status: StyleAnalysisStatus.error,
          errorMessage: '스타일 프로필 분석 결과가 없습니다',
        );
        return;
      }

      // 5. Firebase RTDB에 저장
      state = state.copyWith(status: StyleAnalysisStatus.savingProfile);
      developer.log('Saving to Firebase...', name: 'StyleAnalysis');

      final styleRepo = ref.read(styleRepositoryProvider);
      await styleRepo.saveStyleProfile(
        userId: userId,
        styleProfile: styleProfile,
        summary: summary,
        recommendations: recommendations,
      );

      // 6. 인메모리 캐시 업데이트
      ref.read(userStyleProfileProvider.notifier).state = styleProfile;

      state = state.copyWith(status: StyleAnalysisStatus.completed);
      developer.log('Style analysis completed', name: 'StyleAnalysis');
    } catch (e) {
      developer.log('Style analysis failed: $e', name: 'StyleAnalysis');
      final msg = e is ApiException ? e.userMessage : '분석 중 오류가 발생했습니다. 다시 시도해 주세요';
      state = state.copyWith(
        status: StyleAnalysisStatus.error,
        errorMessage: msg,
      );
    }
  }

  /// 상태 초기화.
  void reset() {
    state = const StyleAnalysisState();
  }
}

final styleAnalysisPipelineProvider =
    NotifierProvider<StyleAnalysisNotifier, StyleAnalysisState>(() {
  return StyleAnalysisNotifier();
});
