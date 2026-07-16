---
name: goal-spec-apply
description: Implement tasks from a spec change via wave-parallel subagent-driven development with two-stage review
argument-hint: [<change-name>]
disable-model-invocation: true
---

Implement tasks from a spec change using **subagent-driven development with wave-based parallelism**: a fresh implementer subagent per task (independent tasks run concurrently within a wave), a two-stage review (spec compliance + code quality) after each, a broad final review, and a durable progress ledger. The controller never touches git — implementers write files to disk, the user stages and commits; TDD, code review, and verification are built in — no external skills required.

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

### 7. Implement tasks (wave-based parallel subagent-driven loop)

Dispatch independent implementers **concurrently within each wave**, review them concurrently, then repeat for the next wave. `Parallelizable: yes` tasks with no file overlap and satisfied dependencies run in parallel; `Parallelizable: no` tasks run alone. **Waves are sequential** — no cross-wave overlap (do not start the next wave's implementers until this wave's reviews finish). The parallelism comes from within-wave concurrent implementers + concurrent reviewers.

#### 7a. Build the ready set + form a parallel batch

Read the ledger (step 4) to know which tasks are complete. Compute the **ready set**: pending tasks (marked `- [ ]` in `tasks.md`, not in the ledger) whose `**Consumes:**` dependencies are ALL satisfied (every task they consume is complete in the ledger).

Form a **parallel batch** from the ready set:
- Candidates are tasks marked `**Parallelizable:** yes`.
- Extract each candidate's planned files (from its `**Files:**` block) — needed before dispatch, since actual files don't exist yet:
  ```bash
  bash "ai/config/skills/goal-spec-apply/scripts/planned-files.sh" "$change_dir/tasks.md" "$N" "$change_dir/sdd/task-$N-planned.txt"
  ```
- Greedily add a candidate only if its planned files have **NO OVERLAP** with the batch's accumulated planned files. Initialize `$change_dir/sdd/batch-planned.txt` empty, then for each candidate check it against the accumulated list:
  ```bash
  bash "ai/config/skills/goal-spec-apply/scripts/files-overlap.sh" "$change_dir/sdd/task-$N-planned.txt" "$change_dir/sdd/batch-planned.txt"
  ```
  If `NO OVERLAP`: add task N to the batch and append its planned files to `batch-planned.txt`. If `OVERLAP:`: skip it this wave (it may run later, once the overlapping task is done and its files are no longer in the way).
- **Batch ≥ 2 tasks** → parallel wave (7c, multiple Task calls in one message).
- **No batch possible** (only one ready task, or all ready tasks are `Parallelizable: no` / mutually overlapping) → dispatch the single highest-priority ready task alone (serial). A `Parallelizable: no` task always runs alone — it may share state or files with other tasks.

#### 7b. Prepare each task's handoff files (before dispatch)

For each task in the batch:

```bash
bash "ai/config/skills/goal-spec-apply/scripts/task-brief.sh" "$change_dir/tasks.md" "$N" "$change_dir/sdd/task-$N-brief.md"
```

#### 7c. Dispatch implementer subagent(s)

For each task, read `ai/config/skills/goal-spec-apply/references/implementer-prompt.md`, fill the `{{...}}` placeholders:
- `{{TASK_FIT}}` — one line on where this task fits in the project.
- `{{TASK_BRIEF_PATH}}` — `$change_dir/sdd/task-$N-brief.md` (introduce it as "read this first — it is your requirements, with exact values verbatim").
- `{{CROSS_TASK_INTERFACES}}` — exact signatures/decisions from earlier tasks this task consumes (from their Produces blocks).
- `{{AMBIGUITY_RESOLUTIONS}}` — your resolution of any ambiguity you noticed in the brief.
- `{{GLOBAL_CONSTRAINTS}}` — the Global Constraints block from `tasks.md` (extracted in step 3; every task implicitly includes it).
- `{{REPORT_PATH}}` — `$change_dir/sdd/task-$N-report.md`.

Dispatch via the **Task tool** with `subagent_type: "ai-spec-implementer"`.
- **Parallel batch**: dispatch ALL implementers in **ONE message** (multiple Task tool calls). Each is a fresh subagent with only its own brief + cross-task interfaces + global constraints — never paste session history or sibling-task summaries.
- **Single task**: one Task call.

