---
name: sync-skills
description: Git 리포지토리(AI-Practice-Archive)의 skills/, skills-archived/ 스킬을 각 AI 도구 디렉터리에 복사하여 동기화. 전체 동기화 및 단건 동기화 모두 지원. (1) 새 스킬을 만든 후 각 AI 도구에 연결할 때, (2) "스킬 동기화", "sync skills", "link skills" 요청 시, (3) 스킬 삭제 후 잔여 디렉터리 정리 시, (4) "prompt-master 스킬 싱크해줘", "sync prompt-master" 같은 특정 스킬 단건 동기화 요청 시 사용.
---

# Skill Copy Sync

Git 리포지토리의 `skills/`, `skills-archived/` 디렉터리에 있는 스킬을 선택한 AI 도구 경로에 복사하여 동기화한다.

| 소스 경로 | 용도 |
|-----------|------|
| `<repo>/skills/` | 활성 스킬 |
| `<repo>/skills-archived/` | 보관 스킬 |

| 대상 플래그 | 대상 경로 | AI 도구 |
|-------------|-----------|---------|
| `--claude` | `~/.claude/skills/` | Claude Code |
| `--gemini` | `~/.gemini/skills/` | Gemini |
| `--antigravity` | `~/.gemini/antigravity/skills/` | Gemini Antigravity |

## 대상 선택 규칙

- **반드시 하나 이상의 대상 플래그를 지정해야 한다** (`--claude`, `--gemini`, `--antigravity`)
- 대상을 지정하지 않으면 사용자에게 어떤 대상에 동기화할지 되묻는다
- 여러 대상을 동시에 지정할 수 있다

## 사용법

```bash
# Claude만 전체 동기화
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --claude

# Claude + Gemini 전체 동기화
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --claude --gemini

# 특정 스킬만 단건 동기화 (Claude에만)
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --claude --skill prompt-master

# 외부 경로의 스킬을 수동 복제 (skills/, skills-archived/ 이외)
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --claude --source /path/to/create-monolith-demo

# 미리보기 (실제 변경 없음)
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --claude --gemini --dry-run

# 삭제된 스킬의 고아 디렉터리도 정리
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --claude --gemini --antigravity --remove-orphans
```

## 동작 규칙

1. `skills/`, `skills-archived/` 하위 디렉터리만 스킬로 인식 (파일 무시)
2. 동일 폴더명이 이미 존재하면 덮어쓰기 (rm -rf 후 cp -R)
3. `--remove-orphans`: 리포지토리에서 삭제된 스킬의 디렉터리 제거 (`.sync-source` 마커가 있는 경우만)
4. `--skill <name>`: 지정한 스킬만 동기화 (소스에 없으면 에러 종료)
5. `--source <path>`: `skills/`, `skills-archived/` 이외의 임의 경로에서 스킬을 복사 (덮어쓰기 방식)
6. 리포지토리 루트는 스크립트 위치에서 자동 감지
7. **대상 플래그 미지정 시 에러 종료** — 사용자에게 대상을 되물어야 한다

## 스킬 호출 시 동작 흐름

1. 사용자 요청에서 대상 플래그(`--claude`, `--gemini`, `--antigravity`)를 파싱한다
2. **대상이 지정되지 않았으면 사용자에게 되묻는다**: "어떤 대상에 동기화할까요? (claude / gemini / antigravity)"
3. 스크립트를 적절한 플래그와 함께 실행한다
