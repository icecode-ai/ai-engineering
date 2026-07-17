---
name: goal-spec-apply
description: Implement tasks from a spec change via wave-parallel subagent-driven development with two-stage review
argument-hint: [<change-name>]
disable-model-invocation: true
---

Implement tasks from a spec change using **subagent-driven development with wave-based parallelism**: a fresh implementer subagent per task (independent tasks run concurrently within a wave), a two-stage review (spec compliance + code quality) after each, a broad final review, and a durable progress ledger. The controller never touches git — implementers write files to disk, the user stages and commits; TDD, code review, and verification are built in — no external skills required. A **workspace scope guard** and **explicit state machine** frame the run: the change's declared affected modules (from `proposal.md`) gate each task's planned files as a pre-flight finding, and the artifact/task state (blocked / in progress / all done) routes the flow.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

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

The script prints a `STATE:` line — branch on it:
- **`STATE: BLOCKED`** — artifacts missing. Suggest `/ai-spec-propose $name` and stop; do not proceed to implementation.
- **`STATE: ALL_DONE`** — every task already complete. Suggest `/ai-spec-archive $name` and stop; do not re-run waves or the final review on an already-finished change.
- **`STATE: IN_PROGRESS`** — artifacts present, tasks remain. Continue to step 3.

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

Before dispatching Task 1, run two pre-flight scans and present ALL findings (conflicts + scope) as **one batched question** before execution begins. If both are clean, proceed without comment. Both scans run before any dispatch, so wave parallelism is unaffected.

**6a. Conflict scan.** Scan `tasks.md` once for conflicts: tasks that contradict each other or the Global Constraints, or anything the plan mandates that the review rubric treats as a defect.

**6b. Workspace scope scan.** Extract the change's allowed edit roots from `proposal.md`, then check every task's planned files against them. This catches scope creep — a task editing a module the proposal did not declare as affected (e.g. proposal says `modules/auth` but a task's `**Files:**` lists `modules/billing/…`).

```bash
# Extract module-level edit roots from proposal.md. Exit 2 = no roots declared.
if bash "ai/config/skills/goal-spec-apply/scripts/edit-roots.sh" "$change_dir/proposal.md" "$change_dir/sdd/edit-roots.txt"; then
  # Roots declared — scope-check each task's planned files against them.
  # Fence-aware task-number extraction (skip ```-fenced regions, consistent with
  # mark-task-done.sh / planned-files.sh) — avoids matching example "### Task N:"
  # headers inside code blocks.
  for N in $(awk 'BEGIN{f=0} /^```/{f=!f;next} f{next} /^### Task [0-9]+:/{line=$0; sub(/^### Task /,"",line); sub(/:.*/,"",line); print line}' "$change_dir/tasks.md" | sort -n -u); do
    bash "ai/config/skills/goal-spec-apply/scripts/planned-files.sh" "$change_dir/tasks.md" "$N" "$change_dir/sdd/task-$N-planned.txt" >/dev/null
    bash "ai/config/skills/goal-spec-apply/scripts/check-scope.sh" "$change_dir/sdd/task-$N-planned.txt" "$change_dir/sdd/edit-roots.txt" || true
  done
else
  # No roots declared — unscoped change; record one finding. Do not run check-scope
  # per task here (edit-roots.txt is empty, so it would just print NO ROOTS N times).
  :
fi
```

Handle the scope results (fold them into the same batched question as 6a):
- `edit-roots.sh` exits `2` (no `modules/<x>` / `ai` tokens in proposal) → the change is **unscoped**: add "change declares no Affected Modules — confirm scope or update `proposal.md`" as a finding. The `else` branch above records this once; `check-scope.sh` is not run in that case.
- `check-scope.sh` prints `OUT OF SCOPE:` + files for a task → add as a finding: "Task N plans to edit `<files>` outside declared Affected Modules `<roots>`." The user decides whether the task is wrong, the proposal is incomplete, or the scope is intentionally wider.

Root-level files (`package.json`, `tsconfig.json`, …) are intentionally not roots — a task editing one legitimately surfaces as a finding for the user to approve. Scope is validated here, once, so step 7 does not re-check it inside any wave.

### 7. Implement tasks (wave-based parallel subagent-driven loop)

Dispatch independent implementers **concurrently within each wave**, review them concurrently, then repeat for the next wave. `Parallelizable: yes` tasks with no file overlap and satisfied dependencies run in parallel; `Parallelizable: no` tasks run alone. **Waves are sequential** — no cross-wave overlap (do not start the next wave's implementers until this wave's reviews finish). The parallelism comes from within-wave concurrent implementers + concurrent reviewers.

#### 7a. Build the ready set + form a parallel batch

Read the ledger (step 4) to know which tasks are complete. Compute the **ready set**: pending tasks (marked `- [ ]` in `tasks.md`, not in the ledger) whose `Consumes:` dependencies are ALL satisfied (every task they consume is complete in the ledger).

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
- `{{CROSS_TASK_INTERFACES}}` — exact signatures/decisions from earlier tasks this task consumes (from their `Produces:` items under `**Interfaces:**`).
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
# Gather every task's reported files into one list (2>/dev/null guards against
# the glob not matching, which shouldn't happen at step 8 but is defensive)
cat "$change_dir"/sdd/task-*-files.txt 2>/dev/null | sort -u > "$change_dir/sdd/final-files.txt"
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
- Never implement tasks in the controller session — dispatch via the Task tool (`ai-spec-implementer` / `ai-spec-reviewer`).
- Never touch git (no `add`/`commit`/`stash`) — **except** the 7f discard path's `git checkout HEAD -- <files>` (working-tree only).
- Never paste session history or prior-task summaries into an implementer dispatch (context isolation).
- Never skip the re-review after a fix.
- Never re-dispatch a task the ledger marks complete; trust the ledger over recollection on resume.
- Never write "don't flag X" or pre-rate severity in a review dispatch.
- Never re-dispatch a change whose state is `ALL_DONE`.
- Keep going through waves until done or blocked; pause on errors/blockers/unclear requirements — don't guess.
- If implementation reveals a design issue, pause and suggest updating artifacts (`/ai-spec-propose` or edit `design.md`/`tasks.md`).
- No per-task model selection is performed (intentionally not implemented).