The implementer does NOT commit or stage; it writes files to disk and returns the changed paths + status (see its report contract).

#### 7d. Handle implementer statuses + record changed files

When all implementers in the wave return, handle each one. The controller **never touches git** (no `add`, no `commit`). Extract each task's reported changed files (one path per line) — do not hand-transcribe, or a file may be silently dropped:

```bash
bash "ai/config/skills/goal-spec-apply/scripts/extract-files.sh" "$change_dir/sdd/task-$N-report.md" "$change_dir/sdd/task-$N-files.txt"
```

If the script exits `2` (no paths could be parsed from the report), read the report and fill `$change_dir/sdd/task-$N-files.txt` manually (one path per line) before proceeding — an empty file list means nothing gets reviewed.

- **DONE** → record file list, proceed to review (7e).
- **DONE_WITH_CONCERNS** → read the concerns; if about correctness/scope, address before proceeding; if observations, proceed to review.
- **NEEDS_CONTEXT** → provide the missing context and re-dispatch that task. Do not proceed with partial work.
- **BLOCKED** → assess: context problem (add context, re-dispatch), task too large (split it), plan wrong (escalate to user). Never ignore an escalation or force a retry with no changes.

The review package (7e) diffs these files against each repo's HEAD (the pre-change baseline) — no staging or commits needed.

#### 7e. Generate review packages + dispatch reviewers concurrently

For each completed task in the wave, generate its review package (frozen, before any review):

```bash
bash "ai/config/skills/goal-spec-apply/scripts/review-package.sh" "$change_dir/sdd/task-$N-files.txt" "$change_dir/sdd/task-$N-review.md"
```

The wave's tasks have disjoint file sets (verified in 7a), so each package diffs only that task's files vs HEAD — other concurrent tasks didn't touch them, so the package is clean.

