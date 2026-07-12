https://icecode-ai.github.io/ai-engineering/#overview


# AI Engineering

An end-to-end workflow for AI Agents.

![End-to-end delivery](https://img.shields.io/badge/End--to--end_delivery-blue)
![Self-evolving](https://img.shields.io/badge/Self--evolving-green)
![Safety guardrails](https://img.shields.io/badge/Safety_guardrails-orange)
![Resumable](https://img.shields.io/badge/Resumable-yellow)
![On-demand skills](https://img.shields.io/badge/On--demand_skills-purple)
![Multi-repo control](https://img.shields.io/badge/Multi--repo_control-teal)

---

## Install

AI Engineering supports four AI Agents. Pick the one you use and follow the corresponding instruction.

### Claude Code

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_CLAUDE.md
```

### OpenCode

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_OPENCODE.md
```

### Codex

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_CODEX.md
```

### Qoder

```
Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_QODER.md
```

> After installation, please **restart the Agent** and run `/ai-env-init` to complete environment initialization.

---

## Engineering Structure

After running `/ai-env-init`, the following directory structure is generated in your project:

```
{project}/                            # Main project root directory
├── AGENTS.md                         # Main project guidance file
├── ai/                               # AI working directory (process artifacts output)
│   ├── config/                       # Configuration directory
│   │   ├── rules/                    # Rules & standards for AI work (apply when requirement-relevant)
│   │   │   └── {rule}.md
│   │   ├── skills/                   # On-demand skills (invoke only when the user explicitly requests)
│   │   └── spec-config.yaml          # Spec configuration
│   ├── input/                        # Entry for PRD, initial prompts, prototypes (user's only working directory)
│   │   └── {user}/{seq}/{prd}.md
│   └── output/                       # Process artifacts output directory
│       ├── changes/                  # Changes directory (explore/propose output)
│       │   └── archive/              # Archived change history (read when needed or when requirements are unclear)
│       ├── memories/                 # Bad cases & lessons (read when needed for long-term context)
│       │   └── {memory}.md
│       └── specs/                    # Source-of-truth system behavior specs (read when needed or when requirements are unclear)
│           └── {spec}/
├── modules/                          # Modules (result artifacts)
│   └── {module}/                     # Module git repository
│       └── AGENTS.md
└── readonly-dependencies/            # Dependencies (read-only, knowledge referenced by modules)
    └── {dependency}/                 # Dependency git repository
```

---

## Workflow

AI Engineering provides four workflows to match different levels of autonomy:

### Automated End-to-End

Fully automated, no user intervention · includes Git push, release, regression testing, and archive.

```
USER> /ai-goal-e2e-auto @ai/input/jim/0/prd.md
AI>  Fully automated end-to-end flow started, no intervention needed, executing...
AI>  Flow complete, report generated: ai/output/changes/user-login/report.md
```

| Step | Command | Mode |
|------|---------|------|
| 1 | explore — Explore requirement, clarify scope | Auto |
| 2 | propose — Create change, generate artifacts | Auto |
| 3 | apply — Implement, review, verify | Auto |
| 4 | push — Commit and push code | Auto |
| 5 | release — Release to target environment | Auto |
| 6 | test — Run regression tests | Auto |
| 7 | archive — Archive change, sync specs | Auto |

### Exploratory End-to-End

User confirmation at key steps · asks before explore, Git push, release, and archive.

```
USER> /ai-goal-e2e-explore @ai/input/jim/0/prd.md
AI>  Exploratory end-to-end flow started, will ask for confirmation at key steps...
USER> Confirm
AI>  Committed and released, continuing to archive...
```

| Step | Command | Mode |
|------|---------|------|
| 1 | explore — Explore requirement, clarify scope | Confirm |
| 2 | propose — Create change, generate artifacts | Auto |
| 3 | apply — Implement, review, verify | Auto |
| 4 | push — Commit and push code | Confirm |
| 5 | release — Release to target environment | Confirm |
| 6 | test — Run regression tests | Auto |
| 7 | archive — Archive change, sync specs | Confirm |

### Automated

Fully automated, but no Git push, release, or archive · artifacts stay local for you to commit.

```
USER> /ai-goal-auto @ai/input/jim/0/prd.md
AI>  Automated flow started, no Git push or release, executing...
AI>  Implementation complete, artifacts left local, report generated
```

| Step | Command | Mode |
|------|---------|------|
| 1 | explore — Explore requirement, clarify scope | Auto |
| 2 | propose — Create change, generate artifacts | Auto |
| 3 | apply — Implement, review, verify | Auto |
| 4 | test — Run regression tests | Auto |

### Manual

Manual flow · run `/ai-spec-*` commands step by step, fully under your control.

```
USER> /ai-spec-explore @ai/input/jim/0/prd.md
AI>  Entered exploration mode, analyzing PRD and clarifying requirements...
USER> create change or /ai-spec-propose
AI>  Creating change...
USER> /ai-spec-apply
```

| Step | Command | Mode |
|------|---------|------|
| 1 | explore — Explore requirement, clarify scope | Manual |
| 2 | propose — Create change, generate artifacts | Manual |
| 3 | apply — Implement, review, verify | Manual |
| 4 | archive — Archive change, sync specs | Manual |

---

## Commands

Five categories covering environment, modules, workflow, Spec, and Git operations.

### Environment

| Command | Description |
|---------|-------------|
| `/ai-env-init` | Initialize or update the project environment, create the standard directory structure and generate guidance files |

### Modules & Dependencies

| Command | Description |
|---------|-------------|
| `/ai-module-add` | Add a module (git repo) to the `modules/` directory |
| `/ai-module-remove` | Remove a module from the `modules/` directory |
| `/ai-dependency-add` | Add a dependency (git repo) to the `readonly-dependencies/` directory |
| `/ai-dependency-remove` | Remove a dependency from the `readonly-dependencies/` directory |

### Workflow

| Command | Description |
|---------|-------------|
| `/ai-goal-e2e-auto` | Automated end-to-end flow: explore, propose, apply, push, release, test, and archive without user prompts |
| `/ai-goal-e2e-explore` | Exploratory end-to-end flow with user confirmations at infra, git, release, and archive steps |
| `/ai-goal-auto` | Automated requirement flow: explore, propose, apply, and test without git push/release or user prompts |

### Spec

| Command | Description |
|---------|-------------|
| `/ai-spec-explore` | Enter exploration mode, organize ideas, investigate problems, clarify requirements |
| `/ai-spec-propose` | Propose a new change, create and generate all artifacts in one step |
| `/ai-spec-apply` | Implement tasks per spec changes, incorporating TDD and code review |
| `/ai-spec-archive` | Archive completed changes |
| `/ai-spec-sync` | Sync spec content to related modules |

### Git

| Command | Description |
|---------|-------------|
| `/ai-git-checkout` | Checkout a specified branch of the main project, module, or dependency |
| `/ai-git-pull` | Pull the latest content of all, main project, module, or dependency |
| `/ai-git-push` | Commit and push Git changes of all, main project, or module |
| `/ai-git-merge` | Merge main branch into current branch; supports all, main project, module, dependency |

---

## License

MIT
