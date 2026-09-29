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

/// 설정의 '얼굴/체형 보정' 토글 (기본 꺼짐).
///
/// keepAlive — autoDispose였을 때는 설정 화면이 떠 있지 않으면 분석 경로가
/// 로딩 상태를 읽어 `?? false`로 떨어졌다. 켜 둔 사용자도 항상 꺼짐으로 전송됐다.

@ProviderFor(ReshapeEnabledSetting)
final reshapeEnabledSettingProvider = ReshapeEnabledSettingProvider._();

/// 설정의 '얼굴/체형 보정' 토글 (기본 꺼짐).
///
/// keepAlive — autoDispose였을 때는 설정 화면이 떠 있지 않으면 분석 경로가
/// 로딩 상태를 읽어 `?? false`로 떨어졌다. 켜 둔 사용자도 항상 꺼짐으로 전송됐다.
final class ReshapeEnabledSettingProvider
    extends $AsyncNotifierProvider<ReshapeEnabledSetting, bool> {
  /// 설정의 '얼굴/체형 보정' 토글 (기본 꺼짐).
  ///
  /// keepAlive — autoDispose였을 때는 설정 화면이 떠 있지 않으면 분석 경로가
  /// 로딩 상태를 읽어 `?? false`로 떨어졌다. 켜 둔 사용자도 항상 꺼짐으로 전송됐다.
  ReshapeEnabledSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reshapeEnabledSettingProvider',
        isAutoDispose: false,
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
    r'243e425dd3698ca3d018a375e6031e3ec24ff8b9';

/// 설정의 '얼굴/체형 보정' 토글 (기본 꺼짐).
///
/// keepAlive — autoDispose였을 때는 설정 화면이 떠 있지 않으면 분석 경로가
/// 로딩 상태를 읽어 `?? false`로 떨어졌다. 켜 둔 사용자도 항상 꺼짐으로 전송됐다.

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

/// 설정의 '피부 보정' 토글 (기본 켜짐).
///
/// keepAlive — 분석·저장 경로가 `.future`로 읽는다. autoDispose면 설정 화면이
/// 떠 있지 않을 때 매번 새로 읽혀 로딩 상태를 보게 되고, 기본값(켜짐)으로
/// 잘못 보낼 수 있다.

@ProviderFor(SkinRetouchEnabledSetting)
final skinRetouchEnabledSettingProvider = SkinRetouchEnabledSettingProvider._();

/// 설정의 '피부 보정' 토글 (기본 켜짐).
///
/// keepAlive — 분석·저장 경로가 `.future`로 읽는다. autoDispose면 설정 화면이
/// 떠 있지 않을 때 매번 새로 읽혀 로딩 상태를 보게 되고, 기본값(켜짐)으로
/// 잘못 보낼 수 있다.
final class SkinRetouchEnabledSettingProvider
    extends $AsyncNotifierProvider<SkinRetouchEnabledSetting, bool> {
  /// 설정의 '피부 보정' 토글 (기본 켜짐).
  ///
  /// keepAlive — 분석·저장 경로가 `.future`로 읽는다. autoDispose면 설정 화면이
  /// 떠 있지 않을 때 매번 새로 읽혀 로딩 상태를 보게 되고, 기본값(켜짐)으로
  /// 잘못 보낼 수 있다.
  SkinRetouchEnabledSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skinRetouchEnabledSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skinRetouchEnabledSettingHash();

  @$internal
  @override
  SkinRetouchEnabledSetting create() => SkinRetouchEnabledSetting();
}

String _$skinRetouchEnabledSettingHash() =>
    r'fda296e2ec51e8a1956371b07de10309c46f327f';

/// 설정의 '피부 보정' 토글 (기본 켜짐).
///
/// keepAlive — 분석·저장 경로가 `.future`로 읽는다. autoDispose면 설정 화면이
/// 떠 있지 않을 때 매번 새로 읽혀 로딩 상태를 보게 되고, 기본값(켜짐)으로
/// 잘못 보낼 수 있다.

abstract class _$SkinRetouchEnabledSetting extends $AsyncNotifier<bool> {
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
