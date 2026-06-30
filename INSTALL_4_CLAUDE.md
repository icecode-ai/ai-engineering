# Install AI Engineering and Superpowers (Claude Code)

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
            "command": "bash -c 'for m in ai-engineering-marketplace:ai-engineering superpowers-marketplace:superpowers; do market=${m%%:*}; plug=${m#*:}; [ -d \"$HOME/.claude/plugins/cache/$market\" ] && continue; command -v claude >/dev/null 2>&1 && claude plugin install \"$plug@$market\" --scope project >/dev/null 2>&1; done; true'"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "ai-engineering@ai-engineering-marketplace": true,
    "superpowers@superpowers-marketplace": true
  },
  "extraKnownMarketplaces": {
    "ai-engineering-marketplace": {
      "source": { 
        "source": "github", 
        "repo": "doersoul/ai-engineering"
      },
      "autoUpdate": true
    },
    "superpowers-marketplace": {
      "source": { 
        "source": "github", 
        "repo": "obra/superpowers-marketplace"
      },
      "autoUpdate": true
    }
  }
}
```

Add the marketplaces and install both plugins:

```bash
claude plugin marketplace add doersoul/ai-engineering --scope project
claude plugin marketplace add obra/superpowers-marketplace --scope project
claude plugin install ai-engineering@ai-engineering-marketplace --scope project
claude plugin install superpowers@superpowers-marketplace --scope project
```

## Next Steps

Restart Claude Code, then run `/ai-env-init`.