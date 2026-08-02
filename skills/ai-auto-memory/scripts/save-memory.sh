#!/usr/bin/env bash
# Prepare a memory file under ai/output/memories/ and print its target path.
#
# Usage: save-memory.sh "<title>" [bad-case|experience]
#
# What it does:
#   1. Locates the project root (nearest ancestor containing an ai/ directory).
#   2. Ensures ai/output/memories/ exists.
#   3. Lists existing memories to stderr so the caller can spot duplicates.
#   4. Builds a date-prefixed, slug-based filename (collision-safe).
#   5. Prints the absolute target path to stdout. It does NOT write content —
#      the caller writes the memory body with its native Write tool.
set -euo pipefail

title="${1:-}"
mem_type="${2:-experience}"

if [ -z "$title" ]; then
  echo "Usage: save-memory.sh \"<title>\" [bad-case|experience]" >&2
  exit 1
fi

# Locate project root: nearest ancestor containing an ai/ directory.
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -d "$PROJECT_ROOT/ai" ]; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

MEMORIES_DIR="${PROJECT_ROOT}/ai/output/memories"
mkdir -p "$MEMORIES_DIR"

# Surface existing memories so the caller can avoid duplicates. If a memory
# already covers this lesson, the caller should UPDATE it rather than create
# a near-duplicate.
existing="$(ls -1 "$MEMORIES_DIR"/*.md 2>/dev/null || true)"
if [ -n "$existing" ]; then
  echo "Existing memories (update one of these instead of duplicating if it covers the same lesson):" >&2
  printf '%s\n' "$existing" >&2
else
  echo "No existing memories yet." >&2
fi

# Slugify the title: lowercase, collapse non-alphanumerics to single hyphens,
# trim leading/trailing hyphens. LC_ALL=C makes [^a-z0-9] match byte-wise so
# multi-byte scripts (CJK, etc.) collapse cleanly. Portable across BSD/GNU sed
# (uses [^a-z0-9][^a-z0-9]* instead of the GNU-only \+ ).
slug="$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | LC_ALL=C sed 's/[^a-z0-9][^a-z0-9]*/-/g' \
  | sed 's/^-//; s/-$//')"

# Fall back when the title contained no ASCII alphanumerics (e.g. pure CJK).
if [ -z "$slug" ]; then
  slug="memory-$(date +%s)"
fi

date_prefix="$(date +%Y-%m-%d)"
filepath="${MEMORIES_DIR}/${date_prefix}-${slug}.md"

# Avoid clobbering an existing file: append -2, -3, ...
n=2
while [ -f "$filepath" ]; do
  filepath="${MEMORIES_DIR}/${date_prefix}-${slug}-${n}.md"
  n=$((n + 1))
done

echo "$filepath"
