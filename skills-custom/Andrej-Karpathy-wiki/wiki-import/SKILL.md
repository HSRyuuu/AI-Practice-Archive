---
name: wiki-import
description: |
  기존 Obsidian 볼트의 노트를 Wiki로 마이그레이션하는 스킬.
  트리거: "/wiki-import {볼트경로}", "기존 노트 가져와", "마이그레이션"
  소스 볼트를 스캔하여 노트를 분류하고, Wiki 디렉토리 구조에 맞게 배치한 뒤
  frontmatter·위키링크를 변환하고 index를 업데이트한다.
---

# Wiki Import

기존 Obsidian 볼트(예: `~/dev/local_workspace/knowledge_hub`)의 노트를 Wiki 구조로 일괄 마이그레이션한다.

---

## Step 0. 볼트 경로 확인 + 스키마 읽기

1. `~/.config/wiki/config.json`을 읽어 `wiki_root` 경로를 확인한다.
2. 파일이 없거나 `wiki_root`가 없으면 사용자에게 볼트 경로를 물어본 뒤 `~/.config/wiki/config.json`에 저장한다.
3. `{wiki_root}/CLAUDE.md`를 읽어 현재 디렉토리 구조, frontmatter 컨벤션, scope 태그, slug 규칙을 확인한다.
4. CLAUDE.md가 없으면 에러: **"CLAUDE.md가 없습니다. `/wiki-setup`을 먼저 실행하세요."**

---

## Step 1. 소스 볼트 스캔

사용자가 지정한 볼트 경로에서 모든 `.md` 파일과 첨부파일(이미지 등)을 재귀적으로 수집한다.

### 첨부파일 처리

- 이미지 파일 (`.png`, `.jpg`, `.gif`, `.webp`, `.svg` 등) → `raw/assets/`에 복사
- 마크다운 내 이미지 참조 (`![[image.png]]`) → 경로를 `raw/assets/`로 변환
- PDF 첨부 → `raw/pdfs/`에 복사

### 제외 디렉토리

아래 디렉토리는 스캔에서 **완전히 제외**한다:

| 디렉토리 | 이유 |
|---|---|
| `.obsidian/` | Obsidian 설정 |
| `.trash/` | Obsidian 휴지통 |
| `.omc/` | Obsidian Meta Community 플러그인 |
| `.claude/` | Claude 설정 |
| `.idea/` | JetBrains IDE 설정 |

### 스캔 명령어

```bash
find {볼트경로} -name '*.md' \
  -not -path '*/.obsidian/*' \
  -not -path '*/.trash/*' \
  -not -path '*/.omc/*' \
  -not -path '*/.claude/*' \
  -not -path '*/.idea/*' \
  -type f
```

스캔 결과를 목록으로 저장하고, 총 노트 수를 사용자에게 보고한다:

```
소스 볼트: {볼트경로}
발견된 노트: {N}개 (.obsidian, .trash, .omc, .claude, .idea 제외)
```

---

## Step 2. 노트 분류

각 노트의 내용과 기존 경로를 분석하여 3가지 카테고리로 분류한다.

### 분류 기준

| 카테고리 | 조건 | 대상 경로 | 처리 |
|---|---|---|---|
| **Structured reference** | 체계적 설명, 개념 정의, 기술 문서, 비교 분석, 허브 페이지 | `wiki/concepts/` | frontmatter 추가 + `type` 필드 부여 |
| **Fleeting / research** | 메모, 리서치 노트, 미가공 스크랩, 일기, 회의록 | `raw/notes/` | frontmatter 추가 |
| **Secret** | 파일명이 `_secret_` 접두사로 시작 | `secrets/` | 그대로 이동, wiki 가공 안 함 |

### Structured reference 세부 분류

`wiki/concepts/`로 분류된 노트에는 CLAUDE.md의 문서 타입 중 적절한 값을 `type`으로 부여한다:

| type | 판단 근거 |
|---|---|
| `concept` | 단일 개념에 대한 독립적 설명 |
| `entity` | 특정 제품, 서비스, 조직 등 고유명사 중심 |
| `hub` | 여러 관련 문서를 모아 연결하는 허브 역할 |
| `synthesis` | 여러 소스를 교차 분석한 통찰 |
| `comparison` | 둘 이상의 개념/기술 비교 |
| `overview` | 특정 영역의 전체 조감도 |

### Scope 태그 자동 부여

