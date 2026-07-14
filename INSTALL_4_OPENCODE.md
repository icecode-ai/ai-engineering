# Install AI Engineering (OpenCode)

## Install

Create `opencode.json` in the project root with:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "ai-engineering@git+https://github.com/icecode-ai/ai-engineering.git"
  ],
  "permission": {
    "external_directory": {
      "/tmp/*": "allow",
      "/private/tmp/*": "allow"
    }
  }
}
```

## Next Steps

Restart OpenCode, then run `/ai-env-init`.
