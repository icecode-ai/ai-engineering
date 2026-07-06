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
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
      branch="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
      branch="master"
    else
      branch="main"
    fi
  fi
  echo "$branch"
}

# pull_one <dir> <name>: git pull in <dir>; conflicts (unmerged paths) are auto-resolvable.
pull_one() {
  local dir="$1" name="$2"
  (cd "$dir" && git pull 2>&1) || {
    if [ -n "$(cd "$dir" && git diff --name-only --diff-filter=U 2>/dev/null)" ]; then
      echo "Pull conflicts in $name — will auto-resolve"
    else
      echo "Pull failed in $name — see output above"
    fi
  }
}

# merge_one <dir> <name>: merge mainline in <dir>; conflicts (unmerged paths) are auto-resolvable.
merge_one() {
  local dir="$1" name="$2"
  (cd "$dir" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || {
    if [ -n "$(cd "$dir" && git diff --name-only --diff-filter=U 2>/dev/null)" ]; then
      echo "Merge conflicts in $name — will auto-resolve"
    else
      echo "Merge failed in $name — see output above"
    fi
  }
}

# Pull modules
if [ "$target" = "ALL" ]; then
  for dir in "${PROJECT_ROOT}/modules"/*/; do
    [ -d "$dir/.git" ] || continue
    echo "=== Pull module: $(basename "$dir") ==="
    pull_one "$dir" "module $(basename "$dir")"
  done
elif [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
  echo "=== Pull module: $target ==="
  pull_one "${PROJECT_ROOT}/modules/$target" "module $target"
fi

# Merge mainline into modules
if [ "$target" = "ALL" ]; then
  for dir in "${PROJECT_ROOT}/modules"/*/; do
    [ -d "$dir/.git" ] || continue
    echo "=== Merge mainline into module: $(basename "$dir") ==="
    merge_one "$dir" "module $(basename "$dir")"
  done
elif [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
  echo "=== Merge mainline into module: $target ==="
  merge_one "${PROJECT_ROOT}/modules/$target" "module $target"
fi

# Pull + merge MAIN
if [ "$target" = "MAIN" ] || [ "$target" = "ALL" ]; then
  echo "=== Pull MAIN ==="
  pull_one "$PROJECT_ROOT" "MAIN"
  echo "=== Merge mainline into MAIN ==="
  merge_one "$PROJECT_ROOT" "MAIN"
fi
