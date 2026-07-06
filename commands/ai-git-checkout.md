---
description: Checkout a git branch across MAIN, modules, and dependencies
argument-hint: <target> <branch>
---

Invoke the `goal-git-checkout` skill (a passive, non-auto-triggered skill) to checkout a git branch across MAIN, modules, and dependencies.

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-git-checkout/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`
