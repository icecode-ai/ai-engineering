---
description: Add a dependency project to the readonly-dependencies directory
argument-hint: <git-url> [<branch-name>]
---

Invoke the `goal-dependency-add` skill (a passive, non-auto-triggered skill) to add a dependency project to the `readonly-dependencies/` directory.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-dependency-add/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
