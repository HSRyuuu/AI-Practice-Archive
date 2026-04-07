---
name: kb-setup
description: |
  LLM Wiki Knowledge Base 볼트를 새로 생성한다. 디렉토리 구조, CLAUDE.md 스키마, 초기 파일을 세팅한다.
  트리거: "/kb-setup", "KB 세팅", "knowledge base 초기화", "KB 초기화", "볼트 세팅"
---

# KB 초기 세팅

이 스킬은 LLM Wiki Knowledge Base 볼트를 처음 구축할 때 사용한다.

## 템플릿 파일 위치

이 스킬의 `templates/` 디렉토리에 아래 파일들이 포함되어 있다:

| 파일 | 복사 위치 | 설명 |
|---|---|---|
| `templates/CLAUDE.md` | `{KB_ROOT}/CLAUDE.md` | 스키마 정의서 (핵심 태그, 문서 타입, 컨벤션) |
| `templates/index/` | `{KB_ROOT}/wiki/index/` | 인덱스 디렉토리 (overview + 서브 인덱스) |
| `templates/log.md` | `{KB_ROOT}/wiki/log.md` | 시간순 로그 |
| `templates/.gitignore` | `{KB_ROOT}/.gitignore` | git 제외 규칙 |

## Step 0. 대상 디렉토리 확인

사용자에게 볼트를 생성할 디렉토리를 물어본다:

> "Knowledge Base 볼트를 생성할 경로를 알려주세요. (예: ~/workspace/knowledge-base)"

- 사용자가 경로를 지정하면 해당 경로 사용
- 디렉토리가 이미 존재하면 그대로 사용 (기존 파일 보존)
- 디렉토리가 없으면 생성

이후 모든 경로는 `{KB_ROOT}`로 표기한다.

## Step 1. 디렉토리 구조 생성

아래 디렉토리를 모두 생성한다. 이미 존재하면 건너뛴다.

```
{KB_ROOT}/
├── raw/
│   ├── web/
│   ├── pdfs/
│   ├── images/
│   ├── notes/
│   └── assets/
├── wiki/
│   ├── concepts/
│   ├── sources/
│   └── archive/
└── secrets/
```

```bash
mkdir -p {KB_ROOT}/{raw/{web,pdfs,images,notes,assets},wiki/{concepts,sources,archive},secrets}
```

## Step 2. 템플릿 파일 복사

이 스킬의 `templates/` 디렉토리에서 아래 파일들을 복사한다.
대상에 이미 파일이 있으면 덮어쓰지 않고 사용자에게 확인을 받는다.

- `templates/CLAUDE.md` → `{KB_ROOT}/CLAUDE.md`
- `templates/index/` → `{KB_ROOT}/wiki/index/` (overview.md, concepts-mobigen.md, concepts-personal.md, sources.md, answers.md)
- `templates/log.md` → `{KB_ROOT}/wiki/log.md`
- `templates/.gitignore` → `{KB_ROOT}/.gitignore`

## Step 3. 볼트 경로 저장

`~/.config/kb/config.json`에 볼트 경로를 저장한다. 다른 kb-* 스킬이 이 파일을 읽어 볼트 위치를 찾는다.

```json
{
  "kb_root": "{KB_ROOT의 절대 경로}"
}
```

이미 파일이 존재하면 `kb_root` 값을 업데이트한다.

## Step 4. Git 초기화

- `.git` 디렉토리가 이미 존재하면 건너뛴다
- 없으면 `git init` 실행
- 모든 파일을 스테이징하고 초기 커밋:

```bash
cd {KB_ROOT}
git add -A
git commit -m "kb: initial setup"
```

## Step 5. qmd 설치 확인

[tobi/qmd](https://github.com/tobi/qmd) — 로컬 마크다운 검색 엔진이 설치되어 있는지 확인한다:

```bash
which qmd
```

- 설치되어 있으면: 버전을 출력한다.
- 설치되어 있지 않으면: "qmd가 설치되어 있지 않습니다. https://github.com/tobi/qmd 를 참조하세요." 라고 안내한다.

## Step 6. Obsidian 설정 안내

사용자에게 아래 Obsidian 설정을 안내한다:
- **Settings → Files and links → Attachment folder path** → `raw/assets/`로 설정
- **Settings → Hotkeys → "Download attachments"** → 단축키 설정 (예: Ctrl+Shift+D)
- 웹 클리핑 후 단축키를 누르면 인라인 이미지가 `raw/assets/`에 로컬 저장된다

## Step 7. 완료 메시지

```
✅ Knowledge Base 볼트 초기 세팅이 완료되었습니다.
- 볼트 경로: {KB_ROOT}
- 디렉토리 구조 생성 완료
- CLAUDE.md 스키마 생성 완료
- Git 저장소 초기화 완료
- Obsidian에서 이 폴더를 볼트로 열어주세요.
```

오류가 발생한 단계가 있으면 해당 단계와 오류 내용을 함께 안내한다.
