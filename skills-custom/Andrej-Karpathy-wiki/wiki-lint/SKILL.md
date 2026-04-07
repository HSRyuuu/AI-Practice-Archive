---
name: wiki-lint
description: |
  Wiki 건강 점검 및 교차 참조 발견 스킬.
  트리거: "/wiki-lint", "위키 점검", "위키 건강 체크"
  11가지 항목을 순차 점검하고, 스키마 진화 제안 및 로그 기록까지 수행한다.
---

# Wiki Lint — 위키 건강 점검

이 스킬은 Wiki의 품질, 일관성, 완전성을 점검한다.
단순 오류 찾기뿐 아니라 교차 연결 기회와 지식 갭을 발견하여 Wiki를 성장시킨다.

---

## Step 0. 볼트 경로 확인 + 스키마 읽기

1. `~/.config/wiki/config.json`을 읽어 `wiki_root` 경로를 확인한다.
2. 파일이 없거나 `wiki_root`가 없으면 사용자에게 볼트 경로를 물어본 뒤 `~/.config/wiki/config.json`에 저장한다.
3. `{wiki_root}/CLAUDE.md`를 읽어 현재 스키마(태그, 문서 타입, frontmatter 컨벤션, slug 규칙 등)를 파악한다.
4. CLAUDE.md가 없으면 에러: **"CLAUDE.md가 없습니다. `/wiki-setup`을 먼저 실행하세요."**

이후 모든 점검은 CLAUDE.md 규칙을 기준으로 수행한다.

---

## Step 1. 전체 파일 스캔

`wiki/` 디렉토리 전체와 `raw/` 디렉토리의 모든 `.md` 파일을 읽어 인메모리 인덱스를 구성한다.

수집 항목:
- 파일 경로, frontmatter(tags, type, created_at, updated_at), 본문 텍스트
- 모든 위키링크(`[[...]]`) 목록
- 인바운드/아웃바운드 링크 그래프

---

## Step 2. 11가지 점검 항목

아래 순서대로 점검한다. 각 항목의 결과를 `findings` 목록에 누적한다.

### 2-1. 빈약한 문서 (Thin Documents)

- 대상: `wiki/concepts/` 내 문서
- 기준: 내용이 지나치게 빈약하여 독립 참조 문서로서 가치가 부족한 경우 (LLM 판단)
- 출력: 파일 경로 + 빈약 사유

### 2-2. 누락된 개념 (Missing Concepts)

- 전체 위키링크 중 `[[concepts/X]]` 형태인데 해당 파일이 존재하지 않는 것
- 출력: 누락 slug + 해당 링크를 포함하는 문서 목록

### 2-3. 깨진 위키링크 (Broken Wikilinks)

- `[[...]]` 링크 중 대상 파일이 볼트 내에 존재하지 않는 모든 링크
- concepts 외 경로(sources, archive 등)도 포함
- 출력: 깨진 링크 + 소스 문서

### 2-4. 중복 개념 (Duplicate Concepts)

- `wiki/concepts/` 내 문서들의 제목과 내용이 의미적으로 유사한 쌍을 탐지
- 출력: 유사 문서 쌍 + 병합 제안 여부

### 2-5. 고아 페이지 (Orphan Pages)

- `wiki/concepts/` 내 문서 중 인바운드 링크가 0개인 페이지
- `wiki/index.md`와 `wiki/log.md`에서의 링크는 인바운드에서 제외한다 (목차/로그 링크는 실질적 연결이 아님)
- 출력: 고아 페이지 목록

### 2-6. 오래된 내용 (Stale Content)

- 오래되어 갱신이 필요해 보이는 문서 (LLM이 도메인 특성에 따라 판단)
- 날짜 정보가 없으면 별도 보고
- 출력: 파일 경로 + 마지막 업데이트 일자 + 갱신 필요 사유

### 2-7. 모순 탐지 (Contradictions)

- 동일 개념을 다루는 문서들(동일 태그 + 관련 위키링크로 연결된 문서군)의 핵심 주장을 비교
- LLM 판단으로 상충하는 서술이 있으면 보고
- 출력: 문서 쌍 + 모순 내용 요약

### 2-8. 핵심 태그 누락 (Missing Scope Tags)

