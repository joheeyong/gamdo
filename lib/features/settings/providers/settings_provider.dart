import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/storage_service.dart';

part 'settings_provider.g.dart';

@riverpod
class ProxyUrlSetting extends _$ProxyUrlSetting {
  @override
  FutureOr<String> build() async {
    final storage = ref.read(storageServiceProvider);
    return await storage.getProxyUrl() ?? '';
  }

  Future<void> save(String url) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setProxyUrl(url);
    state = AsyncData(url);
  }
}

@riverpod
class AppTokenSetting extends _$AppTokenSetting {
  @override
  FutureOr<String> build() async {
    final storage = ref.read(storageServiceProvider);
    return await storage.getAppToken() ?? '';
  }

  Future<void> save(String token) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setAppToken(token);
    state = AsyncData(token);
  }
}
