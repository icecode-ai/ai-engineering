# Install AI Engineering (Codex CLI)

## 1. Add the marketplace

```bash
codex plugin marketplace add icecode-ai/ai-engineering
codex plugin marketplace list
```

`codex plugin marketplace list` should show `ai-engineering-marketplace`.

## 2. Install the plugin

```bash
codex plugin add ai-engineering@ai-engineering-marketplace
codex plugin list
```

`codex plugin list` should show `ai-engineering` as installed and enabled.

> The marketplace is fetched directly from the public GitHub repo `icecode-ai/ai-engineering` — no manual `git clone`, and no submission to the official Plugins Directory required. Ensure the repo is public and the latest `marketplace.json` is pushed.
>
> Plugins install globally per user into `~/.codex/plugins/cache/`. Codex CLI has no `--scope project` flag; project-specific files are copied in by running `/ai-env-init` in your project.
>
> Launch Codex from the workspace root (the directory containing `ai/` and `modules/`) — skill script paths are relative to it.

## Next Steps

Restart Codex, then run `/ai-env-init`.
