---
name: kb-lint
description: |
  Knowledge Base 건강 점검. 깨진 링크, 고아 페이지, 태그 누락 등을 점검한다.
  트리거: "/kb-lint", "KB 점검", "위키 건강 체크"
---

# KB Lint — 건강 점검

Knowledge Base의 품질, 일관성, 완전성을 점검한다.

---

## Step 0. 볼트 경로 확인 + 스키마 로드

1. `~/.config/kb/config.json`을 읽어 `kb_root` 경로를 확인한다.
2. `{kb_root}/SCHEMA.md`를 읽어 폴더 구조와 Group 정의를 파악한다.
3. `{kb_root}/.claude/CLAUDE.md`를 읽어 frontmatter 컨벤션을 확인한다.
4. 없으면 에러: **"`/kb-setup`을 먼저 실행하세요."**

---

## Step 1. 전체 파일 스캔

`{kb_root}` 전체에서 `.md` 파일을 수집한다 (raw/, .obsidian/, .claude/, docs/ 제외).

수집 항목:
- 파일 경로, frontmatter (tags, group, source, created)
- 모든 위키링크 (`[[...]]`) 목록
- 인바운드/아웃바운드 링크 그래프

---

## Step 2. 7가지 점검 항목

### 2-1. 깨진 위키링크

`[[...]]` 링크 중 대상 파일이 볼트 내에 존재하지 않는 모든 링크를 찾는다.

### 2-2. 00_index_{Name}.md 누락

폴더에 파일이 있지만 해당 폴더의 `00_index_{Name}.md`에 등록되지 않은 문서를 찾는다.

### 2-3. 고아 페이지

인바운드 위키링크가 0개인 문서를 찾는다. 00_index_{Name}.md에서의 링크는 인바운드에서 제외한다 (목차 링크는 실질적 연결이 아님).

### 2-4. tags 누락

frontmatter에 `tags` 필드가 없는 문서를 찾는다 (tags는 필수 필드).

### 2-5. group과 폴더 위치 불일치

`group: [Common]`인데 `Work/`에 위치하는 등 group과 실제 폴더가 맞지 않는 문서를 찾는다.

### 2-6. 중복 의심 문서

제목이나 내용이 유사한 문서 쌍을 탐지한다. `/kb-merge` 사용을 제안한다.

### 2-7. Inbox 방치

`Inbox/`에 파일이 있으면 보고한다. `/kb-add`로 정리할 것을 제안한다.

---

## Step 3. 결과 출력

```
===== KB Lint Report — {YYYY-MM-DD} =====

총 문서 수: {N}
점검 항목         | 발견  | 심각도
-----------------|------|------
깨진 위키링크     | {n}  | error
00_index_{Name}.md 누락 | {n}  | warn
고아 페이지       | {n}  | info
tags 누락        | {n}  | error
group/폴더 불일치 | {n}  | warn
중복 의심         | {n}  | info
Inbox 방치        | {n}  | info
==========================================
```

각 항목의 상세 내용은 요약 아래에 섹션별로 출력한다.

---

## Step 4. 수정 제안

각 발견 항목에 대해 수정을 제안한다. **수정은 사용자 승인 후 진행.**

- 깨진 링크 → 대상 문서 생성 또는 링크 제거 제안
- 00_index_{Name}.md 누락 → 해당 00_index_{Name}.md에 항목 추가 제안
- tags 누락 → tags 추가 제안
- group 불일치 → group 수정 또는 파일 이동 제안

---

## Step 5. Git 커밋

수정 사항이 있으면 커밋한다.

```bash
cd {kb_root}
git add -A
git commit -m "kb: lint {YYYY-MM-DD}"
```

수정 사항이 없으면 커밋하지 않는다.
