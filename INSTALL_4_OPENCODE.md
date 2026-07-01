# Install AI Engineering and Superpowers (OpenCode)

## Install

Create `opencode.json` in the project root with:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "ai-engineering@git+https://github.com/icecode-ai/ai-engineering.git",
    "superpowers@git+https://github.com/obra/superpowers.git"
  ]
}
```

## Next Steps

Restart OpenCode, then run `/ai-env-init`.