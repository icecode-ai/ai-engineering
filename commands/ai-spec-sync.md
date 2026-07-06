---
description: Sync specs and memories from the main project to related modules
argument-hint: [<change-name>]
---

Invoke the `goal-spec-sync` skill (a passive, non-auto-triggered skill) to sync specification and memory content from the main project's `ai/` directory to each module.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-spec-sync/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
