---
description: Initialize or update project environment for AI-assisted development
---

Invoke the `goal-env-init` skill (a passive, non-auto-triggered skill) to initialize or update the project environment.

**Bootstrap command** — this must run before other `/ai-*` commands so that `ai/config/skills/` is copied into the project. The skill lives under the plugin's own `ai/` (the source that gets copied), so read it from the plugin, not the project.

Resolve `PLUGIN_ROOT` — the installed plugin root (the parent of the `commands/` directory you loaded this wrapper from; it also contains `skills/`, `agents/`, `ai/`). Then read and follow the skill instructions at:

`${PLUGIN_ROOT}/ai/config/skills/goal-env-init/SKILL.md`

When running the skill's `sync-templates.sh` script, pass `PLUGIN_ROOT` as its first argument so it knows where to mirror templates from.
