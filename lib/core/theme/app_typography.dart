import 'package:flutter/material.dart';

/// 인스타그램 기준으로 맞춘 타이포 스케일.
///
/// 인스타그램은 본문을 14px로 고정하고 줄 간격을 1.35~1.45로 좁게 가져간다.
/// 큰 글자일수록 자간을 음수로 조여 제목이 뭉쳐 보이게 하고,
/// 강조는 크기가 아니라 굵기(w600/w700)로 준다.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  // ── 의미 기반 스타일 ──
  //
  // 색은 넣지 않는다 — 쓰는 쪽에서 copyWith(color: ...)로 지정한다.

  /// 앱 워드마크('감도'). 스플래시·홈·설정에서 같은 모양을 쓴다.
  static const TextStyle wordmark = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
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
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.35,
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
      // 히어로 타이틀 — 자간을 조여 인스타그램 헤드라인처럼 뭉치게 한다
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textColor,
        height: 1.25,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
        height: 1.25,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textColor,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textColor,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textColor,
        height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textColor,
        height: 1.35,
      ),
      // 제목 — 인스타그램은 크기 대신 굵기로 위계를 만든다
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
      // 본문 — 14px, 줄 간격 1.4가 인스타그램 캡션의 기본값
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
