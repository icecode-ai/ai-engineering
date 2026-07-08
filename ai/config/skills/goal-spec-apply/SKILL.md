---
name: goal-spec-apply
description: Implement tasks from a spec change via subagent-driven development with two-stage review
argument-hint: [<change-name>]
disable-model-invocation: true
---

Implement tasks from a spec change using **subagent-driven development**: a fresh implementer subagent per task, a two-stage review (spec compliance + code quality) after each, a broad final review, and a durable progress ledger. The controller is the sole git writer; TDD, code review, and verification are built in — no external skills required.

**Input**: Optionally specify a change name (e.g., `/ai-spec-apply add-auth`). If the change name is omitted, infer from context or prompt.

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

### 1. Select the change

Parse `$ARGUMENTS`: the change name is the first non-flag token. If a name is provided, use it. Otherwise:
- Infer from conversation context if the user mentioned a change
- Auto-select if only one active change exists:
  ```bash
  ls -1 "${PROJECT_ROOT}/ai/output/changes/" 2>/dev/null | grep -v '^archive$'
  ```
- If ambiguous or multiple changes exist, use the **AskUserQuestion tool** to let the user select

Always announce: "Using change: <name>" and how to override (e.g., `/ai-spec-apply <other>`).

### 2. Check artifact status

```bash
change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
if [ ! -d "$change_dir" ]; then
  echo "Change '$name' not found."
  exit 1
fi
echo "=== Change: $name ==="
all_done=true
for artifact in proposal.md design.md tasks.md; do
  if [ -f "$change_dir/$artifact" ]; then echo "✓ $artifact"; else echo "✗ $artifact (missing)"; all_done=false; fi
done
if [ -d "$change_dir/specs" ] && [ "$(ls -A "$change_dir/specs" 2>/dev/null)" ]; then
  echo "✓ specs/"
else
  echo "○ specs/ (empty — may need creation)"
fi
[ "$all_done" = false ] && echo "Some artifacts are missing. Suggest running /ai-spec-propose $name first."
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
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/ledger.sh" init "$change_dir"
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/ledger.sh" read "$change_dir"
```

Tasks listed in the ledger as complete are DONE — do not re-dispatch them. Resume at the first task not marked complete. The ledger is committed as `chore(progress)` commits (step 7f), so it survives `git clean -fdx`; if the ledger file is nonetheless missing, recover the "review-passed" task set via `git log --grep='chore(progress)'` — code commits alone cannot tell whether a task's review passed.

### 5. Show current progress

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/check-progress.sh" "$name"
```

### 6. Pre-flight plan review

Before dispatching Task 1, scan `tasks.md` once for conflicts: tasks that contradict each other or the Global Constraints, or anything the plan mandates that the review rubric treats as a defect. Present all findings to the user as one batched question (each finding beside the plan text that mandates it) before execution begins. If the scan is clean, proceed without comment.

### 7. Implement tasks (subagent-driven loop)

For each pending task (marked `- [ ]` in `tasks.md`, not already in the ledger), in dependency order:

#### 7a. Build the dispatch batch

Read the task's `**Parallelizable:**` flag and its `**Interfaces:**` (Consumes/Produces). **Implementers are always serial** — one implementer at a time. The controller is the sole git committer (see 7d), so concurrent implementers would race on git and build artifacts; `Parallelizable` instead enables **pipeline** overlap of a task's review with the next implementer:

- **Serial** (default, `Parallelizable: no`, or the next task depends on a not-yet-done task): after committing a task's work (7d) and generating its review package (7e), dispatch the task-reviewer alone; wait for its verdict before dispatching the next implementer.
- **Pipeline** (`Parallelizable: yes` AND the next pending task has no file overlap): after committing task N's work and generating its review package, dispatch the task-reviewer(N) AND the next implementer(N+1) in ONE message (two Task tool calls). The reviewer reads a frozen review-package file, so it is safe to overlap with implementer N+1's writes. Never pipeline tasks that touch the same files.

#### 7b. Prepare each task's handoff files (do this before dispatching)

```bash
# Extract the task's full text to a brief file (single source of requirements)
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/task-brief.sh" "$change_dir/tasks.md" "$N" "$change_dir/sdd/task-$N-brief.md"

