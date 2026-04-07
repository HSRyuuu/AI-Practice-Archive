---
name: kb-update-schema
description: |
  SCHEMA.md를 대화형으로 업데이트한다. 폴더 추가/삭제, Group 변경, 배치 규칙 수정.
  트리거: "/kb-update-schema", "스키마 업데이트", "폴더 구조 변경"
---

# KB Update Schema — SCHEMA.md 대화형 업데이트

SCHEMA.md를 사용자와 대화하며 업데이트한다.

---

## Step 0. 볼트 경로 확인 + 현재 스키마 로드

1. `~/.config/kb/config.json`을 읽어 `kb_root` 경로를 확인한다.
2. `{kb_root}/SCHEMA.md`를 읽어 현재 폴더 구조와 Group 정의를 파악한다.
3. 없으면 에러: **"`/kb-setup`을 먼저 실행하세요."**

---

## Step 1. 현재 상태 출력

현재 SCHEMA.md의 폴더 구조와 Group을 사용자에게 보여준다:

```
현재 SCHEMA:
[폴더 구조 테이블]
[Group 테이블]

무엇을 변경할까요?
1. 폴더 추가
2. 폴더 삭제
3. Group 추가/수정
4. 직접 편집
```

---

## Step 2. 대화형 변경

사용자의 선택에 따라:

### 폴더 추가

1. 폴더명과 설명을 물어본다.
2. 상위 폴더를 확인한다.
3. 변경 사항을 보여주고 승인을 받는다:
   > "SCHEMA.md에 `{폴더명}/`을 추가하겠습니다. 확인?"
4. 승인 시:
   - SCHEMA.md 폴더 구조 테이블에 행 추가
   - 실제 폴더 생성
   - 00_index_{폴더명}.md 생성
   - 상위 폴더 00_index_{Name}.md에 하위 폴더 링크 추가

### 폴더 삭제

1. 삭제할 폴더를 확인한다.
2. 폴더에 파일이 있으면 경고한다:
   > "이 폴더에 {N}개의 파일이 있습니다. 파일을 먼저 이동해주세요."
3. 빈 폴더만 삭제 가능. SCHEMA.md에서 행 제거 + 실제 폴더 삭제.

### Group 추가/수정

1. 그룹명과 설명을 물어본다.
2. SCHEMA.md Group 테이블 업데이트.

---

## Step 3. Git 커밋

```bash
cd {kb_root}
git add SCHEMA.md
git add -A
git commit -m "kb: update schema — {변경 내용 요약}"
```
