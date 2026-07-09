---
name: goal-spec-apply
description: Implement tasks from a spec change via subagent-driven development with two-stage review
argument-hint: [<change-name>]
disable-model-invocation: true
---

Implement tasks from a spec change using **subagent-driven development**: a fresh implementer subagent per task, a two-stage review (spec compliance + code quality) after each, a broad final review, and a durable progress ledger. The controller never touches git — implementers write files to disk, the user stages and commits; TDD, code review, and verification are built in — no external skills required.

**Input**: Optionally specify a change name (e.g., `/ai-spec-apply add-auth`). If the change name is omitted, infer from context or prompt.

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. Select the change

Parse `$ARGUMENTS`: the change name is the first non-flag token. If a name is provided, use it. Otherwise:
- Infer from conversation context if the user mentioned a change
- Auto-select if only one active change exists:
  ```bash
  ls -1 "ai/output/changes/" 2>/dev/null | grep -v '^archive$'
  ```
- If ambiguous or multiple changes exist, use the **AskUserQuestion tool** to let the user select

Always announce: "Using change: <name>" and how to override (e.g., `/ai-spec-apply <other>`).

### 2. Check artifact status

Let `change_dir` = `ai/output/changes/$name` (use this path in all subsequent steps).

```bash
bash "ai/config/skills/goal-spec-apply/scripts/check-artifacts.sh" "$name"
```

### 3. Read context files

Read all existing artifact files for context:
- `$change_dir/proposal.md`
- `$change_dir/design.md`
- `$change_dir/tasks.md`
- Files under `$change_dir/specs/`

Extract the **Global Constraints** block from `tasks.md` — every task's reviewer needs it verbatim.

### 4. Resume check (durable progress ledger)

Read the progress ledger so you never re-dispatch a completed task (the single most expensive failure after compaction):

```bash
bash "ai/config/skills/goal-spec-apply/scripts/ledger.sh" init "$change_dir"
bash "ai/config/skills/goal-spec-apply/scripts/ledger.sh" read "$change_dir"
```

Tasks listed in the ledger as complete are DONE — do not re-dispatch them. Resume at the first task not marked complete. The ledger is a plain file on disk (`sdd/progress.md`), so it survives context compaction. It is NOT committed, so it will not survive `git clean -fdx` — avoid running that while a change is in progress, or back up `sdd/` first.

### 5. Show current progress

```bash
bash "ai/config/skills/goal-spec-apply/scripts/check-progress.sh" "$name"
```

### 6. Pre-flight plan review

Before dispatching Task 1, scan `tasks.md` once for conflicts: tasks that contradict each other or the Global Constraints, or anything the plan mandates that the review rubric treats as a defect. Present all findings to the user as one batched question (each finding beside the plan text that mandates it) before execution begins. If the scan is clean, proceed without comment.

### 7. Implement tasks (subagent-driven loop)

For each pending task (marked `- [ ]` in `tasks.md`, not already in the ledger), in dependency order:

#### 7a. Build the dispatch batch

Read the task's `**Parallelizable:**` flag and its `**Interfaces:**` (Consumes/Produces). **Implementers are always serial** — one implementer at a time. The controller is the sole git writer (see 7d); `Parallelizable` enables **pipeline** overlap of a task's review with the next implementer:

- **Serial** (default, `Parallelizable: no`, or the next task depends on a not-yet-done task): after recording a task's file list (7d) and generating its review package (7e), dispatch the task-reviewer alone; wait for its verdict before dispatching the next implementer.
- **Pipeline** (`Parallelizable: yes` AND the next pending task has no file overlap): after recording task N's file list and generating its review package, dispatch the task-reviewer(N) AND the next implementer(N+1) in ONE message (two Task tool calls). The reviewer reads a frozen review-package file, so it is safe to overlap with implementer N+1's writes. Never pipeline tasks that touch the same files.

#### 7b. Prepare each task's handoff files (do this before dispatching)

```bash
# Extract the task's full text to a brief file (single source of requirements)
bash "ai/config/skills/goal-spec-apply/scripts/task-brief.sh" "$change_dir/tasks.md" "$N" "$change_dir/sdd/task-$N-brief.md"
```

#### 7c. Dispatch the implementer subagent

Read `ai/config/skills/goal-spec-apply/references/implementer-prompt.md`, fill the `{{...}}` placeholders:
- `{{TASK_FIT}}` — one line on where this task fits in the project.
- `{{TASK_BRIEF_PATH}}` — `$change_dir/sdd/task-$N-brief.md` (introduce it as "read this first — it is your requirements, with exact values verbatim").
- `{{CROSS_TASK_INTERFACES}}` — exact signatures/decisions from earlier tasks this task consumes (from their Produces blocks).
- `{{AMBIGUITY_RESOLUTIONS}}` — your resolution of any ambiguity you noticed in the brief.
- `{{REPORT_PATH}}` — `$change_dir/sdd/task-$N-report.md`.

