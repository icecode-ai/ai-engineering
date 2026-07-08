# Install AI Engineering (Claude Code)

## Install

Create `.claude/settings.json` in the project root:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c '[ -d \"$HOME/.claude/plugins/cache/ai-engineering-marketplace\" ] && exit 0; command -v claude >/dev/null 2>&1 && claude plugin install ai-engineering@ai-engineering-marketplace --scope project >/dev/null 2>&1; true'"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "ai-engineering@ai-engineering-marketplace": true
  },
  "permissions": {
    "allow": [
      "Bash(bash ai/config/skills/*)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git stash *)"
    ]
  },
  "extraKnownMarketplaces": {
    "ai-engineering-marketplace": {
      "source": { 
        "source": "github", 
        "repo": "icecode-ai/ai-engineering"
      },
      "autoUpdate": true
    }
  }
}
```

> Launch Claude Code from the workspace root (the directory containing `ai/` and `modules/`) — skill script paths are relative to it. The `permissions.allow` rules above take effect after a one-time workspace trust dialog.

Add the marketplace and install the plugin:

```bash
claude plugin marketplace add icecode-ai/ai-engineering --scope project
claude plugin install ai-engineering@ai-engineering-marketplace --scope project
```

## Next Steps

Restart Claude Code, then run `/ai-env-init`.
