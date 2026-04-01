---
name: create-monolith-demo
description: 기획(spec) 완료 후 Next.js + Prisma + Neon + Vercel 모노리스 데모 프로젝트를 스캐폴딩. "데모 프로젝트 만들어줘", "monolith demo", "프로젝트 스캐폴딩", "모노리스 프로젝트 생성" 시 사용.
---

# create-monolith-demo

기획이 완료된 상태에서 Next.js 풀스택 모노리스 프로젝트를 스캐폴딩한다.

## Prerequisites

- `docs/superpowers/specs/` 에 디자인 문서(spec)가 존재해야 한다
- Node.js 18+ 설치
- 현재 작업 디렉토리(cwd)가 빈 디렉토리이거나 새 프로젝트를 생성할 위치여야 한다

## Tech Stack (Fixed)

| 항목 | 기술 |
|---|---|
| Framework | Next.js (App Router) |
| DB | Neon Postgres + Prisma ORM |
| UI | shadcn/ui + Tailwind CSS v4 |
| State | Zustand |
| Charts | Recharts |
| Deploy | Vercel |

## Phase A: Scaffolding (이 스킬이 실행하는 범위)

아래 단계를 순서대로 실행한다.

### Step 1. Spec 탐색

`docs/superpowers/specs/` 에서 디자인 문서를 찾는다.

- 파일이 1개면 해당 파일을 읽는다
- 여러 개면 사용자에게 어떤 spec을 사용할지 선택을 요청한다
- 없으면 사용자에게 먼저 기획을 완료하라고 안내하고 중단한다

spec에서 추출할 정보:
- 프로젝트명
- 프로젝트 설명
- 데이터 모델 (엔티티, 필드, 관계)
- 인증 필요 여부

### Step 2. Assets 복사

이 스킬의 `assets/` 디렉토리에 있는 모든 파일을 cwd에 생성한다.

생성되는 파일 목록:
```
package.json
tsconfig.json
next.config.ts
postcss.config.mjs
eslint.config.mjs
components.json
.env.example
.gitignore
prisma/schema.prisma
src/app/layout.tsx
src/app/globals.css
src/app/page.tsx
src/lib/prisma.ts
src/lib/utils.ts
src/stores/useStore.ts
```

### Step 3. Prisma 스키마 생성

spec의 데이터 모델을 기반으로 `prisma/schema.prisma`에 Prisma 모델을 추가한다.

규칙:
- `assets/prisma/schema.prisma`의 generator/datasource 설정은 유지
- spec의 각 엔티티를 Prisma model로 변환
- 필드 타입은 PostgreSQL 호환으로 매핑
- 관계(1:N, M:N)가 있으면 `@relation`으로 정의
- `id`는 `@id @default(cuid())` 사용
- `createdAt`, `updatedAt`은 자동 포함

### Step 4. 의존성 버전 조회

모든 패키지의 최신 stable 버전을 조회한다:

```bash
npm info <package-name> version
```

### Step 5. 호환성 검증

조회된 버전 간 호환성을 반드시 확인한다.

**필수 검증 쌍:**
- `next` <-> `react` / `react-dom` (Next.js가 요구하는 React 버전)
- `next` <-> `eslint-config-next` (메이저 버전 일치)
- `prisma` <-> `@prisma/client` (동일 버전)
- `tailwindcss` <-> `@tailwindcss/postcss` (메이저 버전 일치)
- `@types/react` <-> `react` (메이저 버전 호환)

호환되지 않으면 호환 가능한 버전 조합으로 조정한다.

검증 방법:
- `npm info next peerDependencies` 로 Next.js의 React 요구 버전 확인
- 메이저 버전 불일치 시 하위 호환 버전으로 다운그레이드

### Step 6. Placeholder 치환

아래 파일들의 placeholder를 실제 값으로 치환한다:

**package.json:**
- `{{PROJECT_NAME}}`: spec의 프로젝트명 (kebab-case)
- `{{PROJECT_DESCRIPTION}}`: spec의 프로젝트 설명
- `{{LATEST}}`: Step 5에서 검증된 실제 버전

**src/app/layout.tsx:**
- `{{PROJECT_NAME}}`: metadata title
- `{{PROJECT_DESCRIPTION}}`: metadata description

**src/app/page.tsx:**
- `{{PROJECT_NAME}}`: 랜딩 페이지 제목

### Step 7. .env 파일 생성

`.env.example`을 복사하여 `.env`를 생성한다:

```bash
cp .env.example .env
```

> `.env`는 이후 Phase B(구현) 및 Phase C(배포) 단계에서 실제 값으로 채운다.
> 이 시점에서는 placeholder 값 그대로 둔다.

### Step 8. npm install

```bash
npm install
```

### Step 9. Prisma Client 생성

```bash
npx prisma generate
```

> `npm install` 후 Prisma Client 타입을 생성해야 빌드와 IDE 자동완성이 정상 동작한다.

### Step 10. shadcn/ui 초기화

```bash
npx shadcn@latest init --yes
```

`components.json`이 이미 존재하므로 해당 설정을 따른다. `--yes` 플래그로 인터랙티브 프롬프트를 건너뛴다.

> **주의**: shadcn init이 `globals.css`를 덮어쓸 수 있다.
> init 완료 후 `src/app/globals.css`의 내용이 변경되었다면, assets의 원본 `globals.css`로 복원한다.

### Step 11. Git 초기화

```bash
git init
git add -A
git commit -m "chore: initial project scaffolding"
```

### Step 12. 완료 안내

아래 내용을 사용자에게 출력한다:

```
스캐폴딩 완료!

생성된 프로젝트 구조:
- prisma/schema.prisma  → 데이터 모델 정의
- src/app/              → 페이지 및 레이아웃
- src/lib/prisma.ts     → Prisma 클라이언트
- src/lib/utils.ts      → 유틸리티
- src/stores/           → Zustand 상태 관리

다음 단계:
1. [구현] references/implementation-guide.md 참조
   → API Route, 페이지, 시드 데이터 구현
2. [배포] references/deployment-guide.md 참조
   → Neon DB 생성 + Vercel 배포
3. [인증] references/auth-guide.md 참조 (필요 시)
   → 쿠키 기반 세션 인증 적용

"Phase B 진행해줘" 라고 하면 구현을 시작합니다.
"배포해줘" 라고 하면 배포 가이드를 따릅니다.
```

## Phase B: Implementation (가이드 참조)

사용자가 구현을 요청하면 `references/implementation-guide.md`를 읽고 따른다.

## Phase C: Deployment (가이드 참조)

사용자가 배포를 요청하면 `references/deployment-guide.md`를 읽고 따른다.

## Auth (가이드 참조)

spec에 인증이 포함되어 있거나 사용자가 인증 추가를 요청하면 `references/auth-guide.md`를 읽고 따른다.
