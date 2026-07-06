#!/usr/bin/env bash
# Clone a module into modules/ and register it in ai/config/git.tsv.
# Usage: clone-and-register.sh <git-url> [<branch>]
# Exits 1 with an EXISTS: message if the module dir already exists and is non-empty.
set -euo pipefail
url="${1:-}"
branch="${2:-}"
[ -z "$url" ] && { echo "Usage: clone-and-register.sh <git-url> [<branch>]"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

module_name="$(basename "$url" .git)"
module_dir="${PROJECT_ROOT}/modules/$module_name"
# An empty directory is treated as non-existent
if [ -d "$module_dir" ] && [ -n "$(ls -A "$module_dir" 2>/dev/null)" ]; then
  echo "EXISTS: Module '$module_name' already exists and is non-empty."
  echo "PATH: $module_dir"
  echo "ACTION_REQUIRED: Ask the user whether to delete and re-add."
  echo "If confirmed, run: rm -rf \"$module_dir\" then re-run this script."
  echo "If declined, abort."
  exit 1
fi
if [ -n "$branch" ]; then
  git clone --branch "$branch" "$url" "$module_dir" || { echo "CLONE_FAILED: $url"; exit 1; }
else
  git clone "$url" "$module_dir" || { echo "CLONE_FAILED: $url"; exit 1; }
fi

# register in ai/config/git.tsv (path<TAB>url<TAB>branch)
branch="$(git -C "$module_dir" rev-parse --abbrev-ref HEAD)"
git_tsv="${PROJECT_ROOT}/ai/config/git.tsv"
[ -f "$git_tsv" ] || printf '# path\turl\tbranch\n' > "$git_tsv"
if awk -F'\t' -v p="modules/$module_name" '$1==p {found=1} END{exit !found}' "$git_tsv"; then
  echo "Already registered in ai/config/git.tsv"
else
  printf '%s\t%s\t%s\n' "modules/$module_name" "$url" "$branch" >> "$git_tsv"
  echo "Registered modules/$module_name in ai/config/git.tsv"
fi
