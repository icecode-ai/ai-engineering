#!/usr/bin/env bash
# Create the standard ai-engineering directory structure and configure .gitignore.
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

DIRS=(
  "ai"
  "ai/config"
  "ai/config/rules"
  "ai/config/skills"
  "ai/input"
  "ai/input/common"
  "ai/input/common/references"
  "ai/input/jim"
  "ai/input/jim/0"
  "ai/input/jim/1"
  "ai/output/changes"
  "ai/output/changes/archive"
  "ai/output/memories"
  "ai/output/specs"
  "modules"
  "readonly-dependencies"
)
for dir in "${DIRS[@]}"; do
  target="${PROJECT_ROOT}/${dir}"
  if [ ! -d "$target" ]; then
    mkdir -p "$target"
    echo "Created: ${dir}/"
  else
    echo "Exists: ${dir}/"
  fi
done

gitignore_file="${PROJECT_ROOT}/.gitignore"
entry="readonly-dependencies/*/*"
if [ ! -f "$gitignore_file" ]; then
  printf '%s\n' "$entry" > "$gitignore_file"
  echo "Created .gitignore with readonly-dependencies entry"
elif ! grep -qF "$entry" "$gitignore_file"; then
  printf '%s\n' "$entry" >> "$gitignore_file"
  echo "Added '${entry}' to .gitignore"
else
  echo "'${entry}' already in .gitignore"
fi

echo "Environment initialized at: ${PROJECT_ROOT}"
