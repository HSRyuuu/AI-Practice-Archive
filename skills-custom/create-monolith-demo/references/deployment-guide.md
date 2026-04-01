# Phase C: Deployment Guide

Neon DB 생성 + Vercel 배포 가이드.

## 1. Neon DB 생성

### 1.1 프로젝트 생성

1. https://neon.tech 접속, 계정 생성/로그인
2. "New Project" 클릭
3. 프로젝트 이름, 리전(ap-southeast-1 등 가까운 리전) 설정
4. Postgres 버전 선택 (기본값 권장)
5. "Create Project" 클릭

### 1.2 Connection String 복사

프로젝트 생성 후 Dashboard에서:

- **Connection string** (pooled): `DATABASE_URL`에 사용
- **Direct connection**: `DIRECT_DATABASE_URL`에 사용

```
# Pooled (Connection Pooling 사용 - 앱 런타임용)
postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require

# Direct (직접 연결 - Prisma migrate용)
postgresql://user:pass@ep-xxx.region.aws.neon.tech/dbname?sslmode=require
```

> **주의**: Pooled URL에는 `-pooler`가 포함되어 있다.

### 1.3 로컬에서 DB 연결 확인

`.env` 파일 생성 (`.env.example` 복사):

```bash
cp .env.example .env
```

`.env`에 실제 connection string 입력 후:

```bash
# 스키마를 DB에 반영
npx prisma db push

# Prisma Studio로 확인
npx prisma studio
```

### 1.4 시드 데이터 투입

```bash
npm run db:seed
```

## 2. Vercel 배포

### 2.1 Vercel CLI 설치

```bash
npm i -g vercel
```

### 2.2 방법 A: GitHub 연동 (추천)

1. 프로젝트를 GitHub 리포지토리에 push
2. https://vercel.com 에서 "Import Project"
3. GitHub 리포를 선택
4. 환경변수 설정 (아래 참조)
5. "Deploy" 클릭

이후 `git push`만으로 자동 배포된다.

### 2.3 방법 B: CLI 직접 배포

```bash
# Vercel 프로젝트 연결
vercel link

# 환경변수 설정
vercel env add DATABASE_URL
vercel env add DIRECT_DATABASE_URL

# 프리뷰 배포
vercel deploy

# 프로덕션 배포
vercel deploy --prod
```

### 2.4 환경변수 설정

Vercel Dashboard > Project > Settings > Environment Variables:

| 변수 | 값 | 환경 |
|---|---|---|
| `DATABASE_URL` | Neon pooled connection string | Production, Preview, Development |
| `DIRECT_DATABASE_URL` | Neon direct connection string | Production, Preview, Development |
| `AUTH_SECRET` | 랜덤 문자열 (인증 사용 시) | Production, Preview, Development |

### 2.5 빌드 설정

Vercel은 Next.js를 자동 감지한다. `package.json`의 build 스크립트:

```json
"build": "prisma generate && next build"
```

`prisma generate`가 빌드 전에 실행되어 Prisma Client가 생성된다.

## 3. 배포 후 확인

```bash
# 배포된 URL 확인
vercel ls

# 로그 확인
vercel logs <deployment-url>
```

체크리스트:
- [ ] 배포 URL 접속 시 페이지 정상 렌더링
- [ ] API Route 호출 시 DB 데이터 반환
- [ ] Prisma Studio에서 데이터 확인 (로컬에서 Neon DB 연결)

## 4. 커스텀 도메인 (선택)

```bash
vercel domains add your-domain.com
```

또는 Vercel Dashboard > Project > Settings > Domains에서 추가.

## Neon Free Tier 제한

| 항목 | 제한 |
|---|---|
| Compute | 191.9 hours/월 |
| Storage | 512MB |
| Branches | 10개 |
| Auto-suspend | 5분 비활동 시 |

데모/프로토타입 용도로 충분하다.
