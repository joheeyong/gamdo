import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
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

    FlutterError.onError = (details) {
      developer.log(
        'FlutterError: ${details.exceptionAsString()}',
        name: 'GAMDO',
        error: details.exception,
        stackTrace: details.stack,
      );
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
