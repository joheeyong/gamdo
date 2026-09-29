/// 서버 분석 작업(job)의 단계. 계약: queued → analyzing → rendering → done.
enum AnalysisJobStage {
  queued,
  analyzing,
  rendering,
  done;

  /// 서버의 stage(없으면 status) 문자열을 단계로 바꾼다. 모르는 값은 null.
  static AnalysisJobStage? tryParse(Object? stage, {Object? status}) {
    switch (stage) {
      case 'queued':
        return AnalysisJobStage.queued;
      case 'analyzing':
        return AnalysisJobStage.analyzing;
      case 'rendering':
        return AnalysisJobStage.rendering;
      case 'done':
        return AnalysisJobStage.done;
    }
    switch (status) {
      case 'queued':
        return AnalysisJobStage.queued;
      case 'running':
        return AnalysisJobStage.analyzing;
      case 'done':
        return AnalysisJobStage.done;
    }
    return null;
  }

  /// 대기 화면에 보여 줄 문구.
  String get message => switch (this) {
        AnalysisJobStage.queued => '대기 중이에요',
        AnalysisJobStage.analyzing => 'AI가 사진을 분석하고 있어요',
        AnalysisJobStage.rendering => '보정을 적용하고 있어요',
        AnalysisJobStage.done => '거의 다 됐어요',
      };
}

/// 분석 진행 상황 — 대기 화면 문구용.
class AnalysisJobProgress {
  final AnalysisJobStage stage;

  /// 서버가 알려 준 작업 경과 시간.
  final Duration elapsed;

  /// 서버 작업(job)으로 돌고 있는지. true면 앱이 백그라운드에 다녀와도
  /// 결과를 다시 받아 올 수 있다. 구버전 서버(동기 폴백)면 false.
  final bool resumable;

  const AnalysisJobProgress({
    required this.stage,
    this.elapsed = Duration.zero,
    this.resumable = true,
  });

  @override
  bool operator ==(Object other) =>
      other is AnalysisJobProgress &&
      other.stage == stage &&
      other.elapsed == elapsed &&
      other.resumable == resumable;

  @override
  int get hashCode => Object.hash(stage, elapsed, resumable);

  @override
  String toString() =>
      'AnalysisJobProgress($stage, ${elapsed.inMilliseconds}ms, resumable: $resumable)';
}
