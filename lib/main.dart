import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

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
