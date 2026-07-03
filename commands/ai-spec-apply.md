---
description: Implement tasks from a spec change
argument-hint: [<change-name>]
---

Implement tasks from a spec change. Work through pending tasks with integrated TDD cycle, code review, and verification practices.

**Input**: Optionally specify a change name (e.g., `/ai-spec-apply add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **Select the change**

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"
   ```

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists:
     ```bash
     ls -1 "${PROJECT_ROOT}/ai/output/changes/" 2>/dev/null | grep -v '^archive$'
     ```
   - If ambiguous or multiple changes exist, use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/ai-spec-apply <other>`).

2. **Check artifact status**

   ```bash
   # $name = selected change (provided by user or auto-selected in step 1)
   change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
   if [ ! -d "$change_dir" ]; then
     echo "Change '$name' not found."
     exit 1
   fi

   echo "=== Change: $name ==="
   all_done=true
   for artifact in proposal.md design.md tasks.md; do
     if [ -f "$change_dir/$artifact" ]; then
       echo "✓ $artifact"
     else
       echo "✗ $artifact (missing)"
       all_done=false
     fi
   done

   if [ -d "$change_dir/specs" ] && [ "$(ls -A "$change_dir/specs" 2>/dev/null)" ]; then
     echo "✓ specs/"
   else
     echo "○ specs/ (empty — may need creation)"
   fi

   if [ "$all_done" = false ]; then
     echo "Some artifacts are missing. Suggest running /ai-spec-propose $name first."
   fi
   ```

3. **Read context files**

   Read all existing artifact files for context:
   - `$change_dir/proposal.md`
   - `$change_dir/design.md`
   - `$change_dir/tasks.md`
   - Files under `$change_dir/specs/`

4. **Show current progress**

   Parse the tasks file to show implementation progress:

   ```bash
   tasks_file="$change_dir/tasks.md"
   if [ -f "$tasks_file" ]; then
     total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
     done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
     pending=$((total - done_count))
     echo "Progress: $done_count/$total tasks complete ($pending remaining)"
   else
     echo "No tasks.md found — create one with /ai-spec-propose"
   fi
   ```

5. **Implement tasks (loop until done)**

   For each pending task (marked `- [ ]` in `tasks.md`):

   ### 5a. TDD Cycle (for each task)

   Use the `/test-driven-development` skill's TDD cycle to implement each task. Classify each task at the start into one of three categories:

   1. **Strict TDD** — For logic/unit-testable tasks:
      - Write tests first (they should fail)
      - Run tests to confirm failure
      - Implement the feature
      - Run tests to confirm passing
      - Refactor if needed

   2. **Exploratory** — For UI/prototyping/uncertain tasks:
      - Investigate the approach quickly
      - Prototype the solution
      - Verify with manual or integration tests

   3. **Visual** — For styling/layout tasks:
      - Implement the visual change
      - Verify appearance

   If unsure which category a task belongs to, ask the user.

   ### 5b. Mark task complete

   After implementing, mark the task as complete in `tasks.md`:

   ```bash
   # Mark the completed task as done. Set $task_line to the 1-based line number of the completed task.
   case "$task_line" in ''|*[!0-9]*) echo "Invalid task line: '$task_line'"; exit 1;; esac
   sed -i.bak "${task_line}s/\[ \]/[x]/" "$tasks_file" && rm -f "$tasks_file.bak"
   ```

   ### 5c. Request code review

   After each task completion, invoke the `/requesting-code-review` skill to review the changes made for that task. Fix any issues found during the review before proceeding to the next task.

6. **On completion or pause, show status**

   Display:
   ```bash
   tasks_file="${PROJECT_ROOT}/ai/output/changes/$name/tasks.md"
   total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
   done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
   echo "=== Implementation Status ==="
   echo "Change: $name"
   echo "Progress: $done_count/$total tasks complete"
   if [ "$done_count" -eq "$total" ] && [ "$total" -gt 0 ]; then
     echo "✓ All tasks complete! Archive this change with /ai-spec-archive $name"
   fi
   ```

7. **Final verification**

   When all tasks are complete, invoke the `/verification-before-completion` skill to perform a final verification pass. This ensures the build passes, the full test suite runs clean, and no regressions were introduced. If issues are found, fix them and re-verify.

**Output During Implementation**

```
## Implementing: <change-name>

Working on task 3/7: <task description>
[... TDD cycle: test -> implement -> verify ...]
✓ Task complete

Working on task 4/7: <task description>
[... TDD cycle: test -> implement -> verify ...]
✓ Task complete
```

**Output On Completion**

```
## Implementation Complete

**Change:** <change-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

All tasks complete! You can archive this change with /ai-spec-archive <name>.
```

**Output On Pause (Issue Encountered)**

```
## Implementation Paused

**Change:** <change-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

**Guardrails**
- Keep going through tasks until done or blocked
- Always read context files before starting
- If task is ambiguous, pause and ask before implementing
- If implementation reveals issues, pause and suggest updating artifacts
- Keep code changes minimal and scoped to each task
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements — don't guess
- For Strict TDD tasks, use the `/test-driven-development` skill — write tests before implementing
- After each task, invoke `/requesting-code-review` to review changes
- After ALL tasks are complete, invoke `/verification-before-completion` for final verification
