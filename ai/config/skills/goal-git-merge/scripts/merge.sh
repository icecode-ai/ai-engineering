#!/usr/bin/env bash
# Merge mainline branch into current branch for MAIN, a module, a dependency, or ALL.
# Usage: merge.sh <target>   (target: ALL | MAIN | <module-name> | <dependency-name>)
# Mainline is detected per-repo (origin/HEAD -> main -> master -> main).
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

merge_one() {
  local label="$1" dir="$2"
  [ -d "$dir/.git" ] || { echo "=== $label: not a git repository, skip ==="; return; }
  echo "=== $label ==="
  (cd "$dir" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || {
    if [ -n "$(cd "$dir" && git diff --name-only --diff-filter=U 2>/dev/null)" ]; then
      echo "Merge conflicts in $label — will auto-resolve"
    else
      echo "Merge failed in $label — see output above"
    fi
  }
}

case "$target" in
  ALL)
    merge_one "MAIN" "$PROJECT_ROOT"
    for d in "${PROJECT_ROOT}/modules"/*/; do [ -d "$d" ] || continue; merge_one "Module: $(basename "$d")" "$d"; done
    for d in "${PROJECT_ROOT}/readonly-dependencies"/*/; do [ -d "$d" ] || continue; merge_one "Dependency: $(basename "$d")" "$d"; done
    ;;
  MAIN)
    merge_one "MAIN" "$PROJECT_ROOT"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      merge_one "Module: $target" "${PROJECT_ROOT}/modules/$target"
    elif [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
      merge_one "Dependency: $target" "${PROJECT_ROOT}/readonly-dependencies/$target"
    else
      echo "Target '$target' not found or is not a git repository"
      exit 1
    fi
    ;;
esac
