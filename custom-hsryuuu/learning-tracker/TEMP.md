# Learning Logger - 전체 흐름 분석

## 개요

Claude Code 세션이 종료될 때마다 **Stop Hook**이 트리거되어, 대화 내용을 자동 분석하고 사용자가 모를 만한 IT 개념/기술을 추출하여 학습 로그로 저장하는 시스템.

---

## 1. 트리거: Stop Hook (settings.json)

**파일**: `~/.claude/settings.json`

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/learning_logger.py"
          }
        ]
      }
    ]
  }
}
```

- `matcher`가 빈 문자열 → **모든 Stop 이벤트**에서 실행됨
- Claude Code 세션이 종료(Stop)될 때마다 `learning_logger.py`가 호출됨
- Hook은 stdin으로 `{ "session_id": "...", "cwd": "..." }` 형태의 JSON을 전달받음

---

## 2. 진입점: learning_logger.py

**파일**: `~/.claude/hooks/learning_logger.py`

### 역할
Stop Hook의 진입점. **백그라운드로 분석 프로세스를 실행한 뒤 즉시 종료**한다. (Hook이 오래 걸리면 Claude Code 종료가 지연되므로)

### 흐름

```
Stop Hook 발동
    │
    ▼
learning_logger.py 실행
    │
    ├─ 환경변수 CLAUDE_LEARNING_HOOK 체크
    │   └─ 설정되어 있으면 → sys.exit(0) (무한 루프 방지)
    │
    ├─ stdin에서 JSON 파싱 → session_id, cwd 추출
    │   └─ 둘 중 하나라도 없으면 → sys.exit(0)
    │
    └─ subprocess.Popen으로 analyze_session.py를 백그라운드 실행
        ├─ 인자: session_id, cwd
        ├─ stdout/stderr → DEVNULL (출력 무시)
        └─ start_new_session=True (부모 프로세스와 완전 분리)
```

### 무한 루프 방지 메커니즘

`analyze_session.py`가 내부적으로 `claude -p` (Claude CLI)를 호출하는데, 이 CLI 세션이 끝나면 또 Stop Hook이 발동된다. 이를 방지하기 위해:

1. `analyze_session.py`에서 `claude -p` 실행 시 환경변수 `CLAUDE_LEARNING_HOOK=1`을 설정
2. `learning_logger.py`가 실행될 때 이 환경변수가 있으면 즉시 종료

---

## 3. 핵심 로직: analyze_session.py

**파일**: `~/.claude/hooks/analyze_session.py`

### 전체 파이프라인

```
analyze_session.py (session_id, cwd)
    │
    ▼
[Step 1] 세션 JSONL 파일 찾기
    │   ~/.claude/projects/{project_name}/{session_id}.jsonl
    │
    ▼
[Step 2] 대화 내용 추출 (최근 20개 메시지, 각 1000자 제한)
    │
    ▼
