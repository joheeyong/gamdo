import 'package:flutter/material.dart';

/// 감도 '필름 노트' 팔레트 — 종이와 앰버.
///
/// 라이트는 인화지 같은 따뜻한 종이색, 다크는 암실처럼 따뜻한 먹색이다.
/// 사진 색을 방해하지 않도록 무채색에 가까운 바탕을 쓰고, 강조는 앰버 하나로 한다.
///
/// 상수는 라이트·다크 모두에서 쓰인다. 그래서 글자·아이콘으로 쓰이는 강조색은
/// 종이(#F3EEE4)와 먹색(#16130F) 양쪽에서 3:1 이상이 되는 값으로 골랐다.
class AppColors {
  AppColors._();

  // ── 브랜드 ──

  /// 기본 강조(번트 앰버). 글자·아이콘·채움에 모두 쓰고, 채움 위 글자는 흰색.
  static const Color primary = Color(0xFFA8641A);
  static const Color primaryLight = Color(0xFFE8A33D);
  static const Color primaryDark = Color(0xFF7E4A12);

  /// 보조 강조(필름 그린). 스타일 키워드·차트 등 두 번째 색이 필요한 곳.
  static const Color accent = Color(0xFF5E7A55);
  static const Color accentLight = Color(0xFF8FA585);

  /// 밝은 앰버 하이라이트. 채움 전용 — 위에는 반드시 [ink] 글자를 올린다.
  static const Color highlight = Color(0xFFE8A33D);

  /// 먹색. 하이라이트 위 글자, 라이트 모드의 주 버튼 채움.
  static const Color ink = Color(0xFF1E1B17);

  /// 텍스트 버튼·확인 동작 색.
  static const Color action = primary;

  // ── 무채색 — 라이트 (종이) ──
  static const Color backgroundLight = Color(0xFFF3EEE4);
  static const Color surfaceLight = Color(0xFFFBF8F2);
  static const Color textPrimaryLight = Color(0xFF1E1B17);
  static const Color textSecondaryLight = Color(0xFF6B6358);
  static const Color dividerLight = Color(0xFFDDD4C5);

  // ── 무채색 — 다크 (암실) ──
  static const Color backgroundDark = Color(0xFF16130F);
  static const Color surfaceDark = Color(0xFF211D18);
  static const Color textPrimaryDark = Color(0xFFEFE8DC);
  static const Color textSecondaryDark = Color(0xFFA39A8C);
  static const Color dividerDark = Color(0xFF3A342C);

  /// 토스트 등 떠 있는 어두운 표면.
  static const Color floatingDark = Color(0xFF2B2620);

  /// 보조 버튼 채움.
  static const Color secondaryFillLight = Color(0xFFE9E2D5);
  static const Color secondaryFillDark = Color(0xFF2E2923);

  // ── 의미 ──
  static const Color success = Color(0xFF4F8A3A);
  static const Color warning = Color(0xFFB86E1E);
  static const Color error = Color(0xFFC2452D);
  static const Color info = Color(0xFF4F7896);

  // ── 점수 ──
  static const Color scoreExcellent = success;
  static const Color scoreGood = primary;
  static const Color scoreAverage = warning;
  static const Color scoreLow = error;

  // ── 색온도 ──
  static const Color warmColor = Color(0xFFB86E1E);
  static const Color coolColor = Color(0xFF4F7896);
  static const Color neutralColor = Color(0xFF8C8478);

  // ── 그라디언트 ──
  //
  // 넓은 면을 칠하는 그라디언트는 쓰지 않는다. 워드마크·선택 표시처럼 작은 곳에
  // 같은 계열 앰버 두 톤만 쓴다 (인화지 위 빛 번짐 정도의 차이).

  /// 앰버 두 톤. 강조 글자·아이콘·주 버튼에 쓴다.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFA8641A), Color(0xFF8E5312)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  /// 프로필 링 등 테두리용. 밝은 앰버에서 번트 앰버로.
  static const LinearGradient ringGradient = LinearGradient(
    colors: [Color(0xFFE8A33D), Color(0xFFA8641A)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}
