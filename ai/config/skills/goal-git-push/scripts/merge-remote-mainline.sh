#!/usr/bin/env bash
# Merge REMOTE mainline (origin/<mainline>) into current branch for MAIN + modules only
# (push scope; readonly-dependencies are never merged).
# Usage: merge-remote-mainline.sh <target>   (target: ALL | MAIN | <module-name>)
# Fetches origin, then merges origin/<mainline> (mainline detected per-repo:
# origin/HEAD -> origin/main -> origin/master -> main).
# Conflicts (unmerged paths) print an auto-resolve line; other merge failures print "see output above".
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
    if git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
      branch="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
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
  (cd "$dir" && git fetch origin 2>&1 && mainline=$(detect_mainline) && git merge "origin/$mainline" 2>&1) || {
    if [ -n "$(cd "$dir" && git diff --name-only --diff-filter=U 2>/dev/null)" ]; then
      echo "Merge conflicts in $label — will auto-resolve"
    else
      echo "Merge failed in $label — see output above"
    fi
  }
}

case "$target" in
  ALL)
    for d in "${PROJECT_ROOT}/modules"/*/; do
      [ -d "$d" ] || continue
      merge_one "Module: $(basename "$d")" "$d"
    done
    merge_one "MAIN" "$PROJECT_ROOT"
    ;;
  MAIN)
    merge_one "MAIN" "$PROJECT_ROOT"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      merge_one "Module: $target" "${PROJECT_ROOT}/modules/$target"
    else
      echo "Target '$target' not found or is not a git repository"
      exit 1
    fi
    ;;
esac
