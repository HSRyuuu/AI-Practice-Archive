---
name: wiki-merge
description: |
  중복·유사 문서를 하나로 병합하는 스킬.
  트리거: "/wiki-merge {slug-a} {slug-b}", "/wiki-merge", "중복 문서 합쳐줘"
  두 가지 모드를 지원한다:
  - 명시 모드: 두 slug를 직접 지정하여 병합
  - 자동 모드: 중복 문서를 탐지하고 쌍별로 확인 후 병합
---

# Wiki 문서 병합

이 스킬은 중복되거나 유사한 문서를 하나로 합친다. wiki-lint에서 중복 개념이 발견된 후 주로 사용한다.

## 모드

### 명시 모드 (Explicit)

두 개의 slug를 인자로 받아 즉시 병합한다.

```
/wiki-merge {slug-a} {slug-b}
```

### 자동 모드 (Auto)

인자 없이 실행하면 wiki 전체를 스캔하여 중복 후보 쌍을 탐지한다.
각 쌍마다 사용자에게 병합 여부를 확인받은 뒤 진행한다.

```
/wiki-merge
```

자동 탐지 기준:
- 제목이 유사한 문서 (동의어, 약어 포함)
- tags가 80% 이상 겹치는 문서
- 본문 내용이 상당 부분 중복되는 문서

탐지된 각 쌍에 대해 아래 형태로 확인한다:

```
중복 후보 발견: {slug-a} ↔ {slug-b}
  - slug-a: {title-a} (tags: ...)
  - slug-b: {title-b} (tags: ...)
  병합할까요? [Y/n/skip]
```

## 수행 절차

### Step 0. 볼트 경로 확인 + 스키마 읽기

1. `~/.config/wiki/config.json`을 읽어 `wiki_root` 경로를 확인한다.
2. 파일이 없거나 `wiki_root`가 없으면 사용자에게 볼트 경로를 물어본 뒤 `~/.config/wiki/config.json`에 저장한다.
3. `{wiki_root}/CLAUDE.md`를 읽어 문서 구조(frontmatter 필드, 디렉토리 규칙, 네이밍 컨벤션)를 파악한다.
4. CLAUDE.md가 없으면 에러: **"CLAUDE.md가 없습니다. `/wiki-setup`을 먼저 실행하세요."**

### Step 1. 대상 문서 읽기

병합 대상 두 문서를 읽는다. `wiki/` 하위 전체에서 slug로 검색한다.

```bash
# 명시 모드
cat wiki/**/{slug-a}.md
cat wiki/**/{slug-b}.md
```

각 문서에서 아래 정보를 추출한다:
- frontmatter 전체 (title, tags, aliases, created, updated 등)
- 본문 섹션 구조
- 위키링크(`[[...]]`) 목록
- 콘텐츠 분량 (줄 수)

**병합 방향 결정**: 내용의 풍부함과 정확성을 기준으로 "더 나은 문서(primary)"를 선택한다. LLM이 분량, 백링크 수, 내용 품질 등을 종합적으로 판단한다.

사용자에게 병합 방향을 알린다:

```
병합 방향: {slug-primary} ← {slug-absorbed}
  primary 문서에 내용을 합치고, absorbed 문서는 archive로 이동합니다.
  진행할까요? [Y/n]
```

### Step 2. 문서 병합 및 아카이브

#### 2-1. Primary 문서에 내용 병합

- **frontmatter 병합**:
  - `tags`: 두 문서의 tags를 합집합(union)으로 합친다. 중복 제거.
  - `aliases`: absorbed 문서의 title과 aliases를 primary의 aliases에 추가한다.
  - `updated`: 현재 날짜로 갱신한다.
  - 나머지 필드: primary 문서의 값을 유지한다.

- **본문 병합**:
  - primary 문서의 기존 내용을 유지한다.
  - absorbed 문서에만 있는 고유 섹션/내용을 primary 문서 하단에 추가한다.
  - 완전히 중복되는 내용은 제거한다.
  - 병합 출처를 주석으로 남긴다: `%% merged from {slug-absorbed} on {date} %%`

#### 2-2. Absorbed 문서를 archive로 이동

absorbed 문서를 `wiki/archive/{slug-absorbed}.md`로 이동하고, 내용을 redirect 노트로 교체한다:

```markdown
---
title: "{absorbed-title}"
redirect: "[[{slug-primary}]]"
tags:
  - archived
  - redirect
archived: {date}
reason: "merged into [[{slug-primary}]]"
---

> [!info] 이 문서는 [[{slug-primary}]]에 병합되었습니다.
>
> [[{slug-primary}]] 문서를 참조하세요.
```

```bash
mv wiki/**/{slug-absorbed}.md wiki/archive/{slug-absorbed}.md
```

### Step 3. 백링크 수정 및 인덱스 갱신

#### 3-1. 백링크 일괄 수정

wiki 전체에서 absorbed 문서를 참조하는 위키링크를 찾아 primary로 변경한다.

```bash
# absorbed slug를 참조하는 파일 검색
grep -rl "\[\[{slug-absorbed}" wiki/
```

각 파일에서:
- `[[{slug-absorbed}]]` → `[[{slug-primary}]]`
- `[[{slug-absorbed}|표시텍스트]]` → `[[{slug-primary}|표시텍스트]]`
- `[[{slug-absorbed}#섹션]]` → `[[{slug-primary}#섹션]]` (섹션이 primary에 존재하는지 확인)

#### 3-2. 인덱스 갱신

`wiki/index.md`에서:
- absorbed 문서 항목을 제거한다.
- primary 문서 항목이 없으면 추가한다.
- aliases가 변경되었으면 반영한다.

### Step 4. log.md 기록

`wiki/log.md`에 병합 이벤트를 append한다:

```markdown
## [{날짜}] merge | {slug-absorbed} into {slug-primary}
- primary: [[concepts/{slug-primary}]]
- archived: [[archive/{slug-absorbed}]]
- 백링크 수정: {n}개 파일
```

### Step 5. Git 커밋

모든 변경사항을 커밋한다.

```bash
git add -A
git commit -m "wiki: merge concepts/{slug-absorbed} into concepts/{slug-primary}"
```

자동 모드에서 여러 쌍을 병합한 경우:

```bash
git commit -m "wiki: merge {n} duplicate concept pairs

- concepts/{slug-a1} into concepts/{slug-b1}
- concepts/{slug-a2} into concepts/{slug-b2}
..."
```

## 완료 메시지

```
문서 병합이 완료되었습니다.
- primary: {slug-primary} (tags, aliases 갱신됨)
- archived: wiki/archive/{slug-absorbed}.md (redirect 노트)
- 백링크 수정: {n}개 파일
- 커밋: wiki: merge concepts/{slug-absorbed} into concepts/{slug-primary}
```

오류가 발생하면 해당 단계와 오류 내용을 안내하고, 이미 변경된 파일 목록을 함께 출력한다.
