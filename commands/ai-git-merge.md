---
description: Merge mainline branch into current branch across MAIN, modules, and dependencies
argument-hint: [<target>]
---

Invoke the `goal-git-merge` skill (a passive, non-auto-triggered skill) to merge the mainline branch into the current branch across MAIN, modules, and dependencies.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-git-merge/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
