# Install AI Engineering (Qoder CLI)

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
            "command": "bash -c 'url=https://github.com/icecode-ai/ai-engineering.git; name=ai-engineering; [ -d \"$HOME/.qoder/plugins/cache/local/$name\" ] && exit 0; command -v qodercli >/dev/null 2>&1 || exit 0; d=$(mktemp -d); git clone \"$url\" \"$d/$name\" >/dev/null 2>&1; [ -d \"$d/$name\" ] && qodercli plugins install \"$d/$name\" --scope project >/dev/null 2>&1; rm -rf \"$d\"; true'",
            "timeout": 120
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "ai-engineering@local": true
  },
  "permissions": {
    "allow": [
      "Bash(bash ai/config/skills/*)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git stash *)"
    ]
  }
}
```

> Launch Qoder from the workspace root (the directory containing `ai/` and `modules/`) — skill script paths are relative to it. Project-level allow rules may require a one-time trust prompt.

After writing `settings.json`, clone the plugin to a temp dir and install it to the current project:

```bash
d=$(mktemp -d) && git clone https://github.com/icecode-ai/ai-engineering.git "$d/ai-engineering" \
  && qodercli plugins install "$d/ai-engineering" --scope project && rm -rf "$d"
```

## Next Steps

Restart Qoder, then run `/ai-env-init`.
