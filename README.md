# 감도 (GAMDO)

**사진 감각 코칭 앱** - AI 기반 사진 분석 및 개인화 가이드

1인 브랜딩 시대에 사진의 톤앤매너가 중요해졌으나 체계적으로 배울 기회가 부족합니다. 감도(GAMDO)는 사진을 업로드하면 색감·구도·분위기를 AI(Claude Vision)로 분석하고 개인화된 촬영/보정 가이드를 제공합니다.

## 주요 기능

- **색감 분석** - 대표 색상 팔레트, 색온도, 채도/밝기 시각화
- **구도 분석** - 삼분법 그리드 오버레이, 균형 점수, 장점/개선점
- **톤 리포트** - 전체 분위기, 스타일 카테고리, 상세 평가
- **촬영/보정 팁** - AI 기반 개인화 코칭 가이드
- **분석 히스토리** - 스타일별 필터링, 스와이프 삭제
- **다크 모드** - 라이트/다크 테마 지원
- **다국어** - 한국어/영어 지원

## 기술 스택

| 항목 | 선택 |
|------|------|
| Framework | Flutter 3.41.6 / Dart 3.11.4 |
| 상태관리 | Riverpod 3.x + code generation |
| 라우팅 | GoRouter 14.x |
| 로컬 DB | Drift (SQLite) |
| HTTP | Dio 5.x |
| 모델 | Freezed + json_serializable |
| 이미지 | image_picker + flutter_image_compress |
| 차트 | fl_chart |
| 폰트 | Pretendard |

## 아키텍처

```
[Flutter App] --HTTPS--> [Cloudflare Worker 프록시] --HTTPS--> [Anthropic API]
```

API 키를 앱에 직접 포함하지 않고, Cloudflare Worker를 프록시 서버로 사용하여 서버 사이드에서 API 키를 주입합니다.

## 프로젝트 구조

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/          # API URL, 분석 프롬프트
│   ├── theme/              # AppTheme, AppColors, AppTypography
│   ├── network/            # Dio 클라이언트, 인터셉터
│   ├── services/           # ImageService, StorageService, Database
│   ├── router/             # GoRouter 설정
│   ├── widgets/            # 공통 위젯
│   ├── extensions/         # Context, Color 확장
│   └── providers/          # 테마 프로바이더
├── features/
│   ├── onboarding/         # 스플래시, 온보딩
│   ├── home/               # 홈 화면
│   ├── photo_upload/       # 사진 업로드
│   ├── analysis/           # 핵심: AI 분석 기능
│   ├── history/            # 분석 히스토리
│   └── settings/           # 설정
└── l10n/                   # 한국어/영어 지역화
```

## 시작하기

### 사전 요구사항

- Flutter 3.x 이상
- Dart 3.x 이상
- Xcode (iOS) / Android Studio (Android)

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Freezed, Drift, Riverpod)
dart run build_runner build

# 실행
flutter run
```

### Cloudflare Worker 프록시 배포

```bash
cd cloudflare-worker

# 배포
wrangler deploy

# 시크릿 설정
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put APP_TOKEN
```

### 앱 설정

1. 앱 실행 후 **설정** 탭 이동
2. **프록시 서버 URL** 입력 (배포된 Cloudflare Worker URL)
3. **앱 토큰** 입력 (Worker에 설정한 APP_TOKEN 값)

## 화면 구성

| 화면 | 설명 |
|------|------|
| Splash | 앱 로고, 온보딩 여부 체크 |
| Onboarding | 앱 소개 3페이지 |
| Home | 최근 분석 목록, 분석하기 버튼 |
| Photo Upload | 갤러리/카메라 선택, 미리보기 |
| Analysis Result | 색감/구도/톤 분석 결과, 촬영/보정 팁 |
| History | 분석 기록, 스타일 필터링 |
| Settings | 다크모드, API 설정 |

## 이미지 파이프라인

1. `image_picker`로 이미지 선택 (최대 1568px)
2. `flutter_image_compress`로 JPEG 85% 품질 압축
3. 5MB 초과 시 800px / 60% 품질로 재압축
4. Base64 인코딩 → 프록시 서버 → Claude Vision API

## 라이선스

이 프로젝트는 비공개입니다.
