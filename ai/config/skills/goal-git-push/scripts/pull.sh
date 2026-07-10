#!/usr/bin/env bash
# Pull latest git content for MAIN + modules only (push scope; readonly-dependencies are never pulled).
# Usage: pull.sh <target>   (target: ALL | MAIN | <module-name>)
# Printout is per-repo; conflicts (unmerged paths) print an auto-resolve line,
# other pull failures print a "see output above" line.
set -euo pipefail
target="${1:-ALL}"

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

pull_one() {
  local label="$1" dir="$2"
  [ -d "$dir/.git" ] || { echo "=== $label: not a git repository, skip ==="; return; }
  echo "=== $label ==="
  (cd "$dir" && git pull 2>&1) || {
    if [ -n "$(cd "$dir" && git diff --name-only --diff-filter=U 2>/dev/null)" ]; then
      echo "Pull conflicts in $label — will auto-resolve"
    else
      echo "Pull failed in $label — see output above"
    fi
  }
}

case "$target" in
  ALL)
    for d in "${PROJECT_ROOT}/modules"/*/; do
      [ -d "$d" ] || continue
      pull_one "Module: $(basename "$d")" "$d"
    done
    pull_one "MAIN" "$PROJECT_ROOT"
    ;;
  MAIN)
    pull_one "MAIN" "$PROJECT_ROOT"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      pull_one "Module: $target" "${PROJECT_ROOT}/modules/$target"
    else
      echo "Target '$target' not found or is not a git repository"
      exit 1
    fi
    ;;
esac
