---
description: Push git changes across MAIN and modules
argument-hint: [<target>]
---

Invoke the `goal-git-push` skill (a passive, non-auto-triggered skill) to push local commits to git remotes across MAIN and modules.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-git-push/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
