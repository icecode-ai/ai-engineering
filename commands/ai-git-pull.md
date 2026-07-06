---
description: Pull latest git content across MAIN, modules, and dependencies
argument-hint: [<target>]
---

Invoke the `goal-git-pull` skill (a passive, non-auto-triggered skill) to pull the latest git content across MAIN, modules, and dependencies.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-git-pull/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
