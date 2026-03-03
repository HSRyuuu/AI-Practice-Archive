#!/bin/bash
# sync-skills.sh — Git 리포지토리의 스킬을 각 AI 도구 디렉터리에 심볼릭 링크
#
# Usage:
#   ./sync-skills.sh [--dry-run] [--remove-orphans]
#
# Options:
#   --dry-run         실제 링크를 생성하지 않고 변경 예정 사항만 출력
#   --remove-orphans  소스에 없는 심볼릭 링크 제거

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
  "$HOME/.agents/skills"
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

echo "=== Skill Symlink Sync ==="
echo "Repo: $REPO_ROOT"
for src in "${SKILL_SOURCES[@]}"; do
  echo "Source: $src"
done
echo ""

# 심볼릭 링크 생성
for source_dir in "${SKILL_SOURCES[@]}"; do
  [ -d "$source_dir" ] || continue

  for skill_path in "$source_dir"/*/; do
    [ -d "$skill_path" ] || continue
    skill=$(basename "$skill_path")

    for target_dir in "${TARGETS[@]}"; do
      link_path="$target_dir/$skill"

      # 대상 디렉터리가 없으면 생성
      if [ ! -d "$target_dir" ]; then
        if $DRY_RUN; then
          echo "  [DRY-RUN] mkdir -p $target_dir"
        else
          mkdir -p "$target_dir"
        fi
      fi

      # 이미 올바른 심볼릭 링크면 스킵
      if [ -L "$link_path" ]; then
        existing_target=$(readlink "$link_path")
        expected="$source_dir/$skill"
        if [ "$existing_target" = "$expected" ]; then
          skipped=$((skipped + 1))
          continue
        else
          # 다른 곳을 가리키는 심볼릭 링크 — 업데이트
          if $DRY_RUN; then
            echo "  [DRY-RUN] UPDATE: $link_path -> $expected (was: $existing_target)"
          else
            rm "$link_path"
            ln -s "$expected" "$link_path"
            echo "  UPDATED: $link_path"
          fi
          created=$((created + 1))
          continue
        fi
      fi

      # 심볼릭 링크가 아닌 디렉터리/파일이 이미 존재하면 스킵
      if [ -e "$link_path" ]; then
        echo "  SKIP (not a symlink): $link_path"
        skipped=$((skipped + 1))
        continue
      fi

      # 새 심볼릭 링크 생성
      if $DRY_RUN; then
        echo "  [DRY-RUN] CREATE: $link_path -> $source_dir/$skill"
      else
        ln -s "$source_dir/$skill" "$link_path"
        echo "  CREATED: $link_path"
      fi
      created=$((created + 1))
    done
  done
done

# 고아 심볼릭 링크 정리 (--remove-orphans)
if $REMOVE_ORPHANS; then
  echo ""
  echo "--- Orphan Check ---"
  for target_dir in "${TARGETS[@]}"; do
    [ -d "$target_dir" ] || continue
    for link in "$target_dir"/*; do
      [ -L "$link" ] || continue
      target=$(readlink "$link")
      # 이 리포지토리를 가리키는 링크만 검사
      if [[ "$target" == "$REPO_ROOT/"* ]]; then
        if [ ! -d "$target" ]; then
          if $DRY_RUN; then
            echo "  [DRY-RUN] REMOVE ORPHAN: $link (source deleted)"
          else
            rm "$link"
            echo "  REMOVED ORPHAN: $link"
          fi
          orphaned=$((orphaned + 1))
        fi
      fi
    done
  done
fi

echo ""
echo "=== Summary ==="
echo "  Created/Updated: $created"
echo "  Already synced:  $skipped"
[ $orphaned -gt 0 ] && echo "  Orphans removed: $orphaned"
echo "  Done."
