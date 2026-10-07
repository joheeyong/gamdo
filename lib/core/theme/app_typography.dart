import 'package:flutter/material.dart';

/// 감도 '필름 노트' 타이포 스케일.
///
/// 제목·워드마크는 명조(Noto Serif KR)로 인화지 노트 같은 결을 내고,
/// 본문·버튼·수치는 고딕(Pretendard)으로 읽기 쉽게 둔다.
/// 명조는 앱 용량을 줄이려 KS X 1001 한글 2,350자만 담은 서브셋이다.
/// 그 밖의 글자는 [serifFallback]의 고딕으로 그려진다.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  /// 제목용 명조. 굵기는 w600·w700만 들어 있다.
  static const String serifFamily = 'NotoSerifKR';
  static const List<String> serifFallback = [fontFamily];

  // ── 의미 기반 스타일 ──
  //
  // 색은 넣지 않는다 — 쓰는 쪽에서 copyWith(color: ...)로 지정한다.

  /// 앱 워드마크('감도'). 스플래시·홈·설정에서 같은 모양을 쓴다.
  static const TextStyle wordmark = TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// 사용자명·스타일명 등 카드의 주 라벨.
  static const TextStyle username = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// 게시물 본문 캡션.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 보조 설명(회색으로 쓰는 것을 전제).
  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 날짜·수치 등 최소 크기 메타 정보.
  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// 화면 안 섹션 제목.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: serifFamily,
    fontFamilyFallback: serifFallback,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  /// 앱바 제목(모달·편집 플로우의 가운데 정렬 제목).
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// 버튼 라벨.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 배지·칩 라벨.
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 입력 필드의 본문 글자.
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── Material TextTheme ──

  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      // 히어로·헤드라인 — 명조. 줄 간격을 넉넉히 둬 노트에 쓴 제목처럼 보이게 한다
      displayLarge: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: serifFallback,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textColor,
        height: 1.4,
      ),
      displayMedium: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: serifFallback,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
        height: 1.4,
      ),
      displaySmall: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: serifFallback,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textColor,
        height: 1.4,
      ),
      headlineLarge: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: serifFallback,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textColor,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: serifFallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textColor,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: serifFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textColor,
        height: 1.4,
      ),
      // 제목 — 고딕. 크기 대신 굵기로 위계를 만든다
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      // 본문 — 14px, 줄 간격 1.4
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.2,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.2,
      ),
    );
  }
}
