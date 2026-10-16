// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get next => '다음';

  @override
  String get skip => '건너뛰기';

  @override
  String get home => '홈';

  @override
  String get history => '기록';

  @override
  String get settings => '설정';

  @override
  String get noAnalysisYet => '아직 분석한 사진이 없습니다';

  @override
  String get analyzing => '분석 중...';

  @override
  String get colorAnalysis => '색감 분석';

  @override
  String get dominantColors => '대표 색상';

  @override
  String get colorTemperature => '색온도';

  @override
  String get saturation => '채도';

  @override
  String get brightness => '밝기';

  @override
  String get colorHarmony => '색상 조화';

  @override
  String get compositionAnalysis => '구도 분석';

  @override
  String get balance => '균형';

  @override
  String get toneReport => '톤 리포트';

  @override
  String get overallMood => '전체 분위기';

  @override
  String get styleCategory => '스타일 카테고리';

  @override
  String get darkMode => '다크 모드';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get error => '오류';

  @override
  String get errorAnalysisFailed => '분석에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get allStyles => '전체';

  @override
  String get deleteAnalysis => '분석 삭제';

  @override
  String get deleteConfirm => '이 분석을 삭제하시겠습니까?';

  @override
  String get delete => '삭제';
}
