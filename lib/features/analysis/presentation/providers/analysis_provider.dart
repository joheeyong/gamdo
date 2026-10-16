import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/style_profile_provider.dart';
export '../../../../core/providers/style_profile_provider.dart';
import '../../../../core/services/instagram_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../di/analysis_providers.dart';
import '../../../../core/services/analytics_service.dart';
import 'transform_provider.dart';

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

  const StyleAnalysisState({
    this.status = StyleAnalysisStatus.idle,
    this.errorMessage,
  });

  StyleAnalysisState copyWith({
    StyleAnalysisStatus? status,
    String? errorMessage,
  }) {
    return StyleAnalysisState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  /// 파이프라인이 진행 중인지 (미디어 조회 ~ 프로필 저장).
  bool get isRunning =>
      status == StyleAnalysisStatus.fetchingMedia ||
      status == StyleAnalysisStatus.analyzingStyle ||
      status == StyleAnalysisStatus.savingProfile;

  /// 서버는 받은 게시물 중 사진을 최대 [maxAnalyzedPhotos]장까지만 분석한다
  /// (동영상·스토리 등 전체 개수를 세면 실제보다 많아 보인다).
  static const maxAnalyzedPhotos = 10;

  String get statusMessage => switch (status) {
        StyleAnalysisStatus.idle => '',
        StyleAnalysisStatus.fetchingMedia => '게시글, 피드, 스토리를 가져오는 중...',
        StyleAnalysisStatus.analyzingStyle =>
          '최근 사진을 최대 $maxAnalyzedPhotos장까지 골라 스타일을 분석하는 중...',
        StyleAnalysisStatus.savingProfile => '프로필을 저장하는 중...',
        StyleAnalysisStatus.completed => '스타일 분석이 완료되었습니다!',
        StyleAnalysisStatus.error => errorMessage ?? '분석 중 오류가 발생했습니다',
      };
}

class StyleAnalysisNotifier extends Notifier<StyleAnalysisState> {
  /// 파이프라인 실행 번호. 실행마다 1씩 올라간다.
  /// 완료 배너의 지연 reset이 그 뒤에 시작된 새 실행을 지우지 않도록 쓴다.
  int _runId = 0;
  int get runId => _runId;

  @override
  StyleAnalysisState build() => const StyleAnalysisState();

  /// 지금 파이프라인이 돌고 있는지. 같은 분석이 두 번 겹쳐 돌지 않게 막는다
  /// (로그인 직후 자동 실행 중에 '다시 분석'을 누르는 경우 등).
  bool _inFlight = false;

  /// 연결된 계정으로 스타일 분석을 다시 돌린다 (연결 해제 없이).
  ///
  /// 연결 정보가 없거나 이미 분석 중이면 아무것도 하지 않는다.
  Future<void> reanalyzeConnectedAccount() async {
    final auth = ref.read(instagramAuthProvider);
    final token = auth.accessToken;
    final userId = auth.userId;
    if (!auth.isConnected || token == null || userId == null) return;
    await analyzeInstagramProfile(accessToken: token, userId: userId);
  }

  /// Instagram 프로필 분석 파이프라인.
  ///
  /// 이미 실행 중이면 새로 시작하지 않고 바로 돌아온다.
  Future<void> analyzeInstagramProfile({
    required String accessToken,
    required String userId,
  }) async {
    if (_inFlight) {
      developer.log('Style analysis already running — skip',
          name: 'StyleAnalysis');
      return;
    }
    _inFlight = true;
    _runId++;
    try {
      // 1. 미디어 조회
      state = state.copyWith(status: StyleAnalysisStatus.fetchingMedia);
      developer.log('Fetching media...', name: 'StyleAnalysis');

      final prefs = await SharedPreferences.getInstance();
      final proxyUrl =
          ApiConstants.resolveProxyUrl(prefs.getString('proxy_url'));
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
        AnalyticsService.instance.styleProfileFailed();
        state = state.copyWith(
          status: StyleAnalysisStatus.error,
          errorMessage: '분석할 게시글이 없습니다',
        );
        return;
      }

      state = state.copyWith(status: StyleAnalysisStatus.analyzingStyle);
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
        AnalyticsService.instance.styleProfileFailed();
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

      AnalyticsService.instance.styleProfileCreated();
      state = state.copyWith(status: StyleAnalysisStatus.completed);
      developer.log('Style analysis completed', name: 'StyleAnalysis');

      // 서버가 이번 분석으로 대표 사진을 새로 골랐다. 이미 받아 둔 목록이
      // 있어도 다시 받는다.
      unawaited(ref
          .read(transformProvider.notifier)
          .loadReferenceImages(force: true));
    } catch (e) {
      developer.log('Style analysis failed: $e', name: 'StyleAnalysis');
      final msg = e is ApiException ? e.userMessage : '분석 중 오류가 발생했습니다. 다시 시도해 주세요';
      AnalyticsService.instance.styleProfileFailed();
      state = state.copyWith(
        status: StyleAnalysisStatus.error,
        errorMessage: msg,
      );
    } finally {
      _inFlight = false;
    }
  }

  /// 상태 초기화.
  void reset() {
    state = const StyleAnalysisState();
  }

  /// [runId] 실행이 완료 상태로 남아 있을 때만 초기화한다.
  /// 그 사이 새 분석이 시작됐으면 아무것도 하지 않는다.
  void resetIfCompletedRun(int runId) {
    if (runId == _runId && state.status == StyleAnalysisStatus.completed) {
      reset();
    }
  }
}

final styleAnalysisPipelineProvider =
    NotifierProvider<StyleAnalysisNotifier, StyleAnalysisState>(() {
  return StyleAnalysisNotifier();
});