Read `ai/config/skills/goal-spec-apply/references/task-reviewer-prompt.md`, fill placeholders (`{{TASK_BRIEF_PATH}}`, `{{REPORT_PATH}}`, `{{REVIEW_PACKAGE_PATH}}`, `{{GLOBAL_CONSTRAINTS}}`, `{{SPECS_PATH}}` = `$change_dir/specs`), and dispatch via the Task tool (`subagent_type: "ai-spec-reviewer"`). Dispatch ALL reviewers in **ONE message** (they're read-only, each reads its own frozen package — safe to run concurrently).

> **No-commit cumulative-diff note**: because implementers do not commit, `review-package.sh` diffs reported files against HEAD. For parallel-wave tasks this is clean (disjoint files, so a package shows only that task's changes). For `Parallelizable: no` tasks that share a file with an earlier not-yet-committed task, the package may include the earlier task's uncommitted changes too. To get a clean single-task diff in that case, commit between such tasks. The controller never auto-commits — the user stages and commits.

The reviewer returns `SPEC: ✅/❌/⚠️` and `QUALITY: Approved/Issues`. Handle:
- **SPEC ✅ + QUALITY Approved** → mark complete (7g).
- **SPEC ❌ or Critical/Important issues** → fix path (7f).
- **⚠️ Cannot verify from diff** → you (the controller) resolve each yourself before marking complete; you hold the cross-task context the reviewer lacks. If a real gap, treat as failed spec review.
- **Minor findings** → record in the ledger; defer to the final review (step 8).

Never tell a reviewer what not to flag, or pre-rate a finding's severity in the dispatch.

#### 7f. Fix path with overlap-based sibling discard

For each task that failed review (SPEC ❌ or Critical/Important issues), dispatch a fix subagent (`subagent_type: "ai-spec-implementer"`) with all findings + the implementer contract. Tell it to **read `ai/config/skills/goal-spec-apply/references/receiving-review.md` first** and follow its verify-then-fix process — it must verify each finding before fixing it, push back on wrong ones, and YAGNI-check "implement it properly" suggestions; it must NOT blindly implement every finding. The fixer re-runs covering tests and appends its fix report to the same `task-$N-report.md`; the controller records the fix's changed files (7d via `extract-files.sh`).

**Fix tasks serially** (one fix at a time) to keep the discard logic simple. After a fix, re-review that task (7e). Before re-reviewing task N, check whether N's fix files overlap any **sibling** task M in the same wave that already passed:

```bash
bash "ai/config/skills/goal-spec-apply/scripts/files-overlap.sh" "$change_dir/sdd/task-$N-files.txt" "$change_dir/sdd/task-$M-files.txt"
```

- **NO OVERLAP** → re-review task N. Sibling M is unaffected.
- **OVERLAP** → sibling M's output is now stale relative to N's fix — **discard M's output** (its files are inconsistent with the fix):
  1. For tracked files M modified: `git checkout HEAD -- <file>` (reverts working tree to last-committed state; does not touch index/HEAD/branch).
  2. For untracked files M created: `rm <file>`.
  3. Re-review N; once N passes, **re-dispatch M's implementer fresh** (it will see N's fixed state). Do not review or keep M's overlapped output.

Do not move to the next wave while a task has open Critical/Important issues. Once every task in the wave passes (or is re-dispatched fresh and passes), mark them complete (7g) and proceed to the next wave (7a).

#### 7g. Mark task complete + update ledger

For each passing task, in the same turn the review passes:

```bash
# Mark all of task N's step checkboxes done (robust block detection — no manual line counting)
bash "ai/config/skills/goal-spec-apply/scripts/mark-task-done.sh" "$change_dir/tasks.md" "$N"

# Append to the durable ledger (plain file on disk — survives context compaction).
# If this task deferred Minor findings to the final review, record them honestly:
#   bash "ai/config/skills/goal-spec-apply/scripts/ledger.sh" append-task "$change_dir" "$N" "review clean; deferred: K minor"
# Otherwise the default "review clean" is used:
bash "ai/config/skills/goal-spec-apply/scripts/ledger.sh" append-task "$change_dir" "$N"
```

Then return to 7a for the next wave.

### 8. Final whole-branch review

After ALL tasks are complete, dispatch ONE final code-reviewer subagent for the whole change:

```bash
# Gather every task's reported files into one list
cat "$change_dir"/sdd/task-*-files.txt | sort -u > "$change_dir/sdd/final-files.txt"
bash "ai/config/skills/goal-spec-apply/scripts/review-package.sh" "$change_dir/sdd/final-files.txt" "$change_dir/sdd/final-review.md"
```

Read `ai/config/skills/goal-spec-apply/references/code-reviewer-prompt.md`, fill placeholders (`{{REVIEW_PACKAGE_PATH}}`, `{{MINOR_FINDINGS}}` — the accumulated Minor findings from per-task reviews, `{{SPECS_PATH}}`, `{{DESIGN_PATH}}`), and dispatch via the Task tool (`subagent_type: "ai-spec-reviewer"`). If findings, dispatch **ONE fix subagent** (`subagent_type: "ai-spec-implementer"`) with the complete findings list (not one fixer per finding); tell it to read `ai/config/skills/goal-spec-apply/references/receiving-review.md` first and verify each finding before fixing. The controller records the fix's changed files (7d via `extract-files.sh`). Re-verify affected tests after the fix.

### 9. Final verification

Run a final verification pass inline (no external skill). **Do not trust the accumulated subagent reports — re-run the commands yourself and read the actual output.** A subagent reporting "tests pass" is a claim, not evidence; you hold the whole-change context and must verify independently.

**Gate function (for each claim below): IDENTIFY the command → RUN the full command → READ the complete output + exit code → VERIFY the output confirms the claim → only then assert it.**

- **Build**: run the project's build command (if any). Read the exit code and the tail of output. A non-zero exit or any error line blocks completion — do not paper over it.
- **Full test suite**: run the full suite for every package/module this change touched. Read the failure count from the actual output, not from any agent's summary.
- **No regressions**: confirm no previously-passing test now fails. If you fixed a bug as part of this change, apply the regression red-green check where feasible: revert the fix → the reproducing test MUST fail → restore the fix → it MUST pass. (Skip if the fix is not independently revertible.)
- **Multi-module**: if the change spans modules, verify each affected module independently — a passing run in one module does not cover another.

**Anti-self-deception**: do not use "should", "probably", "seems to", or express satisfaction before the evidence is in front of you. If a command could not be run (no build step, no tests), say so explicitly ("no build command configured; no test suite found") rather than implying success by silence. If issues are found, fix them and re-verify from scratch — do not patch-and-assume.

### 10. On completion or pause, show status

```bash
bash "ai/config/skills/goal-spec-apply/scripts/check-progress.sh" "$name"
```

## Output During Implementation

```
## Implementing: <change-name> (wave-parallel subagent-driven)

[Wave 1] Tasks 1, 3, 5 (independent, disjoint files)
  ├─ implementers dispatched concurrently → all DONE → files recorded
  ├─ reviewers dispatched concurrently → Task 1 ✅, Task 3 ✅, Task 5 ❌ (Missing: X)
  │    └─ Task 5 fix subagent → fix applied → re-review ✅
  └─ ledger updated (tasks 1, 3, 5 marked complete)
[Wave 2] Task 2 (depends on 1) — single task
  ├─ implementer → DONE → files recorded
  ├─ task reviewer → SPEC ✅, QUALITY Approved
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
- **Subagent-driven, wave-parallel**: dispatch a fresh implementer per task via the Task tool (`subagent_type: "ai-spec-implementer"`) and review via `ai-spec-reviewer`; never implement tasks in the controller session. `Parallelizable: yes` tasks with disjoint files and satisfied dependencies run as **concurrent implementers within a wave** (multiple Task calls in one message); `Parallelizable: no` tasks run alone. Waves are sequential — no cross-wave overlap. Reviewers are read-only and run concurrently within a wave.
- **No git operations**: implementers, fixers, and the controller never touch git — no `add`, no `commit`, no `stash`. Implementers write files to disk and report changed paths. Review packages use read-only `git diff` (tracked files vs HEAD) and `git diff --no-index` (untracked files, shown in full), grouped per repo so nested module repos work. The user stages and commits to whatever branch is checked out in each repo. **Exception**: in the 7f discard path, the controller may use `git checkout HEAD -- <files>` to revert a sibling task's stale tracked-file output (working-tree only — does not touch index/HEAD/branch).
- **No-commit review diffs**: review packages diff reported files vs HEAD (no commits). Parallel-wave packages are clean (disjoint files); for `Parallelizable: no` tasks sharing a file with an earlier uncommitted task, commit between them for a clean single-task diff. The controller never auto-commits. This is an accepted limitation of the no-commit model; see 7f for the overlap-based discard mechanism that handles the parallel-wave equivalent.
- **Context isolation**: hand the implementer its task brief file + cross-task interfaces + ambiguity resolutions + report contract only. Never paste session history or prior-task summaries.
- **File handoff**: briefs, reports, and review packages move as files under `$change_dir/sdd/`, not pasted text.
- **Two-stage review**: every task gets a task-reviewer subagent (spec compliance + code quality) before marking complete. Critical/Important findings must be fixed and re-reviewed. Never skip the re-review.
- **Durable ledger**: append to `sdd/progress.md` (a plain file on disk) the moment a task's review passes; on resume, trust the ledger over your own recollection. It survives context compaction but NOT `git clean -fdx` (avoid that mid-change). Never re-dispatch a task the ledger marks complete.
- **TDD inline**: implementer subagents follow RED-GREEN-REFACTOR (per the implementer-prompt); classify each task Strict TDD / Exploratory / Visual. No external TDD skill.
- **No pre-judging reviewers**: never write "don't flag X" or "at most Minor" in a review dispatch.
- **Final review is broad**: one whole-branch reviewer, one consolidated fix subagent for its findings.
- **Verification inline**: final build + full suite + regression check happens here, no external verification skill.
- Keep going through waves until done or blocked; pause on errors/blockers/unclear requirements — don't guess.
- If implementation reveals a design issue, pause and suggest updating artifacts (`/ai-spec-propose` or edit `design.md`/`tasks.md`).
- Update the task checkbox AND the ledger immediately after each task's review passes.
- No per-task model selection is performed (intentionally not implemented).
