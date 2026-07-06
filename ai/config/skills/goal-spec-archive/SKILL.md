---
name: goal-spec-archive
description: Archive a completed change
argument-hint: [<change-name>]
disable-model-invocation: true
---

Archive a completed change. Moves the change directory into the archive to keep the active changes list clean.

**Input**: Optionally specify a change name after `/ai-spec-archive` (e.g., `/ai-spec-archive add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

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
```

## Steps

### 1. If no change name provided, prompt for selection

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-archive/scripts/list-changes.sh"
```

Use the **AskUserQuestion tool** to let the user select.

**IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

### 2. Check artifact + task completion status

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-archive/scripts/check-completion.sh" "$name"
```

If the last line is `INCOMPLETE` (some artifacts missing or tasks pending), display the warnings and prompt the user: "Archive anyway?" Proceed if the user confirms.

### 3. Sync delta specs to main specs (if delta specs exist)

Before archiving, check if the change has delta specs that need to be synced to the main specs directory. Delta specs contain ADDED/MODIFIED/REMOVED/RENAMED requirement sections that need to be merged into the corresponding main spec files.

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-archive/scripts/assess-delta-specs.sh" "$name"
```

**If delta specs exist**, for each delta spec:
1. Read the delta spec file (`$change_dir/specs/<capability>/spec.md`)
2. Parse the delta sections: `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements`
3. Read the corresponding main spec (`ai/output/specs/<capability>/spec.md`) if it exists
4. Apply the delta operations in order: RENAMED → REMOVED → MODIFIED → ADDED
5. Write the updated main spec to `ai/output/specs/<capability>/spec.md`

**Ask the user** whether to sync before archiving. Options: "Sync now (recommended)", "Archive without syncing". Proceed to archive regardless of choice.

### 4. Perform the archive

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-archive/scripts/perform-archive.sh" "$name"
```

If the script prints `EXISTS:`, the target archive directory already exists — present the options (rename existing / delete duplicate / wait) and let the user resolve before retrying.

### 5. Display summary

```
## Archive Complete

**Change:** <change-name>
**Archived to:** ai/output/changes/archive/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs" / "Sync skipped")
```

If there were warnings:

```
## Archive Complete (with warnings)

**Change:** <change-name>
**Archived to:** ai/output/changes/archive/YYYY-MM-DD-<name>/
**Specs:** Synced / Sync skipped / No delta specs

**Warnings:**
- Archived with incomplete artifacts
- Archived with N incomplete tasks
- Delta spec sync was skipped (user chose to skip)

Review the archive if this was not intentional.
```

## Guardrails
- Always prompt for change selection if not provided
- Don't block archive on warnings — just inform and confirm
- Preserve `.spec.yaml` when archiving (it moves with the directory)
- Show clear summary of what happened
- If delta specs exist, always run the sync assessment and show the summary before prompting
