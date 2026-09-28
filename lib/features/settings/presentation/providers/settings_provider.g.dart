// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProxyUrlSetting)
final proxyUrlSettingProvider = ProxyUrlSettingProvider._();

final class ProxyUrlSettingProvider
    extends $AsyncNotifierProvider<ProxyUrlSetting, String> {
  ProxyUrlSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proxyUrlSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proxyUrlSettingHash();

  @$internal
  @override
  ProxyUrlSetting create() => ProxyUrlSetting();
}

String _$proxyUrlSettingHash() => r'a91ebe9139b39da98093f7be296144d2fa7ff890';

abstract class _$ProxyUrlSetting extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AppTokenSetting)
final appTokenSettingProvider = AppTokenSettingProvider._();

final class AppTokenSettingProvider
    extends $AsyncNotifierProvider<AppTokenSetting, String> {
  AppTokenSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appTokenSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appTokenSettingHash();

  @$internal
  @override
  AppTokenSetting create() => AppTokenSetting();
}

String _$appTokenSettingHash() => r'00961f808178a4d1fb4c0f8ba9b05f72e36e4eca';

abstract class _$AppTokenSetting extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ReshapeEnabledSetting)
final reshapeEnabledSettingProvider = ReshapeEnabledSettingProvider._();

final class ReshapeEnabledSettingProvider
    extends $AsyncNotifierProvider<ReshapeEnabledSetting, bool> {
  ReshapeEnabledSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reshapeEnabledSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reshapeEnabledSettingHash();

  @$internal
  @override
  ReshapeEnabledSetting create() => ReshapeEnabledSetting();
}

String _$reshapeEnabledSettingHash() =>
    r'9deff7defb7796dbf229e18d9368e36be911e9e6';

abstract class _$ReshapeEnabledSetting extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
