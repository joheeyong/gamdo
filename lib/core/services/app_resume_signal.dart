import 'dart:async';

import 'package:flutter/widgets.dart';

/// 앱이 foreground로 돌아올 때마다 이벤트를 흘리는 신호.
///
/// 분석 작업 폴링이 대기 중에 이 신호를 받으면 간격을 기다리지 않고 바로
/// 한 번 조회한다 — 백그라운드에서 끊긴 사이 끝난 결과를 곧장 받기 위함.
/// 위젯에 매이지 않도록 전역 하나를 두고, main에서 [attach]한다.
class AppResumeSignal with WidgetsBindingObserver {
  AppResumeSignal._();

  static final AppResumeSignal instance = AppResumeSignal._();

  final StreamController<void> _controller = StreamController<void>.broadcast();
  bool _attached = false;

  /// foreground 복귀 이벤트 스트림 (broadcast).
  Stream<void> get stream => _controller.stream;

  /// WidgetsBinding에 관찰자로 붙인다. 여러 번 불러도 한 번만 붙는다.
  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.add(null);
  }

  /// 테스트에서 복귀를 흉내 낸다.
  @visibleForTesting
  void emitForTest() => _controller.add(null);
}