# Record the BASE commit (the commit before this task's work) — never use HEAD~1
BASE="$(git rev-parse HEAD)"
echo "$BASE" > "$change_dir/sdd/task-$N-base.sha"
```

#### 7c. Dispatch the implementer subagent

Read `${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/references/implementer-prompt.md`, fill the `{{...}}` placeholders:
- `{{TASK_FIT}}` — one line on where this task fits in the project.
- `{{TASK_BRIEF_PATH}}` — `$change_dir/sdd/task-$N-brief.md` (introduce it as "read this first — it is your requirements, with exact values verbatim").
- `{{CROSS_TASK_INTERFACES}}` — exact signatures/decisions from earlier tasks this task consumes (from their Produces blocks).
- `{{AMBIGUITY_RESOLUTIONS}}` — your resolution of any ambiguity you noticed in the brief.
- `{{REPORT_PATH}}` — `$change_dir/sdd/task-$N-report.md`.
- `{{CHANGE_NAME}}` — the change name (for the commit tag).

Dispatch via the **Task tool** with `subagent_type: "ai-spec-implementer"`. **Do NOT paste accumulated prior-task summaries** — a fresh subagent gets only its task brief, the interfaces, and the global constraints. The implementer does NOT commit; it returns changed files + a suggested commit message (see its report contract).

#### 7d. Handle implementer status + commit the task's work

The implementer returns one of: **DONE** / **DONE_WITH_CONCERNS** / **NEEDS_CONTEXT** / **BLOCKED**. The implementer does NOT commit — when it reports DONE (or DONE_WITH_CONCERNS you accept), the **controller** is the sole git writer and commits the task's work before review:

```bash
# Stage exactly the files the implementer reported changed, then commit with its suggested message.
git add <reported-files>            # e.g. git add path/a path/b
git commit -m "<suggested message> [ai-change: $name]"
```

- **DONE** → commit the work (above), then proceed to 7e (review).
- **DONE_WITH_CONCERNS** → read the concerns; if about correctness/scope, address before committing; if observations, commit and proceed to review.
- **NEEDS_CONTEXT** → provide the missing context and re-dispatch (same task). Do not commit partial work.
- **BLOCKED** → assess: context problem (add context, re-dispatch), task too large (split it), plan wrong (escalate to user). Never ignore an escalation or force a retry with no changes.

Recording BASE (7b) before dispatch + this commit after gives a clean `BASE..HEAD` review package containing only this task's work.

#### 7e. Two-stage task review

Generate the review package BEFORE dispatching the next implementer (so the package is frozen — a pipelined next implementer won't change it):

```bash
BASE="$(cat "$change_dir/sdd/task-$N-base.sha")"
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/review-package.sh" "$BASE" HEAD "$change_dir/sdd/task-$N-review.md"
```

Read `${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/references/task-reviewer-prompt.md`, fill placeholders (`{{TASK_BRIEF_PATH}}`, `{{REPORT_PATH}}`, `{{REVIEW_PACKAGE_PATH}}`, `{{GLOBAL_CONSTRAINTS}}`, `{{SPECS_PATH}}` = `$change_dir/specs`), and dispatch via the Task tool (`subagent_type: "ai-spec-reviewer"`).

**Pipeline dispatch** (only if task N is `Parallelizable: yes` and the next pending task N+1 has no file overlap): dispatch the task-reviewer(N) AND the next implementer(N+1) (7c) in ONE message. The reviewer reads the frozen review-package file, so it is safe to overlap. When both return, process the verdict below and commit N+1's work (7d). **Serial dispatch** (default): dispatch the task-reviewer alone and wait for its verdict before the next implementer.

The reviewer returns `SPEC: ✅/❌/⚠️` and `QUALITY: Approved/Issues`. Handle:
- **SPEC ✅ + QUALITY Approved** → mark complete (7f).
- **SPEC ❌ or Critical/Important issues** → dispatch a fix subagent (`subagent_type: "ai-spec-implementer"`) with all findings + the implementer contract (re-run covering tests, append fix report to the same `task-$N-report.md`); the controller commits the fix, then re-review (7e again). Do not move to the next task while Critical/Important issues are open.
- **⚠️ Cannot verify from diff** → you (the controller) resolve each yourself before marking complete; you hold the cross-task context the reviewer lacks. If a real gap, treat as failed spec review.
- **Minor findings** → record in the ledger; defer to the final review (step 8).

Never tell a reviewer what not to flag, or pre-rate a finding's severity in the dispatch.

#### 7f. Mark task complete + update ledger + commit progress

```bash
# Mark all of task N's step checkboxes done (robust block detection — no manual line counting)
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/mark-task-done.sh" "$change_dir/tasks.md" "$N"

# Append to the durable ledger
HEAD7="$(git rev-parse --short HEAD)"
BASE7="$(git rev-parse --short "$BASE")"
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/ledger.sh" append "$change_dir" "Task $N: complete (commits $BASE7..$HEAD7, review clean)"

# Commit the progress bookkeeping so it survives git clean -fdx.
# The ledger records "review passed" — which code commits alone cannot express.
git add "$change_dir/tasks.md" "$change_dir/sdd/progress.md"
git commit -m "chore(progress): task $N complete (review clean) [ai-change: $name]"
```

Do this in the same turn as the review passes. Then continue to the next pending task (7a).

### 8. Final whole-branch review

After ALL tasks are complete, dispatch ONE final code-reviewer subagent for the whole branch:

```bash
mainline="$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | cut -d/ -f2)" || mainline=""
if [ -z "$mainline" ]; then
  if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    mainline="main"
  elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    mainline="master"
  else
    mainline="main"
  fi
fi
MERGE_BASE="$(git merge-base HEAD "$mainline")"
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/review-package.sh" "$MERGE_BASE" HEAD "$change_dir/sdd/final-review.md"
```

Read `${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/references/code-reviewer-prompt.md`, fill placeholders (`{{REVIEW_PACKAGE_PATH}}`, `{{MINOR_FINDINGS}}` — the accumulated Minor findings from per-task reviews, `{{SPECS_PATH}}`, `{{DESIGN_PATH}}`), and dispatch via the Task tool (`subagent_type: "ai-spec-reviewer"`). If findings, dispatch **ONE fix subagent** (`subagent_type: "ai-spec-implementer"`) with the complete findings list (not one fixer per finding); the controller commits the fix. Re-verify affected tests after the fix.

### 9. Final verification

Run a final verification pass inline (no external skill): ensure the build passes, the full test suite runs clean, and no regressions were introduced. If issues are found, fix them and re-verify. Concretely:
- Run the project's build command (if any).
- Run the full test suite (all packages/modules touched by this change).
- Confirm no previously-passing tests now fail.
- If the change spans modules, verify each affected module independently.

### 10. On completion or pause, show status

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/scripts/check-progress.sh" "$name"
```

## Output During Implementation

```
## Implementing: <change-name> (subagent-driven)

[Task 3/7] <task description>
  ├─ implementer subagent → DONE → controller committed (abc1234)
  ├─ task reviewer → SPEC ✅, QUALITY Approved
  └─ progress committed (chore(progress), def5678)
[Task 4/7] <task description>
  ├─ implementer subagent → DONE → controller committed
  ├─ task reviewer → SPEC ❌ (Missing: progress reporting) → fix subagent → controller committed → re-review ✅
  └─ progress committed
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
- **Controller owns git**: implementers and fixers never commit — they report changed files + a suggested commit message. The controller is the sole git writer: it commits each task's code (7d, before review) and a `chore(progress)` commit (7f, after review passes). This avoids git index races and keeps per-task review packages clean.
- **Context isolation**: hand the implementer its task brief file + cross-task interfaces + ambiguity resolutions + report contract only. Never paste session history or prior-task summaries.
- **File handoff**: briefs, reports, and review packages move as files under `$change_dir/sdd/`, not pasted text.
- **Two-stage review**: every task gets a task-reviewer subagent (spec compliance + code quality) before marking complete. Critical/Important findings must be fixed and re-reviewed. Never skip the re-review.
- **Durable ledger**: append to `sdd/progress.md` AND commit it (`chore(progress)`) the moment a task's review passes; on resume, trust the ledger (or `git log --grep='chore(progress)'` if the file is gone) over your own recollection. Never re-dispatch a task the ledger marks complete.
- **TDD inline**: implementer subagents follow RED-GREEN-REFACTOR (per the implementer-prompt); classify each task Strict TDD / Exploratory / Visual. No external TDD skill.
- **No pre-judging reviewers**: never write "don't flag X" or "at most Minor" in a review dispatch.
- **Final review is broad**: one whole-branch reviewer, one consolidated fix subagent for its findings.
- **Verification inline**: final build + full suite + regression check happens here, no external verification skill.
- Keep going through tasks until done or blocked; pause on errors/blockers/unclear requirements — don't guess.
- If implementation reveals a design issue, pause and suggest updating artifacts (`/ai-spec-propose` or edit `design.md`/`tasks.md`).
- Update the task checkbox AND the ledger AND commit them (`chore(progress)`) immediately after each task's review passes.
- No per-task model selection is performed (P3 intentionally not implemented).
