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

Add the marketplace and install the plugin:

```bash
claude plugin marketplace add icecode-ai/ai-engineering --scope project
claude plugin install ai-engineering@ai-engineering-marketplace --scope project
```

## Next Steps

Restart Claude Code, then run `/ai-env-init`.
