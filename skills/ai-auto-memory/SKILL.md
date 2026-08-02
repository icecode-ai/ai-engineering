---
name: ai-auto-memory
description: Automatically capture bad cases and lessons learned during AI work by writing them as memory files to ai/output/memories/. Use this skill proactively — whenever you make a mistake that gets corrected, a command or fix fails in a non-obvious way, the user points out a recurring issue, or you discover a hidden constraint/gotcha/project convention the hard way — record it so the same mistake never happens twice. Trigger this whenever something goes wrong and you learn from it, or whenever the user corrects your approach. Do not wait to be asked.
---

# AI Auto-Memory

Capture hard-won lessons from the current task into durable memory files under `ai/output/memories/`. These memories become long-term context that future AI sessions read when they hit similar situations — so the cost of discovering a trap is paid once, not every time.

## Why this matters

Every project has traps that aren't written down anywhere: a build flag that must be set, an API that silently differs from its docs, a test that flakes unless you do X, a convention the team enforces but never documented. When you stumble onto one, you've just paid the discovery cost. Writing it down means the next session — or the next agent — doesn't pay it again. A 30-second note now can save a 20-minute detour later. That's the whole point.

## When to write a memory

Write a memory when you learn something **non-obvious, recurring, and actionable** — something a future session would plausibly hit again and not know about. Concretely:

- **A mistake that got corrected.** You tried an approach, it failed or the user corrected you, and the right approach isn't already documented. (e.g. "`fs.rmSync` with a glob throws on Node 18 — use async `fs.rm` instead")
- **A hidden constraint or gotcha.** The codebase or tooling has a requirement that isn't obvious from reading the code. (e.g. "tests must run from the repo root, not the package dir, or path mocks break")
- **A non-obvious correct pattern.** You found the "right way" to do something in this project by trial and error. (e.g. "to add a skill, it must sit one level deep under `skills/` — the loader ignores nested dirs")
- **A recurring failure mode.** You saw the same class of error twice; capture the diagnosis so it's fast next time.

## When NOT to write a memory

Most of what you do does **not** deserve a memory. Skip it when:

- It's already documented in the README, AGENTS.md, or code comments.
- It's a one-off issue unlikely to recur (a typo, a transient network error).
- It's general programming knowledge any competent developer knows.
- It's already enforced by a linter, type-checker, or test.

Writing noise dilutes the signal. A small set of high-value memories is far more useful than a large pile of trivia. If in doubt, skip it.

## How to write a memory

### 1. Check for duplicates first

Before writing, glance at existing memories so you don't create a near-duplicate. If a memory already covers this lesson, **update it** (add the new instance as evidence under "What Happened") instead of creating a new file.

Run the bundled helper — it locates the project's `ai/output/memories/` directory, lists existing memories (read them for dupes!), and prints the target path for the new file:

```bash
bash "<this-skill-dir>/scripts/save-memory.sh" "<short-english-title>" <bad-case|experience>
```

- `<this-skill-dir>` is the directory containing this `SKILL.md` (the agent knows where it loaded this skill from). If that path isn't available, the equivalent is: `mkdir -p ai/output/memories` from the project root, list `ai/output/memories/*.md` to check for dupes, and name the file `YYYY-MM-DD-<slug>.md`.
- Use a short, English, kebab-friendly title — it becomes the filename. e.g. `"node18-fs-rmsync-glob-throws"`.

### 2. Write the memory file

Use the **Write tool** to create the file at the path printed in step 1, following this template. Fill every section with real, specific content — vague memories are useless.

~~~~markdown
---
title: <human-readable title>
type: bad-case | experience
created: YYYY-MM-DD
tags: [<topic>, <tool>, <framework>]
---

# <Title>

## Context
What were you trying to do? What was the situation? Be specific enough that a future reader understands the setup without having been there.

## What Happened
For a bad-case: what went wrong — the error, the wrong output, or the user's correction.
For an experience: what you discovered.

## Lesson
The actionable takeaway. Write it as guidance a future session can follow directly: "Do X instead of Y because Z." Be concrete, not abstract.

## Applies When
The situations where this memory is relevant. Future sessions search by these cues, so list the keywords/scenarios that should make this memory surface.
~~~~

### 3. Keep memories tight

Aim for a memory you can read in under 30 seconds. If a lesson is big, split it into focused memories rather than one sprawling doc. Tags drive retrieval — choose terms someone would actually search for.

## Reading memories

Memories pay off when consulted proactively. When you start work in an area, it's worth a quick scan of `ai/output/memories/` for anything tagged with the relevant tool/framework/topic. This is especially useful when requirements feel unclear or you're about to attempt something — a 5-second scan can prevent a 20-minute detour.

## Examples

**Example 1 — bad case (corrected approach):**

Title: `pytest-path-mocks-break-from-subdir`

~~~~markdown
---
title: pytest path mocks break when run from a subdirectory
type: bad-case
created: 2026-08-02
tags: [pytest, testing, path-mocking]
---

# pytest path mocks break when run from a subdirectory

## Context
Running the auth module's test suite from `modules/auth/` via `pytest tests/`. Tests mock filesystem paths with `pathlib.Path` and `monkeypatch`.

## What Happened
Tests passed when run from the repo root (`pytest modules/auth/tests`) but failed with `AssertionError` on path comparisons when run from inside `modules/auth/`. Mock paths were resolved relative to CWD, so they didn't match the absolute paths the code under test produced.

## Lesson
Always run this project's tests from the repo root, never from the package directory — the path-mocking pattern assumes a stable CWD. If a test must be dir-independent, construct mock paths via `Path(__file__).resolve().parent` instead of literals.

## Applies When
Running pytest, debugging path-related test failures, writing new tests that mock the filesystem.
~~~~

**Example 2 — experience (hidden gotcha):**

Title: `build-fails-until-env-file-copied`

~~~~markdown
---
title: Build fails until .env is copied from the template
type: experience
created: 2026-08-02
tags: [build, dotenv, setup]
---

# Build fails until .env is copied from the template

## Context
Cloned the repo and ran `npm run build` for the first time.

## What Happened
Build failed with `Error: ENOENT: no such file .env` even though the README never mentions copying it. The app reads `.env` at build time; the repo only ships `.env.example`.

## Lesson
After a fresh clone, always run `cp .env.example .env` before building. The build reads env vars at compile time and hard-fails (no friendly message) when the file is missing. Don't waste time debugging the ENOENT — it's a setup step, not a code bug.

## Applies When
Setting up the project, onboarding, debugging a fresh-clone build failure.
~~~~