Dispatch via the **Task tool** with `subagent_type: "ai-spec-implementer"`. **Do NOT paste accumulated prior-task summaries** — a fresh subagent gets only its task brief, the interfaces, and the global constraints. The implementer does NOT commit or stage; it writes files to disk and returns the changed paths so the controller can generate a review package (see its report contract).

#### 7d. Handle implementer status + record changed files

The implementer returns one of: **DONE** / **DONE_WITH_CONCERNS** / **NEEDS_CONTEXT** / **BLOCKED**. The implementer writes files to disk and reports the changed paths — it does NOT commit or stage. The controller **never touches git** (no `add`, no `commit`). When the implementer reports DONE (or DONE_WITH_CONCERNS you accept), the controller records the file list for the review package.

Write the implementer's reported changed files (one path per line) to `$change_dir/sdd/task-$N-files.txt`:

```bash
# Controller fills in the implementer's reported paths, e.g.:
printf '%s\n' modules/foo/src/a.ts modules/foo/src/b.ts > "$change_dir/sdd/task-$N-files.txt"
```

- **DONE** → record file list (above), then proceed to 7e (review).
- **DONE_WITH_CONCERNS** → read the concerns; if about correctness/scope, address before proceeding; if observations, proceed to review.
- **NEEDS_CONTEXT** → provide the missing context and re-dispatch (same task). Do not proceed with partial work.
- **BLOCKED** → assess: context problem (add context, re-dispatch), task too large (split it), plan wrong (escalate to user). Never ignore an escalation or force a retry with no changes.

The review package (7e) diffs these files against each repo's HEAD (the pre-change baseline) — no staging or commits needed.

#### 7e. Two-stage task review

