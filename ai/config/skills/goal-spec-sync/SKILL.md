---
name: goal-spec-sync
description: Sync specs and memories from the main project to related modules
argument-hint: [<change-name>]
disable-model-invocation: true
---

Sync specification and memory content from the main project's `ai/` directory to the corresponding locations in each module.

**Input**: Optional change name. If provided, only sync specs related to that change. If omitted, sync all specs.

## Resolve PROJECT_ROOT

All script paths below are resolved from `PROJECT_ROOT` — the directory containing both `ai/` and `modules/`:

```bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

change_name="${1:-}"
```

## Steps

### 1. Discover specs, modules, and memories

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-sync/scripts/discover.sh" "$change_name"
```

### 2. Sync specs to modules

For each spec, read its content to determine which module(s) it relates to, then read the existing target files to decide merge vs. replace vs. skip. Perform a targeted copy for each confirmed mapping:

```bash
# $capability = spec name; $module = target module (both determined by AI from spec content)
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-sync/scripts/sync-spec.sh" "$capability" "$module"
```

### 3. Sync memories to modules

For each memory, read its content to determine which module(s) it relates to, then read the existing target files to decide merge vs. replace vs. skip. Perform a targeted copy for each confirmed mapping:

```bash
# $memory_name and $module determined by AI from memory content
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-sync/scripts/sync-memory.sh" "$memory_name" "$module"
```

### 4. Verify sync results

```
=== Sync Complete ===
Specs synced to module ai/output/specs/ directories
Memories synced to module ai/output/memories/ directories
```

## Guardrails
- Only sync content that is relevant to each module — AI should determine if content belongs in an existing file (update) or as a new file
- Do NOT overwrite existing module-specific content without confirmation
- Read the existing files in the target module directory before syncing to decide merge vs replace vs skip
