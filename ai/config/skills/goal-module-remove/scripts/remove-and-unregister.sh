#!/usr/bin/env bash
# Remove a module from modules/ and unregister it from ai/config/git.tsv.
# Usage: remove-and-unregister.sh <module-name>
# Exits 1 if the name is invalid or the module directory is not found.
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: remove-and-unregister.sh <module-name>"; exit 1; }
case "$name" in ..|*..*|/*) echo "Invalid module name '$name'"; exit 1;; esac

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

if [ ! -d "${PROJECT_ROOT}/modules/$name" ]; then
  echo "Module '$name' not found"
  exit 1
fi
rm -rf "${PROJECT_ROOT}/modules/$name"

# remove from ai/config/git.tsv
git_tsv="${PROJECT_ROOT}/ai/config/git.tsv"
if [ -f "$git_tsv" ] && awk -F'\t' -v p="modules/$name" '$1==p {found=1} END{exit !found}' "$git_tsv"; then
  tmp="$(mktemp)"
  awk -F'\t' -v p="modules/$name" '$1!=p' "$git_tsv" > "$tmp" && mv "$tmp" "$git_tsv"
  echo "Removed modules/$name from ai/config/git.tsv"
fi
