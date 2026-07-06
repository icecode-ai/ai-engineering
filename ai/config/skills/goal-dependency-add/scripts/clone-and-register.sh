#!/usr/bin/env bash
# Clone a dependency into readonly-dependencies/ and register it in ai/config/git.tsv.
# Usage: clone-and-register.sh <git-url> [<branch>]
# Exits 1 with an EXISTS: message if the dependency dir already exists and is non-empty.
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

dep_name="$(basename "$url" .git)"
dep_dir="${PROJECT_ROOT}/readonly-dependencies/$dep_name"
# An empty directory is treated as non-existent
if [ -d "$dep_dir" ] && [ -n "$(ls -A "$dep_dir" 2>/dev/null)" ]; then
  echo "EXISTS: Dependency '$dep_name' already exists and is non-empty."
  echo "PATH: $dep_dir"
  echo "ACTION_REQUIRED: Ask the user whether to delete and re-add."
  echo "If confirmed, run: rm -rf \"$dep_dir\" then re-run this script."
  echo "If declined, abort."
  exit 1
fi
if [ -n "$branch" ]; then
  git clone --branch "$branch" "$url" "$dep_dir" || { echo "CLONE_FAILED: $url"; exit 1; }
else
  git clone "$url" "$dep_dir" || { echo "CLONE_FAILED: $url"; exit 1; }
fi

# register in ai/config/git.tsv (path<TAB>url<TAB>branch)
branch="$(git -C "$dep_dir" rev-parse --abbrev-ref HEAD)"
git_tsv="${PROJECT_ROOT}/ai/config/git.tsv"
[ -f "$git_tsv" ] || printf '# path\turl\tbranch\n' > "$git_tsv"
if awk -F'\t' -v p="readonly-dependencies/$dep_name" '$1==p {found=1} END{exit !found}' "$git_tsv"; then
  echo "Already registered in ai/config/git.tsv"
else
  printf '%s\t%s\t%s\n' "readonly-dependencies/$dep_name" "$url" "$branch" >> "$git_tsv"
  echo "Registered readonly-dependencies/$dep_name in ai/config/git.tsv"
fi
