import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/app_resume_signal.dart';
import 'features/settings/presentation/providers/theme_provider.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // 분석 작업 폴링이 foreground 복귀 즉시 결과를 조회하도록 신호를 붙인다.
    AppResumeSignal.instance.attach();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 오류 수집(Crashlytics). 개발 중 오류는 보내지 않는다.
    // 개인정보: 사용자 식별자(인스타그램 ID 등)는 붙이지 않는다.
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = (details) {
      developer.log(
        'FlutterError: ${details.exceptionAsString()}',
        name: 'GAMDO',
        error: details.exception,
        stackTrace: details.stack,
      );
      crashlytics.recordFlutterFatalError(details);
    };
    // 프레임워크 밖(비동기·플랫폼 채널)에서 잡히지 않은 오류.
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // 저장된 테마를 첫 프레임 전에 읽어 둔다 (다크 모드 복원, 깜빡임 방지).
    final isDarkMode = await loadSavedDarkMode();

    runApp(
      ProviderScope(
        overrides: [initialDarkModeProvider.overrideWithValue(isDarkMode)],
        observers: [_ProviderLogger()],
        child: const GamdoApp(),
      ),
    );
  }, (error, stack) {
    developer.log('Uncaught error: $error', name: 'GAMDO', error: error, stackTrace: stack);
    // Firebase 초기화 전에 난 오류일 수 있어 확인 후 보낸다.
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

final class _ProviderLogger extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      'Provider ${context.provider} failed: $error',
      name: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
