#!/usr/bin/env bash
# Scan workspace entries (modules, dependencies, rules) to drive guidance-file tables.
# Emits: PROJECT:<name>, M:<module>|<path>|<guidance>, D:<dep>|<path>, R:<rule>|<path>
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

echo "PROJECT:$(basename "$PROJECT_ROOT")"
for d in "${PROJECT_ROOT}/modules"/*/; do
  [ -d "$d" ] || continue
  gfs=""
  [ -f "${d}AGENTS.md" ] && gfs="AGENTS.md"
  [ -f "${d}CLAUDE.md" ] && gfs="${gfs:+$gfs + }CLAUDE.md"
  [ -z "$gfs" ] && gfs="AGENTS.md + CLAUDE.md"
  echo "M:$(basename "$d")|modules/$(basename "$d")|modules/$(basename "$d")/$gfs"
done
for d in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
  [ -d "$d" ] || continue
  echo "D:$(basename "$d")|readonly-dependencies/$(basename "$d")"
done
for f in "${PROJECT_ROOT}/ai/config/rules"/*; do
  [ -f "$f" ] || continue
  echo "R:$(basename "$f")|ai/config/rules/$(basename "$f")"
done
