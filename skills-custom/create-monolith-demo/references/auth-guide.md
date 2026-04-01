# Auth Guide

쿠키 기반 세션 인증을 프로젝트에 추가하는 가이드.
spec에 인증이 포함된 경우에만 적용한다.

## Overview

- httpOnly 쿠키 기반 세션 인증
- HMAC-SHA256 서명 토큰
- 24시간 TTL
- 서버 사이드에서만 검증

## 1. 환경변수 추가

`.env`에 추가:

```
AUTH_SECRET="your-random-secret-key-minimum-32-chars"
AUTH_USERNAME="admin"
AUTH_PASSWORD="your-password"
```

> **프로덕션**: `AUTH_SECRET`은 `openssl rand -base64 32`로 생성한다.

## 2. Prisma User 모델 (선택)

DB 기반 사용자 관리가 필요하면 `User` 모델 추가 (username unique, password bcrypt hashed, role default "user").

## 3. 파일 생성

### 3.1 src/lib/auth.ts

이 파일은 보안 핵심 로직이므로 아래 코드를 그대로 사용한다:

```ts
import { cookies } from "next/headers";
import crypto from "crypto";

if (!process.env.AUTH_SECRET) {
  throw new Error("AUTH_SECRET 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.");
}
const SECRET = process.env.AUTH_SECRET;
const COOKIE_NAME = "app-session";
const TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

function sign(payload: string): string {
  return crypto
    .createHmac("sha256", SECRET)
    .update(payload)
    .digest("hex");
}

export function createSessionToken(): string {
  const payload = btoa(
    JSON.stringify({ authenticated: true, createdAt: Date.now() })
  );
  const signature = sign(payload);
  return `${payload}.${signature}`;
}

export function verifySessionToken(token: string): boolean {
  try {
    const [payload, signature] = token.split(".");
    if (!payload || !signature) return false;
    const expected = sign(payload);
    if (
      expected.length !== signature.length ||
      !crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature))
    ) return false;

    const data = JSON.parse(atob(payload));
    if (!data.authenticated) return false;
    if (Date.now() - data.createdAt > TTL_MS) return false;

    return true;
  } catch {
    return false;
  }
}

export async function isAuthenticated(): Promise<boolean> {
  const cookieStore = await cookies();
  const token = cookieStore.get(COOKIE_NAME)?.value;
  if (!token) return false;
  return verifySessionToken(token);
}

export { COOKIE_NAME };
```

### 3.2 src/app/api/auth/login/route.ts

- POST 엔드포인트
- `request.json()`에서 username/password 추출
- `AUTH_USERNAME`, `AUTH_PASSWORD` 환경변수와 비교
- 성공 시 `createSessionToken()` → `Set-Cookie` 헤더로 httpOnly 쿠키 발급
- 쿠키 옵션: `Path=/`, `HttpOnly`, `SameSite=Lax`, `Max-Age=86400`, `Secure`(prod only)

### 3.3 src/app/api/auth/logout/route.ts

- POST 엔드포인트
- `Set-Cookie`로 쿠키 삭제 (`Max-Age=0`)

### 3.4 src/app/(auth)/login/page.tsx

- `"use client"` 클라이언트 컴포넌트
- username/password 폼 → `/api/auth/login` POST → 성공 시 `router.push("/")`
- 에러 메시지 표시, 로딩 스피너
- 중앙 정렬 레이아웃

### 3.5 src/middleware.ts (선택)

- 보호된 경로에 인증 검증 적용
- 공개 경로(`/login`, `/api/auth`)와 정적 파일(`/_next`, `.` 포함)은 통과
- 세션 쿠키 존재 여부만 확인 (Edge Runtime에서 `crypto` 모듈 사용 불가)
- 서명 검증은 API Route(Node.js Runtime)에서 수행

## 4. 적용 순서

1. 환경변수 설정 (`.env`)
2. `src/lib/auth.ts` 생성
3. login/logout API Route 생성
4. 로그인 페이지 생성
5. (선택) middleware 생성
6. `npm run dev`로 로그인 테스트
7. Vercel 환경변수에 `AUTH_SECRET`, `AUTH_USERNAME`, `AUTH_PASSWORD` 추가
