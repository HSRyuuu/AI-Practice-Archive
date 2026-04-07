---
name: kb-merge
description: |
  중복·유사 문서를 하나로 병합한다.
  트리거: "/kb-merge {문서A} {문서B}", "/kb-merge", "중복 문서 합쳐줘"
  명시 모드 (두 문서 지정) / 자동 모드 (중복 스캔) 지원.
---

# KB Merge — 중복 병합

중복되거나 유사한 문서를 하나로 합친다.

---

## Step 0. 볼트 경로 확인 + 스키마 로드

1. `~/.config/kb/config.json`을 읽어 `kb_root` 경로를 확인한다.
2. `{kb_root}/SCHEMA.md`를 읽어 폴더 구조를 파악한다.
3. `{kb_root}/.claude/CLAUDE.md`를 읽어 컨벤션을 확인한다.
4. 없으면 에러: **"`/kb-setup`을 먼저 실행하세요."**

---

## 모드 판단

| 입력 | 모드 |
|---|---|
| `/kb-merge 문서A 문서B` | 명시 모드 |
| `/kb-merge` (인자 없음) | 자동 모드 |

---

## 명시 모드

### Step 1. 대상 문서 읽기

두 문서를 찾아 읽는다. 파일명, 00_index_{Name}.md, qmd 검색을 통해 탐색한다.

각 문서에서 추출:
- frontmatter (tags, group 등)
- 본문 내용
- 위키링크 목록

### Step 2. 병합 방향 결정

내용의 풍부함과 품질을 기준으로 primary 문서를 선택한다.

> "→ **{primary}**에 병합하겠습니다. {absorbed}는 삭제됩니다. 확인?"

### Step 3. 병합 실행

1. **Frontmatter 병합**: tags 합집합, group 합집합
2. **본문 병합**: primary 내용 유지 + absorbed의 고유 내용 추가. 중복 제거.
3. **Absorbed 문서 삭제**: 파일 삭제

### Step 4. 백링크 수정

볼트 전체에서 absorbed 문서를 참조하는 위키링크를 primary로 변경한다:

- `[[absorbed-문서]]` → `[[primary-문서]]`
- `[[absorbed-문서|표시텍스트]]` → `[[primary-문서|표시텍스트]]`

### Step 5. 00_index_{Name}.md 갱신

- absorbed 문서가 있던 폴더의 00_index_{Name}.md에서 항목 제거
- primary 문서의 00_index_{Name}.md 항목 업데이트 (한줄 요약 갱신)

---

## 자동 모드

### Step 1. 중복 스캔

볼트 전체를 스캔하여 중복 후보 쌍을 탐지한다:

- 제목이 유사한 문서
- tags가 80% 이상 겹치는 문서
- 본문 내용이 상당 부분 중복되는 문서

### Step 2. 쌍별 확인

각 후보 쌍에 대해:

```
중복 후보: {문서A} ↔ {문서B}
  - A: {제목} (tags: ...)
  - B: {제목} (tags: ...)
  병합할까요? [Y/n/skip]
```

승인된 쌍에 대해 명시 모드의 Step 2~5를 수행한다.

---

## Git 커밋

```bash
cd {kb_root}
git add -A
git commit -m "kb: merge '{absorbed}' into '{primary}'"
```

자동 모드에서 여러 쌍을 병합한 경우:

```bash
git commit -m "kb: merge {n} duplicate pairs"
```
