#!/usr/bin/env bash
# List git branches (local + remote heads) in a target repository.
# Usage: list-branches.sh <target_repo>
#   <target_repo> — path relative to workspace root: ".", "modules/<name>", "readonly-dependencies/<name>"
set -euo pipefail
repo="${1:-}"
[ -n "$repo" ] || { echo "Usage: list-branches.sh <target_repo>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

target="${PROJECT_ROOT}/${repo}"
if [ ! -d "$target/.git" ] && [ ! -f "$target/.git" ]; then
  echo "(unable to list branches)"
  exit 0
fi

{
  git -C "$target" branch --format='%(refname:short)' 2>/dev/null || true
  git -C "$target" ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||' || true
} | sort -u
