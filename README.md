# 감도 (GAMDO)

**사진 감각 코칭 앱** — AI 기반 사진 분석, 스타일 프로파일링, 사진 변형

1인 브랜딩 시대에 사진의 톤앤매너가 중요해졌으나 체계적으로 배울 기회가 부족합니다. 감도(GAMDO)는 Instagram 계정을 연동해 개인 스타일을 AI로 프로파일링하고, 사진을 업로드하면 색감·구도·분위기 분석 + 자동/수동 보정까지 제공합니다.

## 주요 기능

- **Instagram 연동** — OAuth 로그인, 피드/스토리 분석으로 개인 스타일 프로파일 생성
- **AI 사진 분석** — 색감(팔레트·색온도·채도), 구도(삼분법·균형점수), 톤 리포트
- **사진 변형** — 18+ 슬라이더(밝기, 대비, 색온도, 톤커브, HSL 등) + AI 자동 변형
- **얼굴/체형 보정** — 얼굴 슬림, 턱선, 눈 확대, 다리 늘리기, 어깨/허리 조절
- **일괄 변형** — 다수 사진 선택 후 스타일 일괄 적용, 비교 프리뷰
- **스타일 학습** — 사용자 슬라이더 피드백을 Firebase에 저장, 점진적 개인화
- **촬영/보정 팁** — AI 기반 개인화 코칭 가이드
- **분석 히스토리** — 스타일별 필터링 (9개 카테고리), 점수 표시
- **다크 모드** — 라이트/다크 테마 지원
- **다국어** — 한국어/영어 지원

## 기술 스택

| 항목 | 선택 |
|------|------|
| Framework | Flutter 3.41.6 / Dart 3.11.4 |
| 상태관리 | Riverpod + code generation |
| 라우팅 | GoRouter |
| 로컬 DB | Drift (SQLite) |
| 원격 DB | Firebase Realtime Database |
| HTTP | Dio (인터셉터, CancelToken) |
| 인증 | Instagram OAuth 2.0 (flutter_web_auth_2) |
| 모델 | Freezed + json_serializable |
| 이미지 | image_picker + flutter_image_compress + gal |
| 차트 | fl_chart |
| 폰트 | Pretendard (9 weights) |

## 아키텍처

```
                   ┌─────────────────────┐
                   │   Anthropic API     │
                   │  (Claude Vision)    │
                   └────────▲────────────┘
                            │
[Flutter App] ──HTTPS──▶ [Agent 서버] ──HTTPS──▶ [Instagram Graph API]
                        (프록시)        │
                            │           ▼
                            │    ┌──────────────┐
                            │    │ Firebase RTDB │
                            │    │ (스타일/피드백) │
                            │    └──────────────┘
                            ▼
                  사진 분석 · 변형 · 프로파일링
```

API 키를 앱에 직접 포함하지 않고, Agent 서버를 프록시로 사용하여 서버 사이드에서 API 키를 주입합니다.

## 프로젝트 구조

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/          # API URL, 분석 프롬프트, Instagram 상수
│   ├── theme/              # AppTheme, AppColors (라이트/다크)
│   ├── network/            # Dio 클라이언트, AuthInterceptor
│   ├── services/           # Firebase, Instagram, Image, Database, Storage
│   ├── router/             # GoRouter (ShellRoute + 10개 라우트)
│   ├── providers/          # 테마, 인증 프로바이더
│   └── extensions/         # Context, Color 확장
├── features/
│   ├── auth/               # Instagram OAuth 로그인
│   ├── onboarding/         # 스플래시, 온보딩 (3페이지)
│   ├── home/               # 홈 피드, 프로필 카드, 분석 진행 배너
│   ├── photo_upload/       # 갤러리/카메라 선택, 미리보기
│   ├── analysis/           # AI 분석, 변형(단일/일괄), 결과 시각화
│   ├── history/            # 분석 기록, 스타일 필터링
│   └── settings/           # 다크모드, 얼굴보정 토글, Instagram 계정 관리
├── l10n/                   # 한국어/영어 지역화
└── firebase_options.dart   # Firebase 설정
cloudflare-worker/          # Agent 프록시 서버 (별도 README 참조)
```

## 화면 구성

| 화면 | 경로 | 설명 |
|------|------|------|
| Splash | `/` | 앱 로고, 온보딩/인증 여부 체크 |
| Onboarding | `/onboarding` | 앱 소개 3페이지 |
| Instagram Login | `/instagram-login` | OAuth 로그인 |
| Home | `/home` | 프로필 카드, 최근 분석 목록 |
| History | `/history` | 분석 기록, 스타일 필터 (9개) |
| Settings | `/settings` | 다크모드, 보정 토글, 계정 관리 |
| Photo Upload | `/photo-upload` | 갤러리/카메라, 미리보기 |
| Analysis Result | `/analysis-result` | 색감/구도/톤 분석 + 팁 |
| Transform | `/transform` | 18+ 슬라이더 수동/자동 변형 |
| Batch Transform | `/batch-transform` | 다수 사진 일괄 변형 |

## 이미지 파이프라인

1. `image_picker`로 이미지 선택 (최대 1568px)
2. `flutter_image_compress`로 JPEG 85% 품질 압축
3. 5MB 초과 시 800px / 60% 품질로 재압축
4. 슬라이더 조작 시 800px / 70% 프리뷰 모드 (800ms 디바운스)
5. Base64 인코딩 → Agent 서버 → Claude Vision API

## 시작하기

### 사전 요구사항

- Flutter 3.x 이상 / Dart 3.x 이상
- Xcode (iOS) / Android Studio (Android)
- Firebase 프로젝트 (`gamdo-app-2026`)
- Instagram 앱 (Meta Developer Console)

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Freezed, Drift, Riverpod)
dart run build_runner build

# 실행
flutter run
```

### 앱 설정

1. 앱 실행 → Instagram 계정 로그인
2. 설정 탭에서 프록시 서버 URL 확인 (기본: Agent 서버)
3. Instagram 피드 분석 → 자동 스타일 프로파일 생성

### 테스트 배포 (Firebase App Distribution)

```bash
# Ad Hoc IPA 빌드
flutter build ipa --release --export-method ad-hoc

# Firebase App Distribution에 업로드
firebase appdistribution:distribute build/ios/ipa/gamdo.ipa \
  --app 1:792581850707:ios:7714430c86e615c6f3e8a6 \
  --groups "testers" \
  --release-notes "테스트 빌드"
```

## Firebase 구조

```
gamdo-app-2026-default-rtdb
└── users/
    └── {userId}/
        ├── styleProfile/       # 스타일 프로파일 (primaryStyle, colorPreference 등)
        │   └── targetParams/   # 학습된 변형 파라미터
        └── feedback/
            └── {timestamp}/    # 슬라이더 피드백 델타값
```

## 라이선스

이 프로젝트는 비공개입니다.
