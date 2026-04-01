# Phase B: Implementation Guide

스캐폴딩 완료 후 spec 기반으로 실제 기능을 구현하는 가이드.

## 순서

### 1. Prisma 스키마 확정 및 DB 반영

스캐폴딩 시 생성된 `prisma/schema.prisma`의 모델을 검토하고 필요하면 수정한다.

```bash
# 스키마를 DB에 반영 (개발용)
npx prisma db push

# Prisma Client 재생성
npx prisma generate
```

> **주의**: 프로덕션에서는 `prisma migrate dev` → `prisma migrate deploy`를 사용한다.
> `db push`는 개발/프로토타입 단계에서만 사용한다.

### 2. 시드 데이터 작성

`prisma/seed.ts`를 생성하여 초기 데이터를 삽입한다.

- `PrismaClient` 인스턴스 생성
- 기존 데이터 정리 → `createMany`로 시드 삽입
- `main().catch().finally($disconnect)` 패턴 사용
- 대용량 데이터는 `prisma/data/seed-data.json`으로 분리
- 실행: `npm run db:seed`

### 3. API Route 구현

`src/app/api/` 하위에 spec의 각 리소스별 엔드포인트를 생성한다.

**파일 구조:**
- `src/app/api/{resource}/route.ts` — GET(목록, 페이지네이션+필터), POST(생성)
- `src/app/api/{resource}/[id]/route.ts` — GET(상세), PUT(수정), DELETE(삭제)

**핵심 규칙:**
- `@/lib/prisma`에서 Prisma Client import
- 동적 라우트의 params 타입: `{ params: Promise<{ id: string }> }` (Next.js 15+에서 params는 Promise)
- 페이지네이션: `page`, `limit` 쿼리 파라미터, `skip`/`take`로 변환, `count`와 병렬 조회
- 입력 검증: POST/PUT에서 필수 필드 확인
- 에러 핸들링: `try/catch`, `console.error`, 사용자 친화적 에러 메시지 반환
- 응답 형식: `Response.json()`

### 4. 페이지 구현

`src/app/` 하위에 spec의 페이지를 생성한다.

**라우트 그룹:**
- `(portal)/` — 메인 포털 (Header + Sidebar 공통 레이아웃)
- `(auth)/` — 인증 관련 (별도 레이아웃, 필요 시)

**핵심 규칙:**
- 데이터 fetch가 필요한 페이지는 `"use client"` + `useEffect` + `useState` 패턴
- 로딩 상태: `Loader2` (lucide-react) 스피너
- shadcn/ui 컴포넌트 적극 활용

### 5. 레이아웃 구현

`src/app/(portal)/layout.tsx`에 포털 레이아웃을 구현한다.

- `"use client"` — Sidebar 토글 등 인터랙션 필요
- 구조: `flex h-screen flex-col` > Header + `flex flex-1 overflow-hidden` > Sidebar + `main flex-1 overflow-y-auto`
- Header, Sidebar 컴포넌트는 `@/components/layout/`에 분리

### 6. shadcn/ui 컴포넌트 추가

필요한 컴포넌트를 추가:

```bash
npx shadcn@latest add button card input table badge dialog
```

### 7. Recharts 차트 (필요 시)

- `"use client"` 필수
- `ResponsiveContainer`로 반응형 래핑
- spec에 맞는 차트 타입 선택 (BarChart, LineChart, PieChart 등)

## Checklist

구현 완료 시 확인:

- [ ] `prisma db push` 성공
- [ ] 시드 데이터 삽입 성공
- [ ] 모든 API Route 정상 동작 (curl 또는 브라우저)
- [ ] 모든 페이지 렌더링 확인 (`npm run dev`)
- [ ] `npm run build` 에러 없음
- [ ] `npm run lint` 에러 없음