Generate the review package BEFORE dispatching the next implementer (so the package is frozen — a pipelined next implementer won't change it):

```bash
bash "ai/config/skills/goal-spec-apply/scripts/review-package.sh" "$change_dir/sdd/task-$N-files.txt" "$change_dir/sdd/task-$N-review.md"
```

The package diffs each reported file against its owning repo's HEAD (the pre-change baseline), grouped per repo — no commits needed. Read `ai/config/skills/goal-spec-apply/references/task-reviewer-prompt.md`, fill placeholders (`{{TASK_BRIEF_PATH}}`, `{{REPORT_PATH}}`, `{{REVIEW_PACKAGE_PATH}}`, `{{GLOBAL_CONSTRAINTS}}`, `{{SPECS_PATH}}` = `$change_dir/specs`), and dispatch via the Task tool (`subagent_type: "ai-spec-reviewer"`).

**Pipeline dispatch** (only if task N is `Parallelizable: yes` and the next pending task N+1 has no file overlap): dispatch the task-reviewer(N) AND the next implementer(N+1) (7c) in ONE message. The reviewer reads the frozen review-package file, so it is safe to overlap. When both return, process the verdict below and record N+1's files (7d). **Serial dispatch** (default): dispatch the task-reviewer alone and wait for its verdict before the next implementer.

The reviewer returns `SPEC: ✅/❌/⚠️` and `QUALITY: Approved/Issues`. Handle:
- **SPEC ✅ + QUALITY Approved** → mark complete (7f).
- **SPEC ❌ or Critical/Important issues** → dispatch a fix subagent (`subagent_type: "ai-spec-implementer"`) with all findings + the implementer contract (re-run covering tests, append fix report to the same `task-$N-report.md`); the controller records the fix's changed files (7d), then re-review (7e again). Do not move to the next task while Critical/Important issues are open.
- **⚠️ Cannot verify from diff** → you (the controller) resolve each yourself before marking complete; you hold the cross-task context the reviewer lacks. If a real gap, treat as failed spec review.
- **Minor findings** → record in the ledger; defer to the final review (step 8).

Never tell a reviewer what not to flag, or pre-rate a finding's severity in the dispatch.

#### 7f. Mark task complete + update ledger

```bash
# Mark all of task N's step checkboxes done (robust block detection — no manual line counting)
bash "ai/config/skills/goal-spec-apply/scripts/mark-task-done.sh" "$change_dir/tasks.md" "$N"

# Append to the durable ledger (plain file on disk — survives context compaction)
bash "ai/config/skills/goal-spec-apply/scripts/ledger.sh" append-task "$change_dir" "$N"
```

Do this in the same turn as the review passes. Then continue to the next pending task (7a).

### 8. Final whole-branch review

After ALL tasks are complete, dispatch ONE final code-reviewer subagent for the whole change:

```bash
# Gather every task's reported files into one list
cat "$change_dir"/sdd/task-*-files.txt | sort -u > "$change_dir/sdd/final-files.txt"
bash "ai/config/skills/goal-spec-apply/scripts/review-package.sh" "$change_dir/sdd/final-files.txt" "$change_dir/sdd/final-review.md"
```

Read `ai/config/skills/goal-spec-apply/references/code-reviewer-prompt.md`, fill placeholders (`{{REVIEW_PACKAGE_PATH}}`, `{{MINOR_FINDINGS}}` — the accumulated Minor findings from per-task reviews, `{{SPECS_PATH}}`, `{{DESIGN_PATH}}`), and dispatch via the Task tool (`subagent_type: "ai-spec-reviewer"`). If findings, dispatch **ONE fix subagent** (`subagent_type: "ai-spec-implementer"`) with the complete findings list (not one fixer per finding); the controller records the fix's changed files (7d). Re-verify affected tests after the fix.

### 9. Final verification

Run a final verification pass inline (no external skill): ensure the build passes, the full test suite runs clean, and no regressions were introduced. If issues are found, fix them and re-verify. Concretely:
- Run the project's build command (if any).
- Run the full test suite (all packages/modules touched by this change).
- Confirm no previously-passing tests now fail.
- If the change spans modules, verify each affected module independently.

### 10. On completion or pause, show status

```bash
bash "ai/config/skills/goal-spec-apply/scripts/check-progress.sh" "$name"
```

## Output During Implementation

```
## Implementing: <change-name> (subagent-driven)

[Task 3/7] <task description>
  ├─ implementer subagent → DONE → files recorded
  ├─ task reviewer → SPEC ✅, QUALITY Approved
  └─ ledger updated (task 3 marked complete)
[Task 4/7] <task description>
  ├─ implementer subagent → DONE → files recorded
  ├─ task reviewer → SPEC ❌ (Missing: progress reporting) → fix subagent → fix applied → re-review ✅
  └─ ledger updated
```

## Output On Completion

```
## Implementation Complete

**Change:** <change-name>
**Progress:** 7/7 tasks complete ✓
**Final review:** clean (or: N findings fixed)

### Completed This Session
- [x] Task 1 ... Task 7

All tasks complete! You can archive this change with /ai-spec-archive <name>.
```

## Output On Pause (Issue Encountered)

```
## Implementation Paused

**Change:** <change-name>
**Progress:** 4/7 tasks complete
**Ledger:** see ai/output/changes/<name>/sdd/progress.md

### Issue Encountered
<description — e.g., Task 5 implementer BLOCKED: ...>

**Options:**
1. <option 1>
2. <option 2>

What would you like to do?
```

## Guardrails
- **Subagent-driven**: dispatch a fresh implementer per task via the Task tool (`subagent_type: "ai-spec-implementer"`) and review via `ai-spec-reviewer`; never implement tasks in the controller session. Implementers are always serial (one at a time); `Parallelizable: yes` enables pipeline overlap of a task's reviewer with the next implementer, not concurrent implementers.
- **No git operations**: implementers, fixers, and the controller never touch git — no `add`, no `commit`, no `stash`. Implementers write files to disk and report changed paths. Review packages use read-only `git diff` (tracked files vs HEAD) and `git diff --no-index` (untracked files, shown in full), grouped per repo so nested module repos work. The user stages and commits to whatever branch is checked out in each repo.
- **Context isolation**: hand the implementer its task brief file + cross-task interfaces + ambiguity resolutions + report contract only. Never paste session history or prior-task summaries.
- **File handoff**: briefs, reports, and review packages move as files under `$change_dir/sdd/`, not pasted text.
- **Two-stage review**: every task gets a task-reviewer subagent (spec compliance + code quality) before marking complete. Critical/Important findings must be fixed and re-reviewed. Never skip the re-review.
- **Durable ledger**: append to `sdd/progress.md` (a plain file on disk) the moment a task's review passes; on resume, trust the ledger over your own recollection. It survives context compaction but NOT `git clean -fdx` (avoid that mid-change). Never re-dispatch a task the ledger marks complete.
- **TDD inline**: implementer subagents follow RED-GREEN-REFACTOR (per the implementer-prompt); classify each task Strict TDD / Exploratory / Visual. No external TDD skill.
- **No pre-judging reviewers**: never write "don't flag X" or "at most Minor" in a review dispatch.
- **Final review is broad**: one whole-branch reviewer, one consolidated fix subagent for its findings.
- **Verification inline**: final build + full suite + regression check happens here, no external verification skill.
- Keep going through tasks until done or blocked; pause on errors/blockers/unclear requirements — don't guess.
- If implementation reveals a design issue, pause and suggest updating artifacts (`/ai-spec-propose` or edit `design.md`/`tasks.md`).
- Update the task checkbox AND the ledger immediately after each task's review passes.
- No per-task model selection is performed (P3 intentionally not implemented).
