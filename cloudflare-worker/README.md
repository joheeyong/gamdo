# GAMDO Agent 서버 (Cloudflare Worker)

Flutter 클라이언트와 외부 API 사이의 프록시 서버. API 키를 클라이언트에 노출하지 않고 서버 사이드에서 주입합니다.

## 아키텍처

```
[Flutter App] ──POST──▶ [Cloudflare Worker] ──POST──▶ [Anthropic API]
              Bearer APP_TOKEN            x-api-key: ANTHROPIC_API_KEY
```

## 엔드포인트

| Method | Path | 설명 |
|--------|------|------|
| `POST` | `/api/analyze` | 사진 분석 요청을 Anthropic Messages API로 프록시 |
| `OPTIONS` | `*` | CORS preflight 처리 |

### `POST /api/analyze`

클라이언트의 요청 body를 그대로 Anthropic Messages API(`v1/messages`)에 전달하고 응답을 반환합니다.

**인증**: `Authorization: Bearer <APP_TOKEN>` 헤더 필수.

**Request**: Anthropic Messages API 형식 그대로 (model, messages, max_tokens 등)

**Response**: Anthropic API 응답 그대로 전달 (status code 포함)

## 환경 변수 (Secrets)

| 변수 | 설명 |
|------|------|
| `ANTHROPIC_API_KEY` | Anthropic API 키 |
| `APP_TOKEN` | 클라이언트 인증용 토큰 (Bearer) |

## 배포

```bash
# Cloudflare 로그인
wrangler login

# 시크릿 설정
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put APP_TOKEN

# 배포
wrangler deploy
```

배포 후 Worker URL을 Flutter 앱의 프록시 서버 URL로 설정합니다.

## 설정

`wrangler.toml`:

```toml
name = "gamdo-proxy"
main = "worker.js"
compatibility_date = "2024-01-01"
```

## CORS

모든 origin 허용 (`*`). POST와 OPTIONS만 허용하며, 그 외 메서드는 405를 반환합니다.

## 에러 처리

| Status | 설명 |
|--------|------|
| 401 | APP_TOKEN 불일치 또는 누락 |
| 404 | `/api/analyze` 외 경로 접근 |
| 405 | POST 외 메서드 |
| 500 | Anthropic API 호출 중 예외 |
