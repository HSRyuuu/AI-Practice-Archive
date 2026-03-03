# AI-Practice-Archive

AI 코딩 어시스턴트용 프롬프트와 스킬을 중앙에서 관리하고, 여러 AI 도구에 자동 동기화하는 저장소.

핵심 워크플로우: **스킬 작성 → 이 저장소에 커밋 → `sync-skills`로 4개 AI 도구에 심볼릭 링크 동기화**

## 동기화 대상 AI 도구

| AI 도구 | 동기화 경로 |
|---------|------------|
| Claude Code | `~/.claude/skills/` |
| Agents | `~/.agents/skills/` |
| Gemini | `~/.gemini/skills/` |
| Gemini Antigravity | `~/.gemini/antigravity/skills/` |

## 폴더 구조

| 폴더 | 설명 | 상세 |
|------|------|------|
| `skills/` | 활성 스킬 모음 | [skills/README.md](skills/README.md) |
| `skills-archived/` | 보관된 스킬 (동기화 대상이지만 비활성) | — |
| `skills-optional/` | 선택적 스킬 | — |
| `skills-project-depends/` | 프로젝트 의존 스킬 (프로젝트별 적용) | — |
| `project-initializers/` | 프로젝트 초기 설정 템플릿 | — |
| `prompt/` | 범용 프롬프트 모음 | — |

## 주요 기능

### 스킬 동기화 (`sync-skills`)

`skills/`와 `skills-archived/` 하위 스킬을 심볼릭 링크로 4개 AI 도구 경로에 자동 동기화한다.

```bash
# 동기화 실행
bash .claude/skills/sync-skills/scripts/sync-skills.sh

# 미리보기 (실제 변경 없음)
bash .claude/skills/sync-skills/scripts/sync-skills.sh --dry-run

# 삭제된 스킬의 고아 링크 정리
bash .claude/skills/sync-skills/scripts/sync-skills.sh --remove-orphans
```

### 스킬 관리

각 스킬은 `SKILL.md`를 포함하는 디렉토리 단위로 구성되며, 도메인별 베스트 프랙티스와 가이드라인을 제공한다. 스킬 생성/수정/삭제는 `manage-skill` 스킬 또는 직접 파일 편집으로 수행한다.

### 프로젝트 초기화 템플릿

`project-initializers/`에 프로젝트 초기 설정을 위한 템플릿을 관리한다. 새 프로젝트 시작 시 참조용으로 사용.
