#!/usr/bin/env bash
# sync-skills.sh — Git 리포지토리의 스킬을 각 AI 도구 디렉터리에 복사
#
# Usage:
#   ./sync-skills.sh --claude [--gemini] [--antigravity] [--dry-run] [--remove-orphans] [--skill <name>] [--source <path>]
#
# Options:
#   --claude          Claude Code (~/.claude/skills/)에 동기화
#   --gemini          Gemini (~/.gemini/skills/)에 동기화
#   --antigravity     Gemini Antigravity (~/.gemini/antigravity/skills/)에 동기화
#   --dry-run         실제 복사를 하지 않고 변경 예정 사항만 출력
#   --remove-orphans  소스에 없는 스킬 디렉터리 제거
#   --skill <name>    특정 스킬만 동기화 (예: --skill prompt-master)
#   --source <path>   skills/, skills-archived/ 이외의 스킬 경로 지정 (예: --source /path/to/create-monolith-demo)
#
# 대상(--claude/--gemini/--antigravity) 미지정 시 에러 종료

set -euo pipefail

# 리포지토리 루트 자동 감지 (스크립트 위치 기준)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

SKILL_SOURCES=(
  "$REPO_ROOT/skills"
  "$REPO_ROOT/skills-archived"
)

DRY_RUN=false
REMOVE_ORPHANS=false
SINGLE_SKILL=""
EXTERNAL_SOURCE=""
TARGET_CLAUDE=false
TARGET_GEMINI=false
TARGET_ANTIGRAVITY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) TARGET_CLAUDE=true; shift ;;
    --gemini) TARGET_GEMINI=true; shift ;;
    --antigravity) TARGET_ANTIGRAVITY=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --remove-orphans) REMOVE_ORPHANS=true; shift ;;
    --skill) SINGLE_SKILL="$2"; shift 2 ;;
    --source) EXTERNAL_SOURCE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# 대상 미지정 시 에러 종료
if ! $TARGET_CLAUDE && ! $TARGET_GEMINI && ! $TARGET_ANTIGRAVITY; then
  echo "ERROR: 동기화 대상을 하나 이상 지정하세요."
  echo ""
  echo "  --claude        Claude Code (~/.claude/skills/)"
  echo "  --gemini        Gemini (~/.gemini/skills/)"
  echo "  --antigravity   Gemini Antigravity (~/.gemini/antigravity/skills/)"
  echo ""
  echo "예시: $0 --claude --gemini"
  exit 1
fi

# 선택된 대상만 TARGETS 배열에 추가
TARGETS=()
$TARGET_CLAUDE && TARGETS+=("$HOME/.claude/skills")
$TARGET_GEMINI && TARGETS+=("$HOME/.gemini/skills")
$TARGET_ANTIGRAVITY && TARGETS+=("$HOME/.gemini/antigravity/skills")

created=0
skipped=0
orphaned=0

# 동기화 대상 스킬 폴더명 수집 (고아 검사용)
ALL_SKILLS=""

echo "=== Skill Copy Sync ==="
echo "Repo: $REPO_ROOT"
echo "Targets:"
for t in "${TARGETS[@]}"; do
  echo "  - $t"
done

# 외부 소스 모드
if [ -n "$EXTERNAL_SOURCE" ]; then
  # 절대/상대 경로 모두 지원
  source_path="$(cd "$(dirname "$EXTERNAL_SOURCE")" && pwd)/$(basename "$EXTERNAL_SOURCE")"
  if [ ! -d "$source_path" ]; then
    echo "  ERROR: '$EXTERNAL_SOURCE' 디렉터리를 찾을 수 없습니다."
    exit 1
  fi
  skill_name=$(basename "$source_path")
  echo "Mode: external source ($source_path)"
  echo ""

  for target_dir in "${TARGETS[@]}"; do
    dest_path="$target_dir/$skill_name"
    if [ ! -d "$target_dir" ]; then
      if $DRY_RUN; then
        echo "  [DRY-RUN] mkdir -p $target_dir"
      else
        mkdir -p "$target_dir"
      fi
    fi
    if $DRY_RUN; then
      echo "  [DRY-RUN] COPY: $source_path -> $dest_path"
    else
      rm -rf "$dest_path"
      cp -R "$source_path" "$dest_path"
      echo "  COPIED: $dest_path"
    fi
    created=$((created + 1))
  done

