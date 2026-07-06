#!/usr/bin/env bash
# Pull latest git content for MAIN, a module, a dependency, or ALL.
# Usage: pull.sh <target>   (target: ALL | MAIN | <module-name> | <dependency-name>)
# Printout is per-repo; pull failures print a "conflicts detected" line for auto-resolution.
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
  (cd "$dir" && git pull 2>&1) || echo "Pull failed for $label, conflicts detected — will auto-resolve"
}

case "$target" in
  ALL)
    pull_one "MAIN" "$PROJECT_ROOT"
    for d in "${PROJECT_ROOT}/modules"/*/; do
      [ -d "$d" ] || continue
      pull_one "Module: $(basename "$d")" "$d"
    done
    for d in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
      [ -d "$d" ] || continue
      pull_one "Dependency: $(basename "$d")" "$d"
    done
    ;;
  MAIN)
    pull_one "MAIN" "$PROJECT_ROOT"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      pull_one "Module: $target" "${PROJECT_ROOT}/modules/$target"
    elif [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
      pull_one "Dependency: $target" "${PROJECT_ROOT}/readonly-dependencies/$target"
    else
      echo "Target '$target' not found or is not a git repository"
      exit 1
    fi
    ;;
esac
