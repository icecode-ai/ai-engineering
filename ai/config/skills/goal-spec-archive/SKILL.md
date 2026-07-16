---
name: goal-spec-archive
description: Archive a completed change
argument-hint: [<change-name>]
disable-model-invocation: true
---

Archive a completed change. Moves the change directory into the archive to keep the active changes list clean.

**Input**: Optionally specify a change name after `/ai-spec-archive` (e.g., `/ai-spec-archive add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. If no change name provided, prompt for selection

```bash
bash "ai/config/skills/goal-spec-archive/scripts/list-changes.sh"
```

Use the **AskUserQuestion tool** to let the user select.

**IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

### 2. Check artifact + task completion status

```bash
bash "ai/config/skills/goal-spec-archive/scripts/check-completion.sh" "$name"
```

If the last line is `INCOMPLETE` (some artifacts missing or tasks pending), display the warnings and prompt the user: "Archive anyway?" Proceed if the user confirms.

### 3. Sync delta specs to main specs (if delta specs exist)

Before archiving, check if the change has delta specs that need to be synced to the main specs directory. Delta specs contain ADDED/MODIFIED/REMOVED/RENAMED requirement sections that need to be merged into the corresponding main spec files.

```bash
bash "ai/config/skills/goal-spec-archive/scripts/assess-delta-specs.sh" "$name"
```

**If delta specs exist**, for each delta spec — **validate first, then merge atomically**:

**3a. Validate each delta** (stop and report on any error — do NOT merge a malformed delta into the source-of-truth main spec):
1. Read the delta spec file (`$change_dir/specs/<capability>/spec.md`) and the corresponding main spec (`ai/output/specs/<capability>/spec.md`) if it exists.
2. **New-capability rule**: if the main spec does NOT exist, the delta may contain ONLY `## ADDED Requirements`. Any `## MODIFIED` / `## REMOVED` / `## RENAMED` against a non-existent spec is an error — report it and stop.
3. **Reference checks**: every requirement named under `## MODIFIED` / `## REMOVED` / `## RENAMED` (the `FROM:` name) MUST exist in the current main spec. If any is missing, report the mismatch and stop.
4. **REMOVED completeness**: each `## REMOVED Requirements` entry MUST include both **Reason** and **Migration**.
5. **MODIFIED scenario-drop guard**: if the main spec's requirement has scenarios that the MODIFIED block omits, surface this explicitly ("N scenarios will be dropped") and confirm with the user before proceeding — silent scenario loss is the most common merge mistake.

**Ask the user** whether to sync before archiving. Options: "Sync now (recommended)", "Archive without syncing". If the user chose "Archive without syncing", skip 3b entirely and proceed to step 4. If the user chose "Sync now", proceed to 3b — validation (3a) is mandatory and must not be skipped.

**3b. Build all merged specs before writing any** (atomicity — an interrupt must not leave main specs half-merged):
1. For each capability, construct the FULL merged main spec in memory (or a temp string) by applying operations in order: **RENAMED → REMOVED → MODIFIED → ADDED**. (RENAMED first so later sections reference the new name; REMOVED before ADDED so a re-add is allowed.)
2. Only after EVERY capability's merged spec is built successfully, write them all to `ai/output/specs/<capability>/spec.md` (use the **Write tool**; it creates parent dirs as needed).
3. If any capability fails to build, write NONE of them — report the failure and leave all main specs unchanged.

### 4. Perform the archive

```bash
bash "ai/config/skills/goal-spec-archive/scripts/perform-archive.sh" "$name"
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
