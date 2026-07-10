# ai-engineering

## Overview

This is a plugin project that users install into various Agents, such as `Claude Code`, `OpenCode`, `Qoder`, etc.

For installation instructions, read the `README.md` file.

After installation, the following content is cached in the Agent's designated cache path, scoped at the `project` level. The content includes:
1. Commands under the `commands/` directory
2. Skills under the `skills/` directory
3. Custom SubAgents under the `agents/` directory

The following content is synchronized and copied to the `user's project path` after the user runs the `/ai-env-init` command:
* Content under the `ai/` directory is copied to the `ai/` directory in the `user's project`

The difference between the 2 `skills` directories in this project:
* The `skills/` directory stores `auto-triggered skills`, which the Agent loads by default
* The `ai/config/skills/` directory stores `passively-triggered skills`, which are only triggered when the user explicitly calls them

## Path & permission conventions

- The agent must be launched from the workspace root (the directory containing both `ai/` and `modules/`). Scripts under `ai/config/skills/` are invoked with paths relative to this root — no `PROJECT_ROOT` resolution needed.
- Claude Code / Qoder: the install config pre-approves `Bash(bash ai/config/skills/*)` and routine git writes (`add`/`commit`/`stash`) via `permissions.allow`; project-level allow rules require a one-time workspace trust.
- OpenCode: `bash` is allowed by default, so no permission config is needed.

## Command conventions

All command files live in the `commands/` directory. Each command is a `.md` file with YAML frontmatter:

```YAML
---
description: <concise, precise description>
argument-hint: <parameter hint>   # Required only if the command accepts arguments
---
```

## Passive skill conventions

Passive (manually-triggered) skills live under `ai/config/skills/`. Each skill is a self-contained directory with, at minimum, a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code (e.g. bash scripts)
├── references/       # Optional: documentation
├── assets/           # Optional: templates, images, and other resources
└── ...               # Any additional files or directories
```

### SKILL.md frontmatter

```YAML
---
name: <skill name>
description: <concise, precise description>
argument-hint: <parameter hint>   # Required only if the skill accepts arguments
disable-model-invocation: true    # Set to true to prevent auto-triggering; the skill can then only be invoked manually via /name
---
```

### SKILL.md body

The Markdown body after the frontmatter contains the skill's instructions. There are no format restrictions — write whatever helps agents perform the task effectively.

Recommended sections:

* Step-by-step instructions
* Examples of inputs and outputs
* Common edge cases

Note: the agent loads the entire `SKILL.md` once it decides to activate a skill. For longer content, consider splitting it into referenced files.

All skill-invoked scripts should be implemented in `bash`.