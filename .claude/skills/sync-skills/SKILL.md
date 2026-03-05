---
name: sync-skills
description: Git 리포지토리(AI-Practice-Archive)의 skills/, skills-archived/ 스킬을 각 AI 도구 디렉터리에 복사하여 동기화. 전체 동기화 및 단건 동기화 모두 지원. (1) 새 스킬을 만든 후 각 AI 도구에 연결할 때, (2) "스킬 동기화", "sync skills", "link skills" 요청 시, (3) 스킬 삭제 후 잔여 디렉터리 정리 시, (4) "prompt-master 스킬 싱크해줘", "sync prompt-master" 같은 특정 스킬 단건 동기화 요청 시 사용.
---

# Skill Copy Sync

Git 리포지토리의 `skills/`, `skills-archived/` 디렉터리에 있는 스킬을 아래 3개 AI 도구 경로에 복사하여 동기화한다.

| 소스 경로 | 용도 |
|-----------|------|
| `<repo>/skills/` | 활성 스킬 |
| `<repo>/skills-archived/` | 보관 스킬 |

| 대상 경로 | AI 도구 |
|-----------|---------|
| `~/.claude/skills/` | Claude Code |
| `~/.gemini/skills/` | Gemini |
| `~/.gemini/antigravity/skills/` | Gemini Antigravity |

## 사용법

```bash
# 전체 동기화
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh

# 특정 스킬만 단건 동기화
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --skill prompt-master

# 미리보기 (실제 변경 없음)
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --dry-run

# 단건 미리보기
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --skill prompt-master --dry-run

# 삭제된 스킬의 고아 디렉터리도 정리
bash <repo>/.claude/skills/sync-skills/scripts/sync-skills.sh --remove-orphans
```

## 동작 규칙

1. `skills/`, `skills-archived/` 하위 디렉터리만 스킬로 인식 (파일 무시)
2. 동일 폴더명이 이미 존재하면 덮어쓰기 (rm -rf 후 cp -R)
3. `--remove-orphans`: 리포지토리에서 삭제된 스킬의 디렉터리 제거 (`.sync-source` 마커가 있는 경우만)
4. `--skill <name>`: 지정한 스킬만 동기화 (소스에 없으면 에러 종료)
5. 리포지토리 루트는 스크립트 위치에서 자동 감지
