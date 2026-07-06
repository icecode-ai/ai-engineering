#!/usr/bin/env bash
# Materialize registered repos from ai/config/git.tsv (clone modules/dependencies at gitlink SHA).
# Skips gracefully when MAIN is not yet a git repo, or the registry is absent/empty.
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

registry="ai/config/git.tsv"
if [ ! -s "$registry" ] || ! awk -F'\t' '{if($1!="" && $1 !~ /^#/){f=1; exit}} END{exit !f}' "$registry" 2>/dev/null; then
  echo "No ai/config/git.tsv (missing or empty) — skip materialization."
  exit 0
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "MAIN not a git repo yet — skip materialization."
  exit 0
fi

while IFS=$'\t' read -r path url branch; do
  case "$path" in ''|\#*) continue;; esac
  if [ -e "$path" ] && [ -n "$(ls -A "$path" 2>/dev/null)" ]; then
    echo "skip (populated): $path"
    continue
  fi
  mkdir -p "$path"
  sha="$(git ls-tree HEAD -- "$path" 2>/dev/null | awk '$2=="commit"{print $3}' || true)"
  if [ -n "$sha" ]; then
    if git clone "$url" "$path" && git -C "$path" checkout -B "$branch" "$sha"; then
      echo "materialized (branch $branch @ $sha): $path"
    else
      echo "FAILED: $path — check url/branch/sha"
    fi
  else
    if git clone --branch "$branch" "$url" "$path"; then
      echo "materialized (branch $branch @ tip): $path"
    else
      echo "FAILED: $path — check url/branch"
    fi
  fi
done < "$registry"
