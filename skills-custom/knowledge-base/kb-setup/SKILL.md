---
name: kb-setup
description: |
  Knowledge Base 볼트 초기 세팅. 디렉토리 구조, SCHEMA.md, CLAUDE.md, config.json을 생성한다.
  트리거: "/kb-setup", "KB 세팅", "knowledge base 초기화"
---

# KB 초기 세팅

새로운 Knowledge Base 볼트를 생성한다.

## Step 0. 대상 디렉토리 확인

사용자에게 볼트를 생성할 디렉토리를 물어본다:

> "Knowledge Base 볼트를 생성할 경로를 알려주세요. (예: ~/workspace/KnowledgeBase)"

- 디렉토리가 이미 존재하면 그대로 사용 (기존 파일 보존)
- 디렉토리가 없으면 생성

이후 모든 경로는 `{KB_ROOT}`로 표기한다.

## Step 1. config.json 생성

`~/.config/kb/config.json`에 볼트 경로를 저장한다. 모든 kb-* 스킬이 이 파일을 읽어 볼트 위치를 찾는다.

```bash
mkdir -p ~/.config/kb
```

```json
{
  "kb_root": "{KB_ROOT의 절대 경로}"
}
```

이미 파일이 존재하면 `kb_root` 값을 업데이트한다.

## Step 2. SCHEMA.md 대화형 생성

사용자와 대화하며 초기 폴더 구조와 Group을 정의한다.

1. 루트 폴더 질문: "어떤 최상위 폴더를 만들까요? (예: Work, Common, Personal)"
2. 하위 폴더 질문: 각 루트 폴더에 대해 "하위 폴더가 필요한가요?"
3. Group 질문: "Group을 정의해주세요. (보통 루트 폴더와 1:1 대응)"
4. 사용자 승인 후 `{KB_ROOT}/SCHEMA.md` 생성

SCHEMA.md 형식:

```markdown
# SCHEMA

## 폴더 구조

| 폴더명 | 설명 |
|---|---|
| {폴더명}/ | {설명} |

## Group

Group은 frontmatter에서 문서의 큰 분류를 나타냅니다. 직접 지정하세요.

| 그룹명 | 설명 |
|---|---|
| {그룹명} | {설명} |
```

## Step 3. 디렉토리 구조 생성

SCHEMA.md에 정의된 모든 폴더를 생성한다.

```bash
mkdir -p {KB_ROOT}/{각 폴더}
mkdir -p {KB_ROOT}/raw
mkdir -p {KB_ROOT}/Inbox
```

각 폴더에 `00_index_{폴더명}.md`를 생성한다:

```markdown
# {폴더명}

## 하위 폴더

| 이름 | 설명 |
|---|---|

## 문서

| 문서 | 설명 |
|---|---|
```

`raw/`와 `Inbox/`에는 `.gitkeep`만 생성한다 (00_index_{폴더명}.md 불필요).

## Step 4. CLAUDE.md 생성

`{KB_ROOT}/.claude/CLAUDE.md`를 생성한다.

핵심 내용:
- 핵심 원칙 (폴더=분류, LLM 보조, 생성 금지, 컨펌 필수)
- Frontmatter 컨벤션 (tags 필수, group/source/created 선택)
- 00_index_{Name}.md 컨벤션
- 스킬 목록
- 공통 후처리 규칙
- Git 커밋 컨벤션

## Step 5. qmd 설치 확인

```bash
which qmd
```

- 설치되어 있으면: 버전 출력. `qmd index build` 실행하여 초기 인덱스 생성.
- 설치되어 있지 않으면: 안내 메시지 출력.
  > "qmd가 설치되어 있지 않습니다. 마크다운 검색을 위해 설치를 권장합니다: https://github.com/tobi/qmd"

## Step 6. Git 초기화

```bash
cd {KB_ROOT}
git init  # .git이 이미 있으면 건너뜀
git add -A
git commit -m "kb: initial setup"
```

## Step 7. 완료 메시지

```
KB 볼트 초기 세팅 완료.
- 볼트 경로: {KB_ROOT}
- config: ~/.config/kb/config.json
- SCHEMA.md: {N}개 폴더 정의
- 00_index_{Name}.md: {M}개 생성
- Obsidian에서 이 폴더를 볼트로 열어주세요.
```
