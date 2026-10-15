import 'package:flutter/material.dart';

/// 감도 '벤토' 팔레트 — 차가운 회백색과 하늘색.
///
/// 회백색 바탕 위에 흰 카드를 도시락처럼 짜 맞추고, 강조는 하늘색 하나로 한다.
/// 다크는 푸른 먹색 바탕에 짙은 회색 카드, 같은 하늘색을 쓴다.
///
/// 하늘색([highlight])은 밝아서 회백색 위 글자·아이콘으로는 잘 보이지 않는다.
/// 그래서 채움 전용으로만 쓰고 그 위에는 [ink] 글자를 올린다.
/// 글자·아이콘으로 쓰는 강조색은 같은 계열의 짙은 바다색([primary])이다.
/// 상수는 라이트·다크 공용이라, 글자로 쓰이는 색은 회백색(#F1F4F7)과
/// 먹색(#0E1013) 양쪽에서 3:1 이상이 되는 값으로 골랐다.
class AppColors {
  AppColors._();

  // ── 브랜드 ──

  /// 하늘색. 채움 전용 — 점수 카드, 선택된 탭, 켜진 스위치. 위 글자는 [ink].
  static const Color highlight = Color(0xFF7DD3FC);

  /// 하늘색을 조금 눌러 쓴 색 (눌림 상태, 링 그라디언트 끝).
  static const Color highlightDeep = Color(0xFF38BDF8);

  /// 기본 강조(짙은 바다색). 글자·아이콘·진행 표시. 채움 위 글자는 흰색.
  static const Color primary = Color(0xFF0369A1);
  static const Color primaryLight = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF075985);

  /// 보조 강조(차분한 보라). 하늘색과 구분되는 두 번째 계열이 필요한 차트·키워드.
  static const Color accent = Color(0xFF6D5BD0);
  static const Color accentLight = Color(0xFFA99CEB);

  /// 먹색. 하늘색 위 글자, 주 버튼 채움.
  static const Color ink = Color(0xFF111111);

  /// 텍스트 버튼·확인 동작 색.
  static const Color action = primary;

  // ── 무채색 — 라이트 (회백색) ──
  static const Color backgroundLight = Color(0xFFF1F4F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111111);
  static const Color textSecondaryLight = Color(0xFF687078);
  static const Color dividerLight = Color(0xFFE1E6EB);

  // ── 무채색 — 다크 (먹색) ──
  static const Color backgroundDark = Color(0xFF0E1013);
  static const Color surfaceDark = Color(0xFF181B1F);
  static const Color textPrimaryDark = Color(0xFFF1F4F7);
  static const Color textSecondaryDark = Color(0xFF979DA5);
  static const Color dividerDark = Color(0xFF282C31);

  /// 토스트 등 떠 있는 어두운 표면.
  static const Color floatingDark = Color(0xFF1D2024);

  /// 보조 버튼·꺼진 스위치 트랙 채움.
  static const Color secondaryFillLight = Color(0xFFE6EAEE);
  static const Color secondaryFillDark = Color(0xFF24282D);

  // ── 의미 ──
  static const Color success = Color(0xFF3E8E2F);
  static const Color warning = Color(0xFFC27A00);
  static const Color error = Color(0xFFD93F2B);
  static const Color info = Color(0xFF3B6FD8);

  // ── 점수 ──
  static const Color scoreExcellent = success;
  static const Color scoreGood = primary;
  static const Color scoreAverage = warning;
  static const Color scoreLow = error;

  // ── 색온도 ──
  static const Color warmColor = Color(0xFFC27A00);
  static const Color coolColor = Color(0xFF3B6FD8);
  static const Color neutralColor = Color(0xFF8A8F96);

  // ── 그라디언트 ──
  //
  // 벤토는 단색 면으로 구성한다. 아래 두 값은 그라디언트를 받는 기존 위젯
  // (강조 글자·아이콘, 주 버튼, 링)이 단색처럼 보이도록 같은 색 두 톤만 쓴다.

  /// 바다색 단색에 가까운 두 톤. 강조 글자·아이콘·흰 글자 버튼.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF035C8E)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  /// 프로필 링 등 테두리용 하늘색.
  static const LinearGradient ringGradient = LinearGradient(
    colors: [highlight, highlightDeep],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  // ── 인스타그램 브랜드 ──
  //
  // 앱 테마가 아니라 '인스타그램과 연결한다'는 표시다. 인스타그램 연결·로그인
  // 버튼처럼 인스타그램 계정을 다루는 곳에만 쓴다.

  /// 인스타그램 공식 그라디언트 (노랑 → 핑크 → 보라).
  static const LinearGradient instagramGradient = LinearGradient(
    colors: [Color(0xFFFCAF45), Color(0xFFE1306C), Color(0xFF833AB4)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  /// 인스타그램 스토리 링 그라디언트.
  static const LinearGradient instagramRingGradient = LinearGradient(
    colors: [
      Color(0xFFFCAF45),
      Color(0xFFFF6B6B),
      Color(0xFFC13584),
      Color(0xFF833AB4),
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}
