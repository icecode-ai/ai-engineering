#!/usr/bin/env bash
# List checkout targets across the workspace.
# Emits one line per target: MAIN | module:<name> | dependency:<name>
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

echo "MAIN"
for d in "${PROJECT_ROOT}/modules"/*/; do
  [ -d "$d" ] || continue
  echo "module:$(basename "$d")"
done
for d in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
  [ -d "$d" ] || continue
  echo "dependency:$(basename "$d")"
done