각 노트의 내용과 기존 경로를 분석하여 scope 태그를 자동 부여한다:

- 업무 관련 키워드(사내 프로젝트명, 회사명 등) → `mobigen`
- 개인 학습/프로젝트/생활 → `personal`
- 양쪽에 걸치면 둘 다 부여: `[mobigen, personal]`
- 주제별 자유 태그도 함께 부여 (예: `python`, `rag`, `docker`)

### 모호한 문서 일괄 확인

분류가 모호한 노트는 즉시 배치하지 않고 별도 목록으로 모은다. 모든 노트 분석이 끝난 후 사용자에게 일괄 확인을 요청한다:

```
=== 분류 확인 필요 ({M}건) ===

1. meeting-notes-0325.md
   → 현재 판단: raw/notes/ (fleeting) | scope: mobigen
   → 다른 선택지: wiki/concepts/ (hub)

2. python-tips.md
   → 현재 판단: wiki/concepts/ (concept) | scope: personal
   → 다른 선택지: raw/notes/ (fleeting)

각 항목에 대해 [확인/변경]을 알려주세요.
또는 "전체 확인"으로 현재 판단을 일괄 승인할 수 있습니다.
```

### Frontmatter 추가 규칙

#### wiki/concepts/ 배치 노트

```yaml
---
tags: [{scope태그}, {자유태그}, ...]
type: {concept|entity|hub|synthesis|comparison|overview}
created_at: {원본 파일의 생성 시간 또는 현재 시간, ISO 8601 UTC}
updated_at: {현재 시간, ISO 8601 UTC}
imported_from: {소스 볼트 내 원래 경로}
---
```

#### raw/notes/ 배치 노트

```yaml
---
source: {소스 볼트 내 원래 경로}
ingested_at: {현재 시간, ISO 8601 UTC}
type: note
scope: [{scope태그}]
sensitive: false
imported_from: {소스 볼트 내 원래 경로}
---
```

#### secrets/ 배치 노트

원본 그대로 복사한다. frontmatter가 없으면 아래를 추가한다:

```yaml
---
sensitive: true
imported_from: {소스 볼트 내 원래 경로}
---
```

### Slug 변환

파일명은 CLAUDE.md의 slug 규칙에 따라 kebab-case로 변환한다:

- 공백 → `-`
- 특수문자 제거
- 연속 `-` 금지
- 최대 60자
- 한글 포함 가능

---

## Step 3. Index 업데이트 및 위키링크 변환

### 3.1 위키링크 변환

소스 볼트의 위키링크(`[[원래파일명]]`)를 새로운 구조에 맞게 변환한다:

- 대상 노트가 import 목록에 있으면 → 새 경로의 slug로 변경
  - 예: `[[Python Tips]]` → `[[python-tips]]`
- 대상 노트가 import 목록에 없으면 → 일반 텍스트로 변환
  - 예: `[[없는문서]]` → `없는문서`
- alias가 있는 링크는 보존: `[[python-tips|파이썬 팁]]`

### 3.2 index 업데이트

`wiki/index.md`에 import된 문서를 추가한다:

```markdown
## 개념 (Concepts)

- [[{slug}]] — {한줄 요약} `{type}` `{scope태그}`
```

카테고리별로 정렬하여 기존 항목 뒤에 추가한다.

### 3.3 log.md 기록

`wiki/log.md`에 import 이벤트를 기록한다:

```markdown
## [{날짜}] import | {소스 볼트명}

- 소스: {볼트경로}
- 총 {N}개 노트 import
  - wiki/concepts/: {A}개
  - raw/notes/: {B}개
  - secrets/: {C}개
```

---

## Step 4. Git 커밋

모든 파일 배치가 완료되면 하나의 커밋으로 기록한다.

```bash
cd
git add -A
git commit -m "wiki: import {N} notes from {볼트명}"
```

커밋 메시지는 CLAUDE.md의 컨벤션을 따른다.

---

## Step 5 (후속): wiki-lint 추천

import 완료 후 아래 메시지를 출력한다:

```
Import 완료:
- wiki/concepts/: {A}개
- raw/notes/: {B}개
- secrets/: {C}개
- 위키링크 변환: {L}건
- index.md 업데이트 완료
- git commit 완료

후속 작업으로 /wiki-lint 실행을 추천합니다.
- 누락된 위키링크 검출
- 고아 페이지(orphan) 확인
- frontmatter 일관성 검증
- scope 태그 누락 검사
```
