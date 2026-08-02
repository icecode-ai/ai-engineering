#!/usr/bin/env bash
# Validate task IDs in tasks.md: pure numeric, globally unique, contiguous from 1.
# This is the deterministic gate that stops /ai-spec-propose from emitting IDs the
# /ai-spec-apply scripts cannot parse (A1, B1, 1.1, gaps, duplicates).
# Fence-aware (skips ``` regions) so example "### Task N:" headers in code blocks
# are not mistaken for real tasks.
#
# Usage: validate-tasks.sh <tasks-file>
# Exit 0 = valid; Exit 1 = invalid (prints issues to stderr).
set -euo pipefail
tasks_file="${1:-}"
if [ -z "$tasks_file" ]; then
  echo "Usage: validate-tasks.sh <tasks-file>" >&2
  exit 1
fi
[ -f "$tasks_file" ] || { echo "tasks-file not found: $tasks_file" >&2; exit 1; }

# Fence-aware extraction: the token after "### Task " up to the first ":".
ids="$(awk '
  BEGIN { infence=0 }
  /^```/ { infence=!infence; next }
  infence { next }
  /^### Task / {
    line = $0
    sub(/^### Task /, "", line)
    sub(/:.*$/, "", line)
    gsub(/[[:space:]]/, "", line)
    if (line != "") print line
  }
' "$tasks_file")" || true

if [ -z "$ids" ]; then
  echo "✗ No tasks found in $tasks_file (expected at least one '### Task N:' header)" >&2
  exit 1
fi

# 1. Pure numeric — reject A1, B1, 1.1, etc.
bad="$(printf '%s\n' "$ids" | grep -vE '^[0-9]+$' || true)"
if [ -n "$bad" ]; then
  echo "✗ Non-numeric task IDs — IDs must be pure integers (e.g. ### Task 1:), never A1/B1/1.1:" >&2
  printf '%s\n' "$bad" | sed 's/^/    - /' >&2
  echo "  The '## N. <Group>' headings are visual only; numbering continues across all groups." >&2
  exit 1
fi

# 2. No duplicates.
total=$(printf '%s\n' "$ids" | grep -c .)
unique=$(printf '%s\n' "$ids" | sort -u | grep -c .)
if [ "$total" -ne "$unique" ]; then
  echo "✗ Duplicate task IDs ($total headers, $unique unique):" >&2
  printf '%s\n' "$ids" | sort | uniq -d | sed 's/^/    - /' >&2
  exit 1
fi

# 3. Contiguous from 1.
count="$unique"
max=$(printf '%s\n' "$ids" | sort -n | tail -1)
if [ "$count" -ne "$max" ] || [ "$max" -lt 1 ]; then
  echo "✗ Task IDs are not contiguous from 1 (found $count ids, max=$max):" >&2
  printf '%s\n' "$ids" | sort -n | sed 's/^/    - /' >&2
  echo "  Renumber so IDs are 1..$count with no gaps." >&2
  exit 1
fi

echo "✓ Task IDs valid: 1..$count ($count tasks)"
