#!/usr/bin/env bash
# sync-skills.sh — Git 리포지토리의 스킬을 각 AI 도구 디렉터리에 복사
#
# Usage:
#   ./sync-skills.sh [--dry-run] [--remove-orphans]
#
# Options:
#   --dry-run         실제 복사를 하지 않고 변경 예정 사항만 출력
#   --remove-orphans  소스에 없는 스킬 디렉터리 제거

set -euo pipefail

# 리포지토리 루트 자동 감지 (스크립트 위치 기준)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

SKILL_SOURCES=(
  "$REPO_ROOT/skills"
  "$REPO_ROOT/skills-archived"
)

TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.gemini/skills"
  "$HOME/.gemini/antigravity/skills"
)

DRY_RUN=false
REMOVE_ORPHANS=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --remove-orphans) REMOVE_ORPHANS=true ;;
  esac
done

created=0
skipped=0
orphaned=0

# 동기화 대상 스킬 폴더명 수집 (고아 검사용)
ALL_SKILLS=""

echo "=== Skill Copy Sync ==="
echo "Repo: $REPO_ROOT"
for src in "${SKILL_SOURCES[@]}"; do
  echo "Source: $src"
done
echo ""

# 스킬 복사
for source_dir in "${SKILL_SOURCES[@]}"; do
  [ -d "$source_dir" ] || continue

  for skill_path in "$source_dir"/*/; do
    [ -d "$skill_path" ] || continue
    skill=$(basename "$skill_path")
    ALL_SKILLS="$ALL_SKILLS $skill"

    for target_dir in "${TARGETS[@]}"; do
      dest_path="$target_dir/$skill"

      # 대상 디렉터리가 없으면 생성
      if [ ! -d "$target_dir" ]; then
        if $DRY_RUN; then
          echo "  [DRY-RUN] mkdir -p $target_dir"
        else
          mkdir -p "$target_dir"
        fi
      fi

      # 복사 (이미 존재하면 덮어쓰기)
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
