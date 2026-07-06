---
description: Remove a dependency from the readonly-dependencies directory
argument-hint: <dependency-name>
---

Invoke the `goal-dependency-remove` skill (a passive, non-auto-triggered skill) to remove a dependency from the `readonly-dependencies/` directory.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-dependency-remove/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
