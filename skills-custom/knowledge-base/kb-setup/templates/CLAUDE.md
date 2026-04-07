# Knowledge Base

> 이 파일은 모든 kb-* 스킬이 Step 0으로 읽는 스키마 정의서이다.
> LLM Wiki 방법론으로 관리되는 지식 저장소의 구조, 컨벤션, 워크플로우를 정의한다.

---

## 1. 핵심 태그 (Scope Tags)

모든 wiki 문서는 반드시 하나 이상의 핵심 태그를 가져야 한다.

```yaml
scope_tags:
  - mobigen     # 모비젠 업무 관련
  - personal    # 개인 프로젝트 / 학습 / 생활
```

### 태그 부여 규칙

| 규칙 | 설명 |
|---|---|
| **자동 부여** | ingest 시 LLM이 내용을 분석하여 핵심 태그를 자동 판단한다 |
| **모호하면 역질문** | 판단이 어려운 경우 사용자에게 반드시 확인한다: "이 소스는 mobigen/personal 중 어디에 해당하나요?" |
| **양쪽 가능** | 두 영역에 걸치는 지식은 둘 다 부여한다 — `tags: [mobigen, personal, python]` |
| **자유 태그 병행** | 핵심 태그 외에 주제별 자유 태그(evax, rag, python 등)를 함께 사용한다 |

---

## 2. 문서 타입 (Document Types)

`wiki/concepts/` 내 문서의 `type` 필드에 사용한다. 아래는 대표적 타입이며, 필요에 따라 새 타입을 추가할 수 있다 (Schema 진화 프로세스 §7 참조).

| 타입 | 설명 | 예시 |
|---|---|---|
| `concept` | 단일 개념에 대한 독립 참조 문서 | `rag-파이프라인.md` |
| `entity` | 특정 제품, 서비스, 조직 등 고유 엔터티 | `graphio.md` |
| `hub` | 프로젝트/주제의 허브 페이지. 관련 문서를 모아 연결한다 | `evax.md` |
| `synthesis` | 여러 소스를 교차 분석하여 새로운 통찰을 도출한 문서 | `rag-vs-fine-tuning-전략.md` |
| `comparison` | 두 개 이상의 개념/기술을 비교한 문서 | `fastapi-vs-flask.md` |
| `overview` | 특정 영역의 전체 조감도 | `모비젠-ai-전환-현황.md` |
| `answer` | kb-ask로 생성된 질문 답변 문서 | `evax-rag-현재-구조.md` |

---

## 3. 디렉토리 구조

```
knowledge-base/
├── raw/                        # 원본 소스 (불변, LLM은 읽기만)
│   ├── web/       {slug}.md    #   웹 아티클
│   ├── pdfs/      {slug}.md    #   PDF 추출 텍스트 (+원본 .pdf)
│   ├── images/    {slug}.md    #   이미지 설명 (+원본 이미지)
│   ├── notes/     {slug}.md    #   자유 메모
│   └── assets/    {file}.ext   #   Obsidian 첨부파일
├── wiki/                       # LLM 관리 영역
│   ├── index.md                #   마스터 인덱스 (카탈로그)
│   ├── log.md                  #   시간순 append-only 로그
│   ├── hubs/      {slug}.md    #   프로젝트/영역 허브 페이지
│   ├── concepts/  {slug}.md    #   개념 문서
│   ├── sources/   {slug}.md    #   소스 요약
│   └── archive/   {slug}.md    #   병합/흡수된 문서
├── secrets/                    # 민감 정보 (.gitignore 대상)
└── CLAUDE.md                   # 이 파일
```

### 디렉토리별 소유 규칙

| 디렉토리 | 소유자 | 규칙 |
|---|---|---|
| `raw/` | 사용자 | LLM은 읽기만. 수정/삭제 금지 |
| `wiki/` | LLM | LLM이 생성, 업데이트, 병합, 아카이브 수행 |
| `secrets/` | 사용자 | `sensitive: true` 소스 저장. wiki 가공 안 함. git 제외 |

---

