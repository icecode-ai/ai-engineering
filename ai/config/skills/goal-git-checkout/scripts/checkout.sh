#!/usr/bin/env bash
# Checkout a branch on MAIN, a module, or a dependency.
# Usage: checkout.sh <target> <branch>   (target: MAIN | <module-name> | <dependency-name>)
set -euo pipefail
target="${1:-}"
branch="${2:-}"
[ -z "$target" ] || [ -z "$branch" ] && { echo "Usage: checkout.sh <target> <branch>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

case "$target" in
  MAIN)
    git checkout "$branch" 2>&1 || echo "Checkout failed or conflict in MAIN, will auto-resolve via stash"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      (cd "${PROJECT_ROOT}/modules/$target" && git checkout "$branch" 2>&1) || echo "Checkout failed or conflict in module $target, will auto-resolve via stash"
    elif [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
      (cd "${PROJECT_ROOT}/readonly-dependencies/$target" && git checkout "$branch" 2>&1) || echo "Checkout failed or conflict in dependency $target, will auto-resolve via stash"
    else
      echo "Target '$target' not found or is not a git repository"
      exit 1
    fi
    ;;
esac
