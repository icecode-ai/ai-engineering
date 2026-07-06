---
description: Propose a new change - create it and generate all artifacts in one step
argument-hint: [<change-name-or-description>]
---

Invoke the `goal-spec-propose` skill (a passive, non-auto-triggered skill) to create a change directory and generate all artifacts (proposal, specs, design, tasks) in one step.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-spec-propose/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
