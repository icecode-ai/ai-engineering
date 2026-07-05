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
