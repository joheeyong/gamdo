import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeMode extends _$ThemeMode {
  @override
  FutureOr<bool> build() async {
    final storage = ref.read(storageServiceProvider);
    return storage.isDarkMode();
  }

  Future<void> toggle() async {
    final storage = ref.read(storageServiceProvider);
    final current = state.value ?? false;
    final newValue = !current;
    await storage.setDarkMode(newValue);
    state = AsyncData(newValue);
  }
}
