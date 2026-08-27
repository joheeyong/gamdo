// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '감도';

  @override
  String get onboardingTitle1 => '사진의 감각을 읽다';

  @override
  String get onboardingDesc1 =>
      'AI가 사진의 색감, 구도, 분위기를 분석하여\n당신만의 사진 감각을 발견해 드립니다.';

  @override
  String get onboardingTitle2 => '맞춤 코칭 가이드';

  @override
  String get onboardingDesc2 => '촬영 팁과 보정 가이드로\n사진 실력을 한 단계 업그레이드하세요.';

  @override
  String get onboardingTitle3 => '나만의 스타일 기록';

  @override
  String get onboardingDesc3 => '분석 히스토리를 통해\n사진 스타일의 변화를 추적하세요.';

  @override
  String get getStarted => '시작하기';

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
  String get analyze => '분석하기';

  @override
  String get recentAnalysis => '최근 분석';

  @override
  String get noAnalysisYet => '아직 분석한 사진이 없습니다';

  @override
  String get startFirstAnalysis => '첫 번째 사진을 분석해 보세요!';

  @override
  String get selectPhoto => '사진 선택';

  @override
  String get fromGallery => '갤러리에서 선택';

  @override
  String get fromCamera => '카메라로 촬영';

  @override
  String get startAnalysis => '분석 시작';

  @override
  String get analyzing => '분석 중...';

  @override
  String get analyzingDesc => 'AI가 사진을 분석하고 있습니다';

  @override
  String get analysisComplete => '분석 완료';

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
  String get compositionTechnique => '구도 기법';

  @override
  String get balance => '균형';

  @override
  String get strengths => '장점';

  @override
  String get improvements => '개선점';

  @override
  String get toneReport => '톤 리포트';

  @override
  String get overallMood => '전체 분위기';

  @override
  String get styleCategory => '스타일 카테고리';

  @override
  String get shootingTips => '촬영 팁';

  @override
  String get editingTips => '보정 팁';

  @override
  String get overallScore => '종합 점수';

  @override
  String get warm => '따뜻한';

  @override
  String get cool => '차가운';

  @override
  String get neutral => '중성';

  @override
  String get darkMode => '다크 모드';

  @override
  String get apiSettings => 'API 설정';

  @override
  String get proxyUrl => '프록시 서버 URL';

  @override
  String get appToken => '앱 토큰';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get error => '오류';

  @override
  String get retry => '다시 시도';

  @override
  String get errorAnalysisFailed => '분석에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get errorNetworkFailed => '네트워크 연결을 확인해 주세요.';

  @override
  String get errorImageTooLarge => '이미지 크기가 너무 큽니다.';

  @override
  String get allStyles => '전체';

  @override
  String get filterByStyle => '스타일 필터';

  @override
  String get deleteAnalysis => '분석 삭제';

  @override
  String get deleteConfirm => '이 분석을 삭제하시겠습니까?';

  @override
  String get delete => '삭제';

  @override
  String points(int score) {
    return '$score점';
  }
}
