---
description: Implement tasks from a spec change
argument-hint: [<change-name>] [--worktree]
---

Invoke the `goal-spec-apply` skill (a passive, non-auto-triggered skill) to implement tasks from a spec change via subagent-driven development (fresh implementer per task, two-stage review, durable progress ledger, inline TDD + verification).

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-spec-apply/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS` (change name, and optional `--worktree` for git worktree isolation).
