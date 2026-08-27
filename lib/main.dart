import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
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

    runApp(
      ProviderScope(
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
