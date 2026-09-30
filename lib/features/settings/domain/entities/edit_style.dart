/// 보정 스타일(= 서버 style_profile.trendCategory) 목록과 요청용 프로필 조립.
///
/// 서버와의 계약:
/// - 'auto'(내 피드 기준)면 인스타 분석 프로필을 그대로 보낸다.
///   프로필이 없으면 trendCategory 없이 → 서버 기본 레시피.
/// - 스타일을 직접 골랐으면 프로필 복사본(없으면 빈 맵)의 trendCategory를
///   선택값으로 바꾸고 styleSource: "manual"을 붙인다.
library;

/// '자동(내 피드 기준)' 선택값.
const String kEditStyleAuto = 'auto';

/// 자동 선택의 표시 이름·설명.
const String kEditStyleAutoName = '자동(내 피드 기준)';
const String kEditStyleAutoDescription = '인스타그램 피드를 분석한 내 스타일로 보정';

class EditStyle {
  /// 서버 trendCategory 값.
  final String id;
  final String name;
  final String description;

  /// 룩을 떠올리게 하는 색 띠 (ARGB, 왼쪽→오른쪽).
  final List<int> swatch;

  /// 필름 그레인이 핵심인 룩 — 미리보기에 점 무늬를 얹는다.
  final bool grain;

  const EditStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.swatch,
    this.grain = false,
  });
}

/// 앱에서 고를 수 있는 9가지 보정 스타일 (계약 순서).
const List<EditStyle> kEditStyles = [
  EditStyle(
    id: 'warm_film',
    name: '웜 필름',
    description: '필름 그레인·웜톤·바랜 검정',
    swatch: [0xFF4A3B31, 0xFFA7774E, 0xFFDDB98A, 0xFFF1E2C6],
    grain: true,
  ),
  EditStyle(
    id: 'korean_gamsung',
    name: '한국 감성',
    description: '소프트·뮤트·띄운 검정·낮은 대비',
    swatch: [0xFF7A746E, 0xFFB5ADA3, 0xFFD9D2C7, 0xFFF0EBE3],
  ),
  EditStyle(
    id: 'cinematic_moody',
    name: '시네마틱',
    description: '틸-오렌지·깊은 그림자·비네팅',
    swatch: [0xFF0C1F27, 0xFF1E5360, 0xFFC0703B, 0xFF24160F],
  ),
  EditStyle(
    id: 'golden_hour',
    name: '골든아워',
    description: '강한 웜톤·골든 글로우',
    swatch: [0xFF7A3B12, 0xFFDD8629, 0xFFF5C257, 0xFFFFE6A6],
  ),
  EditStyle(
    id: 'clean_minimal',
    name: '클린',
    description: '최소 보정·정확한 화이트밸런스',
    swatch: [0xFF2B2D30, 0xFF9AA0A6, 0xFFE3E6E9, 0xFFFFFFFF],
  ),
  EditStyle(
    id: 'bright_airy',
    name: '밝은 감성',
    description: '밝고 환한 톤',
    swatch: [0xFFC7DDE8, 0xFFEAF3F7, 0xFFFFFFFF, 0xFFF6EDE5],
  ),
  EditStyle(
    id: 'flash_digicam',
    name: '플래시·디카',
    description: '정면 플래시 스냅·Y2K 디지털카메라',
    swatch: [0xFF0A0A12, 0xFF2C3866, 0xFFF3F1FF, 0xFFE0B9A5],
  ),
  EditStyle(
    id: 'soft_pastel',
    name: '소프트 파스텔',
    description: '핑크·파스텔 톤, 부드러운 빛',
    swatch: [0xFFF5C3D6, 0xFFFBE2EB, 0xFFE2D8F6, 0xFFCDE7F1],
  ),
  EditStyle(
    id: 'bw_grain',
    name: '흑백 그레인',
    description: '흑백 + 필름 그레인',
    swatch: [0xFF111111, 0xFF505050, 0xFFA6A6A6, 0xFFEEEEEE],
    grain: true,
  ),
];

/// [id]에 해당하는 스타일. 'auto'·모르는 값이면 null.
EditStyle? editStyleById(String? id) {
  for (final s in kEditStyles) {
    if (s.id == id) return s;
  }
  return null;
}

/// 저장값을 정리한다 — 모르는 값(옛 버전·손상)은 'auto'로.
String normalizeEditStyle(String? value) =>
    editStyleById(value) != null ? value! : kEditStyleAuto;

/// 선택값의 표시 이름.
String editStyleName(String choice) =>
    editStyleById(choice)?.name ?? kEditStyleAutoName;

/// 분석 요청에 실을 style_profile을 만든다 (계약 그대로).
///
/// - [choice]가 'auto'(또는 모르는 값)면 [profile]을 그대로 돌려준다 (null 가능).
/// - 스타일을 골랐으면 [profile] 복사본(없으면 빈 맵)에 trendCategory를
///   선택값으로, styleSource를 "manual"로 넣는다. [profile]은 건드리지 않는다.
Map<String, dynamic>? buildRequestStyleProfile(
  Map<String, dynamic>? profile,
  String choice,
) {
  final style = editStyleById(choice);
  if (style == null) return profile;
  return {
    ...?profile,
    'trendCategory': style.id,
    'styleSource': 'manual',
  };
}

/// '보정 스타일을 골라 주세요' 안내를 띄울지.
///
/// 인스타 분석 프로필이 없고(게시글 0개·분석 실패·건너뜀), 사용자가 아직
/// 자동에 머물러 있고, 한 번도 안내하지 않았을 때만. 스타일 분석이 진행 중이면
/// 곧 프로필이 생길 수 있으니 기다린다.
bool shouldPromptEditStyle({
  required Map<String, dynamic>? profile,
  required String choice,
  required bool alreadyPrompted,
  bool styleAnalysisInProgress = false,
}) {
  if (alreadyPrompted) return false;
  if (styleAnalysisInProgress) return false;
  if (profile != null) return false;
  return normalizeEditStyle(choice) == kEditStyleAuto;
}
