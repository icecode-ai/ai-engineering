#!/usr/bin/env bash
# Update the branch field in ai/config/git.tsv for a module/dependency target.
# Usage: sync-registry.sh <target> <branch>   (MAIN has no registry entry; no-op for MAIN)
set -euo pipefail
target="${1:-}"
branch="${2:-}"

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

git_tsv="ai/config/git.tsv"
path=""
if [ -n "${target:-}" ] && [ -d "modules/${target:-}/.git" ]; then path="modules/$target"
elif [ -n "${target:-}" ] && [ -d "readonly-dependencies/${target:-}/.git" ]; then path="readonly-dependencies/$target"
fi
if [ -n "$path" ] && [ -n "${branch:-}" ] && [ -f "$git_tsv" ]; then
  tmp="$(mktemp)"
  awk -F'\t' -v OFS='\t' -v p="$path" -v b="$branch" '$1==p {$3=b} {print}' "$git_tsv" > "$tmp" && mv "$tmp" "$git_tsv"
  echo "Updated $path branch → $branch in ai/config/git.tsv"
fi