## 4. Frontmatter 컨벤션

### 4.1 Raw 소스 (`raw/`)

```yaml
---
source: {URL 또는 파일 경로}
ingested_at: {ISO 8601 UTC}       # 예: 2026-04-07T09:30:00Z
type: {web|pdf|image|note}
scope: [{핵심태그}]                # 예: [mobigen] 또는 [mobigen, personal]
sensitive: {true|false}
---
```

- `sensitive: true`이면 `secrets/`에 저장하고 wiki 가공을 하지 않는다.

### 4.2 소스 요약 (`wiki/sources/`)

```yaml
---
source: {원본 URL/경로}
ingested_at: {ISO 8601 UTC}
type: {web|pdf|image|note}
tags: [{핵심태그}, {자유태그}, ...]  # 예: [mobigen, evax, graphio]
---
```

### 4.3 개념 문서 (`wiki/concepts/`)

```yaml
---
tags: [{핵심태그}, {자유태그}, ...]
type: {concept|entity|hub|synthesis|comparison|overview|answer}
aliases: []                           # 선택. 병합 시 흡수된 문서 제목 등
created_at: {ISO 8601 UTC}
updated_at: {ISO 8601 UTC}
---
```

### 4.4 아카이브 문서 (`wiki/archive/`)

```yaml
---
title: "{흡수된 문서 제목}"
redirect: "[[{primary-slug}]]"
tags: [archived, redirect]
archived_at: {ISO 8601 UTC}
reason: "merged into [[{primary-slug}]]"
---
```

- 본문에 `> [!info] 이 문서는 [[{primary-slug}]]에 병합되었습니다.` 안내를 포함한다.

---

## 5. Slug 생성 규칙

Slug는 파일명이자 위키링크의 식별자이다. 모든 slug는 **kebab-case**를 사용한다.

| 소스 타입 | 규칙 | 예시 |
|---|---|---|
| `web` | URL 경로에서 추출, 최대 60자 | `attention-is-all-you-need-review` |
| `pdf` | 파일명 → kebab-case | `evax-rfp-요구사항` |
| `image` | 파일명 → kebab-case | `system-architecture-diagram` |
| `note` | 첫 6단어 → kebab-case | `meeting-evax-주간회의-0407` |

### 공통 규칙

- 한글 포함 가능 (Obsidian이 지원)
- 특수문자 제거, 공백은 `-`로 치환
- 연속 `-` 금지 (`--` → `-`)
- 최대 60자

---

## 6. Git 커밋 메시지 컨벤션

하나의 논리적 작업 = 하나의 커밋. 접두사는 항상 `kb:`이다.

| 스킬 | 커밋 메시지 형식 |
|---|---|
| `kb-ingest` | `kb: ingest '{제목}'` |
| `kb-ask` | `kb: ask '{질문 50자}'` |
| `kb-lint` | `kb: lint report {YYYY-MM-DD}` |
| `kb-merge` | `kb: merge concepts/{slug-b} into concepts/{slug-a}` |
| `kb-import` | `kb: import {N} notes from {볼트명}` |
| `kb-output` | `kb: output '{제목}' as {format}` |
| `kb-setup` | `kb: initial setup` |
| schema 변경 | `kb: update schema — {변경 내용}` |

---

## 7. Schema 진화 프로세스

CLAUDE.md는 사용자와 LLM이 함께 발전시킨다.

### 변경이 발생하는 경우

| 트리거 | 예시 |
|---|---|
| **LLM 제안** | kb-lint에서 반복 패턴 발견 → "새 태그/문서 타입을 CLAUDE.md에 추가할까요?" |
| **사용자 지시** | "앞으로 회의록은 항상 mobigen 태그를 붙여" → 규칙 추가 |

### 변경 절차

1. LLM이 변경 내용을 사용자에게 설명하고 **승인을 받는다** (필수)
2. CLAUDE.md를 수정한다
3. `kb: update schema — {변경 내용}` 으로 커밋한다

### 원칙

- CLAUDE.md 변경은 **항상 사용자 승인 후** 반영한다
