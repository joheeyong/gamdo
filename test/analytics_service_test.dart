import 'package:flutter_test/flutter_test.dart';
import 'package:gamdo/core/services/analytics_service.dart';

void main() {
  test('Firebase가 초기화되지 않아도 이벤트 호출이 예외를 던지지 않는다', () {
    final a = AnalyticsService.instance;
    expect(() {
      a.screenView('/');
      a.screenView('/home');
      a.onboardingComplete();
      a.loginSuccess();
      a.loginSkipped();
      a.loginFailed();
      a.styleProfileCreated();
      a.styleProfileFailed();
      a.analysisStart(style: 'auto');
      a.analysisSuccess(elapsed: const Duration(seconds: 40));
      a.analysisFail(reason: 'network', elapsed: Duration.zero);
      a.photoSaved(source: 'single');
      a.share(target: 'story', result: 'opened');
      a.batchStart(count: 3);
      a.batchComplete(successCount: 2, failCount: 1);
    }, returnsNormally);
  });
}
