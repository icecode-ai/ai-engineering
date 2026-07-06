#!/usr/bin/env bash
# Push local commits to remotes for modules + MAIN (modules before MAIN so gitlinks resolve).
# Usage: push.sh <target>   (target: ALL | MAIN | <module-name>)
# Never pushes readonly-dependencies (read-only).
set -euo pipefail
target="${1:-ALL}"
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

case "$target" in
  ALL)
    for dir in "${PROJECT_ROOT}/modules"/*/; do
      [ -d "$dir/.git" ] || continue
      echo "=== Module: $(basename "$dir") ==="
      (cd "$dir" && git push 2>&1) || echo "Push failed for $(basename "$dir")"
    done
    echo "=== MAIN ==="
    git push 2>&1 || echo "Push failed for MAIN"
    ;;
  MAIN)
    git push 2>&1 || echo "Push failed for MAIN"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      (cd "${PROJECT_ROOT}/modules/$target" && git push 2>&1) || echo "Push failed for module $target"
    else
      echo "Target '$target' not found, or push does not apply to read-only dependencies"
      exit 1
    fi
    ;;
esac
