#!/usr/bin/env bash
# Pull latest and merge mainline into current branch for modules + MAIN (push scope only).
# Usage: pull-and-merge.sh <target>   (target: ALL | MAIN | <module-name>)
# Dependencies are never pulled/merged here (read-only).
set -euo pipefail
target="${1:-ALL}"
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

detect_mainline() {
  local branch
  branch=$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | cut -d/ -f2) || branch=""
  if [ -z "$branch" ]; then
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then branch="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then branch="master"
    else branch="main"; fi
  fi
  echo "$branch"
}

# Pull modules
if [ "$target" = "ALL" ]; then
  for dir in "${PROJECT_ROOT}/modules"/*/; do
    [ -d "$dir/.git" ] || continue
    echo "=== Pull module: $(basename "$dir") ==="
    (cd "$dir" && git pull 2>&1) || echo "Pull conflicts in $(basename "$dir") — will auto-resolve"
  done
elif [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
  echo "=== Pull module: $target ==="
  (cd "${PROJECT_ROOT}/modules/$target" && git pull 2>&1) || echo "Pull conflicts in $target — will auto-resolve"
fi

# Merge mainline into modules
if [ "$target" = "ALL" ]; then
  for dir in "${PROJECT_ROOT}/modules"/*/; do
    [ -d "$dir/.git" ] || continue
    echo "=== Merge mainline into module: $(basename "$dir") ==="
    (cd "$dir" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge conflicts in $(basename "$dir") — will auto-resolve"
  done
elif [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
  echo "=== Merge mainline into module: $target ==="
  (cd "${PROJECT_ROOT}/modules/$target" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge conflicts in $target — will auto-resolve"
fi

# Pull + merge MAIN
if [ "$target" = "MAIN" ] || [ "$target" = "ALL" ]; then
  echo "=== Pull MAIN ==="
  git pull 2>&1 || echo "Pull conflicts in MAIN — will auto-resolve"
  echo "=== Merge mainline into MAIN ==="
  mainline=$(detect_mainline)
  git merge "$mainline" 2>&1 || echo "Merge conflicts in MAIN — will auto-resolve"
fi
