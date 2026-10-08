import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 이벤트를 한곳에서 보낸다.
///
/// 분석은 부가 기능이라 실패해도 앱 동작을 막지 않는다. Firebase가
/// 초기화되지 않은 환경(테스트 등)에서는 아무것도 보내지 않는다.
///
/// 개인정보: Instagram user_id·username·사진 내용은 보내지 않는다.
/// 이벤트 이름과 매개변수는 GA4 규칙(영문 snake_case, 이름 40자 이하)을 따른다.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? get _analytics {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  void _send(Future<void> Function(FirebaseAnalytics a) call) {
    final analytics = _analytics;
    if (analytics == null) return;
    // 이벤트 전송을 기다리지 않는다. 화면 흐름이 분석 때문에 늦어지면 안 된다.
    unawaited(
      call(analytics).catchError((Object e) {
        developer.log('analytics failed: $e', name: 'Analytics');
      }),
    );
  }

  /// 테스트에서 보낸 이벤트를 기록하려고 둔다. 운영 코드에서는 쓰지 않는다.
  @visibleForTesting
  void Function(String name, Map<String, Object>? params)? debugEventSink;

  void _event(String name, [Map<String, Object>? params]) {
    debugEventSink?.call(name, params);
    _send((a) => a.logEvent(name: name, parameters: params));
  }

  /// 화면 이동. [path]는 라우트 경로(`/home` 등)다.
  void screenView(String path) {
    final name = path == '/' ? 'splash' : path.replaceFirst('/', '');
    _send((a) => a.logScreenView(screenName: name, screenClass: name));
  }

  // ── 온보딩·로그인 ──

  void onboardingComplete() => _send((a) => a.logTutorialComplete());

  void loginSuccess() => _send((a) => a.logLogin(loginMethod: 'instagram'));

  void loginSkipped() => _event('login_skipped');

  void loginFailed() => _event('login_failed');

  /// Instagram 피드로 스타일 프로필을 만들었다.
  void styleProfileCreated() => _event('style_profile_created');

  void styleProfileFailed() => _event('style_profile_failed');

  // ── 사진 분석 ──

  /// [style]은 설정의 보정 스타일 ID(자동이면 `auto`).
  void analysisStart({required String style}) =>
      _event('analysis_start', {'style': style});

  void analysisSuccess({required Duration elapsed}) =>
      _event('analysis_success', {'duration_sec': elapsed.inSeconds});

  /// [reason]: `network`, `server`, `no_image`, `unknown`.
  void analysisFail({required String reason, required Duration elapsed}) =>
      _event('analysis_fail', {
        'reason': reason,
        'duration_sec': elapsed.inSeconds,
      });

  // ── 결과 활용 ──

  /// [source]: `single` 또는 `batch`.
  void photoSaved({required String source, int count = 1}) =>
      _event('photo_save', {'source': source, 'count': count});

  /// [target]: `story` 또는 `feed`. [result]: 공유 결과 이름.
  void share({required String target, required String result}) => _event(
    'share',
    {'method': 'instagram_$target', 'content_type': 'image', 'result': result},
  );

  // ── 일괄 변형 ──

  void batchStart({required int count}) =>
      _event('batch_start', {'count': count});

  void batchComplete({required int successCount, required int failCount}) =>
      _event('batch_complete', {
        'success_count': successCount,
        'fail_count': failCount,
      });
}
