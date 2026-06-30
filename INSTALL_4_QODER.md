# Install AI Engineering and Superpowers (Qoder CLI)

## Install

Create `.qoder/settings.json` in the project root with:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'for p in https://github.com/doersoul/ai-engineering.git::ai-engineering https://github.com/obra/superpowers.git::superpowers; do url=${p%%::*}; name=${p##*::}; [ -d \"$HOME/.qoder/plugins/cache/local/$name\" ] && continue; command -v qodercli >/dev/null 2>&1 || continue; d=$(mktemp -d); git clone \"$url\" \"$d/$name\" >/dev/null 2>&1; [ -d \"$d/$name\" ] && qodercli plugins install \"$d/$name\" --scope project >/dev/null 2>&1; rm -rf \"$d\"; done; true'",
            "timeout": 120
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "ai-engineering@local": true,
    "superpowers@local": true
  }
}
```

After writing `settings.json`, clone each plugin to a temp dir and install it to the current project:

```bash
# Install ai-engineering
d=$(mktemp -d) && git clone https://github.com/doersoul/ai-engineering.git "$d/ai-engineering" \
  && qodercli plugins install "$d/ai-engineering" --scope project && rm -rf "$d"

# Install superpowers
d=$(mktemp -d) && git clone https://github.com/obra/superpowers.git "$d/superpowers" \
  && qodercli plugins install "$d/superpowers" --scope project && rm -rf "$d"
```

## Next Steps

Restart Qoder, then run `/ai-env-init`.