https://icecode-ai.github.io/ai-engineering/#overview


# AI Engineering

> Languages: [English](README.md) | [中文](README_zh.md)

An end-to-end workflow for AI Agents

- Multi-repo Git management
- Read-only dependency isolation
- Enhanced OpenSpec workflow
- Self-contained Superpowers-style execution (subagent-driven, TDD, two-stage review)

## Install

### Claude Code

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_CLAUDE.md
```

### OpenCode

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_OPENCODE.md
```

### Qoder

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_QODER.md
```

After installation, please **restart the Agent** and run `/ai-env-init` to complete environment initialization.

> **Launch from the workspace root.** Always start the agent in the project directory that contains both `ai/` and `modules/` — skill scripts use paths relative to this root.
>
> **Permissions.** The Claude Code and Qoder install configs pre-approve skill scripts and routine git writes (`add`/`commit`/`stash`) so workflows don't prompt; project-level allow rules take effect after a one-time workspace trust dialog. OpenCode needs no permission config (bash is allowed by default).
>
> **Prerequisites.** A POSIX shell is required — bash ships with macOS and Linux; on Windows use Git Bash (bundled with Git for Windows) or WSL. Optional commands like `rsync` (used by `/ai-env-init`) are skipped gracefully if absent.

## Engineering Structure

After running `/ai-env-init`, the following directory structure is generated in your project:

```text
{project}/                            # Main project root directory
├── AGENTS.md                         # Main project guidance file
├── ai/                               # AI working directory (process artifacts output)
│   ├── config/                       # Configuration directory
│   │   ├── rules/                    # Rules & standards for AI work; apply when relevant
│   │   │   └── {rule}.md
│   │   ├── skills/                   # On-demand skills; invoke only when the user explicitly requests
│   │   └── spec-config.yaml          # Spec configuration
│   ├── input/                        # Entry for PRD, initial prompts, prototypes (user's only intervention path)
│   │   └── {user}/{seq}/{prd}.md
│   └── output/                       # Output directory
│       ├── changes/                  # Changes directory (explore/propose output)
│       │   └── archive/              # Archived change records (proposal/design); read design Decisions & proposal Why for past rationale, or for prior art when scoping a similar change — current behavior specs live in `ai/output/specs/`
│       ├── memories/                 # Bad cases & lessons; read when needed for long-term context
│       │   └── {memory}.md
│       └── specs/                    # Source-of-truth system behavior specs; read when needed or when requirements are unclear
│           └── {spec}/
├── modules/                          # Independent projects, each its own git repo + guidance file
│   └── {module}/                     # Module git repository
│       └── AGENTS.md
└── readonly-dependencies/            # Read-only dependency references; never modify
    └── {dependency}/                 # Dependency git repository
```

## Workflow

Enhanced OpenSpec workflow with self-contained Superpowers-style execution — subagent-driven development, TDD, and two-stage review — achieving a complete closed loop from exploring ideas to archiving. No external Superpowers plugin required.

```
1. explore  →  2. propose  →  3. apply  →  4. archive
```

1. **explore** — Explore ideas, investigate problems, clarify requirements
2. **propose** — Propose changes, generate all artifacts in one step
3. **apply** — Implement tasks with TDD, review, verify
4. **archive** — Archive completed changes, sync specs

```bash
USER> /ai-spec-explore @ai/input/tom/0/prd.md
AI>   Entered exploration mode, analyzing PRD and clarifying requirements...
USER> create change or /ai-spec-propose
AI>   Creating change...
USER> /ai-spec-apply
```

## Commands

Four categories of commands covering environment, modules, Spec workflow, and Git operations.

### Environment

- **`/ai-env-init`** — Initialize or update the project environment, create the standard directory structure and generate guidance files

### Modules & Dependencies

- **`/ai-module-add`** — Add a module (git repo) to the modules/ directory
- **`/ai-module-remove`** — Remove a module from the modules/ directory
- **`/ai-dependency-add`** — Add a dependency (git repo) to the readonly-dependencies/ directory
- **`/ai-dependency-remove`** — Remove a dependency from the readonly-dependencies/ directory

### Spec

- **`/ai-spec-explore`** — Enter exploration mode, organize ideas, investigate problems, clarify requirements
- **`/ai-spec-propose`** — Propose a new change, create and generate all artifacts in one step
- **`/ai-spec-apply`** — Implement tasks per spec changes, incorporating TDD and code review
- **`/ai-spec-archive`** — Archive completed changes
- **`/ai-spec-sync`** — Sync spec content to related modules

### Git

- **`/ai-git-checkout`** — Checkout a specified branch of the main project, module, or dependency
- **`/ai-git-pull`** — Pull the latest content of all, main project, module, or dependency
- **`/ai-git-push`** — Commit and push Git changes of all, main project, or module
- **`/ai-git-merge`** — Merge main branch into current branch; supports all, main project, module, dependency

---

AI Engineering - MIT
