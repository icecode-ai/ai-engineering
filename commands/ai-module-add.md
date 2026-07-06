---
description: Add a new module from a git repository
argument-hint: <git-url> [<branch-name>]
---

Invoke the `goal-module-add` skill (a passive, non-auto-triggered skill) to add a new module by cloning a git repository into the `modules/` directory.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-module-add/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