[Step 3] 사용자 지식 프로필 로드 (~/knowledge/know/*.md)
    │
    ▼
[Step 4] Claude CLI로 대화 분석 (claude -p)
    │   → "사용자가 모를 것 같은 IT 개념" 추출
    │
    ▼
[Step 5] ~/knowledge/logs/에 마크다운으로 저장
```

---

### Step 1: 세션 파일 찾기 (`get_session_file`)

```python
PROJECTS_DIR = ~/.claude/projects/
```

- cwd를 프로젝트 디렉토리명으로 변환
  - 예: `/Users/happyhsryu/my-project` → `-Users-happyhsryu-my-project`
- 경로: `~/.claude/projects/{project_name}/{session_id}.jsonl`
- 파일이 존재하지 않으면 종료

---

### Step 2: 대화 내용 추출 (`extract_conversation`)

세션 JSONL 파일을 파싱하여 대화를 텍스트로 변환:

- **User 메시지**: `type == 'user'` → `[USER]: {content}`
- **Assistant 메시지**: `role == 'assistant'` 중 `type == 'text'` → `[ASSISTANT]: {text}`
- 각 메시지 **1000자로 제한**
- **최근 20개 메시지만** 사용 (컨텍스트 윈도우 절약)
- 전체 대화가 100자 미만이면 스킵 (너무 짧은 세션)

---

### Step 3: 사용자 지식 프로필 로드 (`load_user_knowledge`)

```
~/knowledge/know/
    ├── README.md              # 전체 지식 수준 요약
    ├── backend-java-spring.md # Java/Spring Expert~Beginner 레벨 정리
    ├── frontend-vue-nuxt.md   # Vue/Nuxt Intermediate 레벨 정리
    └── devops-basics.md       # DevOps Beginner 레벨 정리
```

이 디렉토리의 모든 `.md` 파일을 읽어서 하나의 문자열로 합침. Claude가 분석할 때 "사용자가 이미 아는 것"을 판단하는 기준으로 사용됨.

**예시 (README.md):**
```
## Backend - Java/Spring: Expert
## Frontend - Vue.js/Nuxt.js: Intermediate
## DevOps: Beginner
```

---

### Step 4: Claude CLI로 분석 (`analyze_with_claude`)

`claude -p` 명령어로 Claude를 비대화형(pipe) 모드로 호출:

```bash
CLAUDE_LEARNING_HOOK=1 claude -p "<프롬프트>" --output-format text
```

#### 프롬프트 구조

```
당신은 IT 학습 컨설턴트입니다.

사용자의 현재 지식 수준:
{user_knowledge}          ← ~/knowledge/know/*.md 내용

대화 내용:
{conversation}            ← 세션에서 추출한 최근 20개 메시지

위 대화에서 사용자가 모를 것 같은 IT 개념/기술을 추출하세요.
```

#### 기대 출력 (JSON)

```json
{
  "items": [
    {
      "tech_name": "Docker",           // 대분류 기술명 (영문, 한 단어)
      "title": "Docker buildx와 멀티 플랫폼 빌드",
      "category": "devops",            // backend/frontend/devops/cs/etc
      "difficulty": "intermediate",    // beginner/intermediate/advanced
      "summary": "1-2줄 요약",
      "context": "대화에서 언급된 맥락"
    }
  ]
}
```

#### 주요 조건
- 사용자가 **이미 잘 아는 내용은 제외** (know/ 프로필 참조)
- IT 기술/개념/패턴/도구만 포함 (일반 대화 제외)
- `tech_name`은 **한 단어 대분류**로 통합 (go-bufio → Go, docker-compose → Docker)
- 타임아웃: 120초

---

### Step 5: 학습 로그 저장 (`save_to_logs`)

```
~/knowledge/logs/
    ├── 2026-01-26-docker.md
    ├── 2026-01-26-python.md
    └── 2026-01-26-symlink.md
```

#### 파일명 규칙
```
{YYYY-MM-DD}-{tech_name(소문자, 특수문자 제거)}.md
```

#### 파일 구조 (새 파일 생성 시)

```markdown
# {title}

- **카테고리**: {category}
- **난이도**: {difficulty}

---
```

#### 섹션 추가 (기존 파일에 append)

```markdown
## 2026-01-26 15:31
{summary}

**맥락**: {context}
```

같은 날 같은 기술에 대해 여러 세션에서 학습 항목이 나오면, **같은 파일에 시간별 섹션이 누적**됨.

---

## 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Code 세션 종료                          │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Stop Hook 발동
                           ▼
              ┌─────────────────────────┐
              │   learning_logger.py    │
              │   (진입점, 즉시 종료)     │
              │                         │
              │ • CLAUDE_LEARNING_HOOK  │
              │   환경변수 체크 → 루프방지 │
              │ • stdin → session_id,   │
              │   cwd 파싱              │
              │ • 백그라운드 프로세스 생성  │
              └───────────┬─────────────┘
                          │ subprocess.Popen (분리된 프로세스)
                          ▼
              ┌─────────────────────────┐
              │   analyze_session.py    │
              │   (핵심 분석 로직)        │
              └───────────┬─────────────┘
                          │
          ┌───────────────┼───────────────────┐
          ▼               ▼                   ▼
   ┌─────────────┐ ┌───────────────┐  ┌──────────────┐
   │  세션 JSONL   │ │ 지식 프로필     │  │   Claude CLI  │
   │  파일 읽기    │ │  로드          │  │   분석 호출    │
   │              │ │               │  │              │
   │ ~/.claude/   │ │ ~/knowledge/  │  │ claude -p    │
   │ projects/    │ │ know/*.md     │  │ (HOOK=1)     │
   │ {proj}/      │ │               │  │              │
   │ {sid}.jsonl  │ │ - README.md   │  │ → JSON 결과   │
   │              │ │ - backend-    │  │   items[]    │
   │ → 최근 20개   │ │   java-spring │  │              │
   │   메시지 추출 │ │ - frontend-   │  │              │
   │              │ │   vue-nuxt    │  │              │
   │              │ │ - devops-     │  │              │
   │              │ │   basics      │  │              │
   └──────┬──────┘ └───────┬───────┘  └──────┬───────┘
          │                │                  │
          └────────────────┼──────────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │    ~/knowledge/logs/     │
              │                         │
              │ {date}-{tech}.md        │
              │ (append 방식 누적)       │
              │                         │
              │ 예:                      │
              │ 2026-01-26-docker.md    │
              │ 2026-01-26-python.md    │
              └─────────────────────────┘
```

---

## 디렉토리 구조 요약

```
~/.claude/
├── settings.json                    # Stop Hook 설정
└── hooks/
    ├── learning_logger.py           # Hook 진입점 (백그라운드 실행)
    └── analyze_session.py           # 핵심 분석 + 저장 로직

~/.claude/projects/
└── {-escaped-cwd}/
    └── {session_id}.jsonl           # Claude Code 세션 대화 기록 (읽기 전용)

~/knowledge/
├── know/                            # 사용자 지식 프로필 (수동 관리)
│   ├── README.md                    # 전체 요약
│   ├── backend-java-spring.md       # 분야별 상세 수준
│   ├── frontend-vue-nuxt.md
│   └── devops-basics.md
├── logs/                            # 학습 로그 (자동 생성, append)
│   ├── 2026-01-26-docker.md
│   ├── 2026-01-26-python.md
│   └── 2026-01-26-symlink.md
└── to-study/                        # (별도 시스템, 이 흐름과 직접 관련 없음)
    └── etc/
        └── *.md                     # 약 60개+ 학습 주제 파일
```

---

## 핵심 설계 포인트

| 항목 | 설계 |
|------|------|
| **비차단(Non-blocking)** | learning_logger.py는 백그라운드 프로세스 생성 후 즉시 종료 → Claude Code 종료 지연 없음 |
| **무한 루프 방지** | `CLAUDE_LEARNING_HOOK` 환경변수로 분석용 claude -p 세션의 Stop Hook 재귀 차단 |
| **프로세스 분리** | `start_new_session=True`로 부모 프로세스와 완전 분리, stdout/stderr DEVNULL |
| **지식 기반 필터링** | `~/knowledge/know/`의 프로필을 읽어 "이미 아는 것"은 분석 결과에서 제외 |
| **누적 기록** | 같은 날 같은 기술 → 동일 파일에 시간별 섹션 append |
| **대화 제한** | 최근 20개 메시지, 각 1000자 → 토큰 사용 최소화 |
| **에러 무시** | 모든 에러는 조용히 처리 (학습 로거가 Claude Code 사용에 영향 없도록) |
