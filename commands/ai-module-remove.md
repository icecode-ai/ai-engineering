---
description: Remove a module from the project
argument-hint: <module-name>
---

Invoke the `goal-module-remove` skill (a passive, non-auto-triggered skill) to remove a module from the `modules/` directory.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-module-remove/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