- CLAUDE.md의 `scope_tags` (mobigen / personal) 중 하나도 없는 wiki 문서
- 출력: 파일 경로 + 현재 tags + 추천 핵심 태그

### 2-9. 교차 연결 기회 (Cross-link Opportunities)

- 직접 링크가 없지만 태그/주제가 겹치는 문서 쌍을 발견
- 3개 이상의 문서가 하나의 주제로 묶이면 `type: synthesis` 문서 생성을 제안
- 출력: 연결 후보 쌍 + synthesis 문서 제안 (제목, 포함할 문서 목록)

### 2-10. 데이터 갭 (Data Gaps)

- 문서 내에서 "TODO", "TBD", "확인 필요", "추후 조사" 등의 표현을 탐지
- 해당 갭을 보강할 수 있는 웹 검색 키워드를 제안
- 출력: 파일 경로 + 갭 내용 + 추천 검색 키워드

### 2-11. 새 질문 제안 (Suggested Questions)

- 현재 Wiki 내용을 기반으로 아직 답변되지 않은 흥미로운 질문 3~5개를 생성
- 기존 `type: answer` 문서와 중복되지 않도록 확인
- 출력: 질문 목록 + 관련 문서 참조

---

## Step 3. Schema 진화 제안

점검 과정에서 반복 패턴이 발견되면 CLAUDE.md 변경을 제안한다.

제안 예시:
- 특정 자유 태그가 5회 이상 등장 → 핵심 태그 승격 제안
- 기존 문서 타입으로 분류가 안 되는 문서가 3개 이상 → 새 타입 제안
- frontmatter에 반복적으로 추가되는 비표준 필드 → 컨벤션화 제안

**중요**: CLAUDE.md 변경은 제안만 하고, 사용자 승인 없이 직접 수정하지 않는다.

---

## Step 4. 결과 출력

### 4-1. 터미널 요약 (Terminal Summary)

아래 형식으로 터미널에 요약을 출력한다:

```
===== Wiki Lint Report — {YYYY-MM-DD} =====

총 문서 수: {N}
점검 항목     | 발견  | 심각도
-------------|------|------
빈약한 문서    | {n}  | warn
누락된 개념    | {n}  | error
깨진 위키링크  | {n}  | error
중복 개념      | {n}  | warn
고아 페이지    | {n}  | info
오래된 내용    | {n}  | info
모순           | {n}  | error
핵심 태그 누락 | {n}  | warn
교차 연결 기회 | {n}  | info
데이터 갭      | {n}  | warn
새 질문 제안   | {n}  | info

Schema 진화 제안: {있음/없음}
===========================================
```

각 항목의 상세 내용은 요약 아래에 섹션별로 출력한다.

### 4-2. wiki/log.md 기록

`wiki/log.md`에 아래 형식으로 엔트리를 **append** 한다:

```markdown
## {YYYY-MM-DD} — wiki-lint

- 총 문서: {N}
- error: {n} (누락 개념 {n}, 깨진 링크 {n}, 모순 {n})
- warn: {n} (빈약 {n}, 중복 {n}, 태그 누락 {n}, 데이터 갭 {n})
- info: {n} (고아 {n}, 오래됨 {n}, 교차 연결 {n}, 새 질문 {n})
- schema 제안: {내용 요약 또는 "없음"}
```

---

## Step 5. Git 커밋

변경된 파일만 명시적으로 스테이징하고 커밋한다.

```bash
git add wiki/log.md
# 사용자가 승인한 synthesis 문서만 개별 추가
git add wiki/concepts/{승인된-synthesis-slug}.md
git commit -m "wiki: lint report {YYYY-MM-DD}"
```

synthesis 문서 생성이 없었으면 log.md만 커밋한다.

---

## 주의사항

- `raw/` 디렉토리는 읽기만 한다. 절대 수정하지 않는다.
- `secrets/` 디렉토리는 접근하지 않는다.
- synthesis 문서 생성은 사용자에게 확인 후 진행한다 (2-9에서 제안만, 승인 시 생성).
- 점검 중 `sensitive: true` 소스는 건너뛴다.
- 모순 탐지(2-7)는 LLM 판단에 의존하므로, 확신도가 낮으면 "가능성 있는 모순"으로 표시한다.