elif [ -n "$SINGLE_SKILL" ]; then
  echo "Mode: single skill ($SINGLE_SKILL)"
  for src in "${SKILL_SOURCES[@]}"; do
    echo "Source: $src"
  done
  echo ""

  # 단건 모드: 소스에서 해당 스킬 찾기
  found=false
  for source_dir in "${SKILL_SOURCES[@]}"; do
    skill_path="$source_dir/$SINGLE_SKILL"
    [ -d "$skill_path" ] || continue
    found=true

    for target_dir in "${TARGETS[@]}"; do
      dest_path="$target_dir/$SINGLE_SKILL"
      if [ ! -d "$target_dir" ]; then
        if $DRY_RUN; then
          echo "  [DRY-RUN] mkdir -p $target_dir"
        else
          mkdir -p "$target_dir"
        fi
      fi
      if $DRY_RUN; then
        echo "  [DRY-RUN] COPY: $skill_path -> $dest_path"
      else
        rm -rf "$dest_path"
        cp -R "$skill_path" "$dest_path"
        echo "  COPIED: $dest_path"
      fi
      created=$((created + 1))
    done
    break
  done
  if ! $found; then
    echo "  ERROR: '$SINGLE_SKILL' not found in any source directory"
    exit 1
  fi
else
  echo "Mode: all skills"
  for src in "${SKILL_SOURCES[@]}"; do
    echo "Source: $src"
  done
  echo ""

  # 전체 동기화
  for source_dir in "${SKILL_SOURCES[@]}"; do
    [ -d "$source_dir" ] || continue

    for skill_path in "$source_dir"/*/; do
      [ -d "$skill_path" ] || continue
      skill=$(basename "$skill_path")
      ALL_SKILLS="$ALL_SKILLS $skill"

      for target_dir in "${TARGETS[@]}"; do
        dest_path="$target_dir/$skill"

        if [ ! -d "$target_dir" ]; then
          if $DRY_RUN; then
            echo "  [DRY-RUN] mkdir -p $target_dir"
          else
            mkdir -p "$target_dir"
          fi
        fi

        if $DRY_RUN; then
          echo "  [DRY-RUN] COPY: $source_dir/$skill -> $dest_path"
        else
          rm -rf "$dest_path"
          cp -R "$source_dir/$skill" "$dest_path"
          echo "  COPIED: $dest_path"
        fi
        created=$((created + 1))
      done
    done
  done
fi

# 고아 디렉터리 정리 (--remove-orphans)
if $REMOVE_ORPHANS; then
  echo ""
  echo "--- Orphan Check ---"
  for target_dir in "${TARGETS[@]}"; do
    [ -d "$target_dir" ] || continue
    for entry in "$target_dir"/*/; do
      [ -d "$entry" ] || continue
      name=$(basename "$entry")

      # 이 스크립트가 동기화하는 스킬 목록에 없으면 고아
      if ! echo "$ALL_SKILLS" | grep -qw "$name"; then
        # .sync-source 마커가 있는 경우만 정리 (수동 설치한 스킬은 보존)
        if [ -f "$entry/.sync-source" ]; then
          if $DRY_RUN; then
            echo "  [DRY-RUN] REMOVE ORPHAN: $entry"
          else
            rm -rf "$entry"
            echo "  REMOVED ORPHAN: $entry"
          fi
          orphaned=$((orphaned + 1))
        fi
      fi
    done
  done
fi

echo ""
echo "=== Summary ==="
echo "  Copied:          $created"
echo "  Orphans removed: $orphaned"
echo "  Done."
