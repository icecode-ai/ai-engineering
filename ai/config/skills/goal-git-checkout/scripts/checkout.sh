#!/usr/bin/env bash
# Checkout a branch on MAIN, a module, or a dependency.
# Usage: checkout.sh <target> <branch>   (target: MAIN | <module-name> | <dependency-name>)
set -euo pipefail
target="${1:-}"
branch="${2:-}"
{ [ -z "$target" ] || [ -z "$branch" ]; } && { echo "Usage: checkout.sh <target> <branch>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

# checkout_one <label> <dir>: checkout $branch in <dir>, classify failure.
# If the branch exists but checkout failed, local changes are blocking it
# (auto-resolvable via stash). Otherwise the branch does not exist (stop).
checkout_one() {
  local label="$1" dir="$2"
  (cd "$dir" && git checkout "$branch" 2>&1) || {
    if (cd "$dir" && { git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; }); then
      echo "Checkout blocked in $label by local changes — will auto-resolve via stash"
    else
      echo "Checkout failed in $label — branch '$branch' not found"
    fi
  }
}

case "$target" in
  MAIN)
    checkout_one "MAIN" "$PROJECT_ROOT"
    ;;
  *)
    if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
      checkout_one "module $target" "${PROJECT_ROOT}/modules/$target"
    elif [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
      checkout_one "dependency $target" "${PROJECT_ROOT}/readonly-dependencies/$target"
    else
      echo "Target '$target' not found or is not a git repository"
      exit 1
    fi
    ;;
esac
