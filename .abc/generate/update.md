# Spec 技能上游同步提示词

> 当 OpenSpec 或 SuperPowers 上游仓库有更新时，将本文件完整提供给 AI Agent 执行，AI 会按照以下指令完成 spec 相关技能的智能合并更新。

---

## 一、背景

本项目的 spec 相关技能是基于两个上游开源项目改造融合而来：

- **OpenSpec** (`https://github.com/Fission-AI/OpenSpec.git`)：提供 explore / propose / archive 工作流、delta-spec 合并语义（ADDED / MODIFIED / REMOVED / RENAMED）、artifact 结构（proposal / design / tasks / specs）。
- **SuperPowers** (`https://github.com/obra/superpowers.git`)：提供 subagent-driven development、TDD 红绿重构、two-stage review（spec 合规 + 代码质量）架构。

本项目在融合时做了大量本地化改造（多仓库支持、独立 subagent 架构、持久化进度账本、command→skill 包装模式等），因此**不能直接用上游覆盖本地文件**，必须智能合并。

---

## 二、上游仓库与关键路径

### OpenSpec

- 仓库地址：`https://github.com/Fission-AI/OpenSpec.git`
- 默认分支：`main`
- 需要关注的路径：

| 路径 | 说明 |
|---|---|
| `src/core/templates/workflows/` | 工作流提示词模板（explore / propose / apply / archive 等的 SkillTemplate + CommandTemplate 核心来源） |
| `src/commands/` | CLI 命令实现层（change.ts / validate.ts 等）；slash 命令与技能模板来自 `src/core/templates/workflows/*.ts` |
| `src/core/` | 核心逻辑（delta-spec 合并、artifact 校验等） |
| `schemas/spec-driven/` | spec-driven schema 定义 |
| `docs/` | 工作流文档（explore.md / commands.md / overview.md 等） |

### SuperPowers

- 仓库地址：`https://github.com/obra/superpowers.git`
- 默认分支：`main`
- 需要关注的路径：

| 路径 | 说明 |
|---|---|
| `skills/subagent-driven-development/` | subagent 驱动开发（对应 `goal-spec-apply`） |
| `skills/executing-plans/` | 计划批量执行（对应 `goal-spec-apply`） |
| `skills/test-driven-development/` | TDD 红绿重构（对应 `goal-spec-apply` 中的 TDD 分类） |
| `skills/dispatching-parallel-agents/` | 并行 subagent 调度（对应 `goal-spec-apply` 中的 pipeline 模式） |
| `skills/brainstorming/` | 头脑风暴（对应 `goal-spec-explore`） |
| `skills/writing-plans/` | 计划编写（对应 `goal-spec-propose` 中的 tasks 生成） |
| `skills/requesting-code-review/` | 代码审查请求（对应 `agents/ai-spec-reviewer.md`） |
| `skills/receiving-code-review/` | 审查反馈响应（对应 `goal-spec-apply` 中 implementer 对 review 的响应） |
| `skills/finishing-a-development-branch/` | 分支收尾（对应 `goal-spec-archive`） |

---

## 三、本地技能 ↔ 上游来源映射表

| 本地文件 | 上游来源 | 上游关键路径 |
|---|---|---|
| `ai/config/skills/goal-spec-explore/SKILL.md` | OpenSpec explore + SuperPowers brainstorming | OpenSpec `src/core/templates/workflows/`、`docs/explore.md`；SuperPowers `skills/brainstorming/` |
| `ai/config/skills/goal-spec-propose/SKILL.md` | OpenSpec propose + SuperPowers writing-plans | OpenSpec `src/core/templates/workflows/`；SuperPowers `skills/writing-plans/` |
| `ai/config/skills/goal-spec-propose/scripts/create-change.sh` | OpenSpec `openspec init` 逻辑 | OpenSpec `src/commands/`、`src/core/` |
| `ai/config/skills/goal-spec-apply/SKILL.md` | SuperPowers subagent-driven-development + executing-plans + TDD + dispatching-parallel-agents | SuperPowers `skills/subagent-driven-development/`、`skills/executing-plans/`、`skills/test-driven-development/`、`skills/dispatching-parallel-agents/` |
| `ai/config/skills/goal-spec-apply/references/implementer-prompt.md` | SuperPowers subagent 模式 | SuperPowers `skills/subagent-driven-development/` |
| `ai/config/skills/goal-spec-apply/references/code-reviewer-prompt.md` | SuperPowers requesting-code-review | SuperPowers `skills/requesting-code-review/` |
| `ai/config/skills/goal-spec-apply/references/task-reviewer-prompt.md` | SuperPowers requesting-code-review | SuperPowers `skills/requesting-code-review/` |
| `ai/config/skills/goal-spec-apply/scripts/review-package.sh` | SuperPowers diff 逻辑 | SuperPowers `skills/subagent-driven-development/` 中的 diff 脚本 |
| `ai/config/skills/goal-spec-apply/scripts/ledger.sh` | 本地原创 | 无上游对应 |
| `ai/config/skills/goal-spec-apply/scripts/task-brief.sh` | 本地原创 | 无上游对应 |
| `ai/config/skills/goal-spec-apply/scripts/check-progress.sh` | 本地原创 | 无上游对应 |
| `ai/config/skills/goal-spec-apply/scripts/mark-task-done.sh` | 本地原创 | 无上游对应 |
| `ai/config/skills/goal-spec-archive/SKILL.md` | OpenSpec archive + SuperPowers finishing-a-development-branch | OpenSpec `src/core/templates/workflows/`；SuperPowers `skills/finishing-a-development-branch/` |
| `ai/config/skills/goal-spec-archive/scripts/assess-delta-specs.sh` | OpenSpec delta-spec 合并逻辑 | OpenSpec `src/core/` |
| `ai/config/skills/goal-spec-archive/scripts/perform-archive.sh` | OpenSpec archive 逻辑 | OpenSpec `src/commands/` |
| `ai/config/skills/goal-spec-archive/scripts/check-completion.sh` | 本地原创 | 无上游对应 |
| `ai/config/skills/goal-spec-archive/scripts/list-changes.sh` | 本地原创 | 无上游对应 |
| `agents/ai-spec-implementer.md` | SuperPowers subagent 模式 | SuperPowers `skills/subagent-driven-development/` |
| `agents/ai-spec-reviewer.md` | SuperPowers requesting-code-review | SuperPowers `skills/requesting-code-review/` |
| `commands/ai-spec-apply.md` | OpenSpec `/opsx:apply` 命令 | OpenSpec `src/commands/` |
| `commands/ai-spec-propose.md` | OpenSpec `/opsx:propose` 命令 | OpenSpec `src/commands/` |
| `commands/ai-spec-explore.md` | OpenSpec `/opsx:explore` 命令 | OpenSpec `src/commands/` |
| `commands/ai-spec-archive.md` | OpenSpec `/opsx:archive` 命令 | OpenSpec `src/commands/` |

---

## 四、本地定制清单（必须保留，不可被上游覆盖）

以下定制内容是本项目对上游的改造，AI 在合并时**必须保留**这些内容，不得用上游版本覆盖：

### 4.1 架构层

1. **独立 Subagent 架构**：本项目使用 `agents/ai-spec-implementer.md` 和 `agents/ai-spec-reviewer.md` 两个独立 subagent，而非 SuperPowers 的内联模式。subagent 的 `mode: subagent` 配置、职责划分（implementer 写代码不 commit / reviewer 只读不写）必须保留。
2. **Command → Skill 包装模式**：`commands/ai-spec-*.md` 是薄包装，委托到 `ai/config/skills/goal-spec-*/SKILL.md`。这个分层结构必须保留。
3. **`disable-model-invocation: true`**：所有 spec 技能的 SKILL.md frontmatter 中都有此字段，确保技能只能手动触发，不可自动触发。必须保留。

### 4.2 路径与配置

4. **目录路径约定**：本项目使用 `ai/output/changes/`（变更目录）、`ai/output/specs/`（主 spec 目录）、`ai/config/spec-config.yaml`（配置文件）、`ai/config/skills/`（技能目录）。上游 OpenSpec 使用 `openspec/changes/`、`openspec/specs/`、`openspec/config.yaml`。本地路径必须保留。
5. **`.spec.yaml` 标记**：每个 change 目录下有 `.spec.yaml`，包含 `schema: spec-driven` 和 `created:` 日期。必须保留。
6. **`spec-config.yaml` 结构**：包含 `schema: spec-driven`、`context`（技术栈/约定）、`rules`（per-artifact 规则）。必须保留。

### 4.3 功能层

7. **多仓库 Git 支持**：`review-package.sh` 按文件所属 git repo 分组生成 diff（`git rev-parse --show-toplevel`），tracked 文件用 `git diff HEAD`，untracked 文件用 `git diff --no-index /dev/null`。这是本地定制，上游不支持多仓库。必须保留。
8. **持久化进度账本**：`ledger.sh` 管理的 `sdd/progress.md`，支持 `init` / `append` / `append-task` / `read` 子命令。这是本地原创，无上游对应。必须保留。
9. **Task Brief 机制**：`task-brief.sh` 从 `tasks.md` 中提取单个 task 的完整文本到 brief 文件。本地原创。必须保留。
10. **进度检查与标记**：`check-progress.sh`（统计 `- [ ]` vs `- [x]`）和 `mark-task-done.sh`（用 `sed -i.bak` 标记完成）。本地原创。必须保留。
11. **Module 同步**：`commands/ai-spec-sync.md` 支持将 spec/记忆同步到 `modules/<module>/ai/output/`。本地原创。必须保留。
12. **Controller 不碰 Git**：`goal-spec-apply` 的 controller 只负责调度，不执行 git 操作（implementer 写文件到磁盘，不 commit）。必须保留。

### 4.4 工作流层

13. **TDD 三分类**：Strict TDD（严格红绿重构）/ Exploratory TDD（探索性）/ Visual TDD（视觉/前端）。必须保留。
14. **Subagent 状态码**：`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`。必须保留。
15. **Two-stage Review**：每个 task 先做 SPEC 合规检查（✅/❌/⚠️），再做 QUALITY 检查（Approved/Issues with Critical/Important/Minor）。必须保留。
16. **Final Whole-branch Review**：所有 task 完成后，做一次全局审查（跨 task 一致性、spec 覆盖率、累积 minor findings）。必须保留。
17. **Serial / Pipeline 调度模式**：`goal-spec-apply` 支持串行和管道两种 subagent 调度模式。必须保留。

---

## 五、Last-Sync 版本追踪表

> AI 每次执行同步后，必须更新此表。首次执行时 commit SHA 为空，做全量对比。

| 仓库 | 上次同步 commit SHA | 同步日期 | 备注 |
|---|---|---|---|
| OpenSpec (Fission-AI/OpenSpec) | | | 首次同步，全量对比 |
| SuperPowers (obra/superpowers) | | | 首次同步，全量对比 |

---

## 六、更新工作流

请 AI Agent 严格按照以下步骤执行：

### 步骤 1：读取上次同步版本

从上方「Last-Sync 版本追踪表」读取每个仓库上次同步的 commit SHA。如果为空，则本次为首次同步，需要全量对比。

### 步骤 2：Clone 上游仓库到临时目录

```bash
TMPDIR="/var/folders/4f/kf11pfrs399945kw49qwywxm0000gn/T/opencode"
mkdir -p "$TMPDIR/upstream-sync"
git clone --depth 100 https://github.com/Fission-AI/OpenSpec.git "$TMPDIR/upstream-sync/openspec"
git clone --depth 100 https://github.com/obra/superpowers.git "$TMPDIR/upstream-sync/superpowers"
```

> 如果 `--depth 100` 不够（last-sync commit 超出深度），改为完整 clone（去掉 `--depth`）。

### 步骤 3：识别上游变更

对于每个仓库，在临时目录中执行：

```bash
# 如果有 last-sync commit：
git -C "$TMPDIR/upstream-sync/openspec" log <LAST_SYNC_SHA>..HEAD --oneline -- <KEY_PATHS>
git -C "$TMPDIR/upstream-sync/superpowers" log <LAST_SYNC_SHA>..HEAD --oneline -- <KEY_PATHS>

# 如果首次同步（无 last-sync），直接查看最近 30 条提交：
git -C "$TMPDIR/upstream-sync/openspec" log --oneline -30 -- <KEY_PATHS>
git -C "$TMPDIR/upstream-sync/superpowers" log --oneline -30 -- <KEY_PATHS>
```

`<KEY_PATHS>` 参见「二、上游仓库与关键路径」中的表格。

### 步骤 4：查看具体文件差异

对于每个有变更的关键路径：

```bash
# 如果有 last-sync commit：
git -C "$TMPDIR/upstream-sync/openspec" diff <LAST_SYNC_SHA>..HEAD -- src/core/templates/workflows/
git -C "$TMPDIR/upstream-sync/superpowers" diff <LAST_SYNC_SHA>..HEAD -- skills/subagent-driven-development/

# 如果首次同步，直接阅读当前版本的文件内容
```

### 步骤 5：按映射表定位本地文件

根据「三、本地技能 ↔ 上游来源映射表」，找到每个变更上游文件对应的本地文件。

对于映射表中标注为「本地原创」的文件（如 `ledger.sh`、`task-brief.sh`、`check-progress.sh`、`mark-task-done.sh`、`check-completion.sh`、`list-changes.sh`），**跳过，不做对比**。

### 步骤 6：智能合并

对每个需要更新的本地文件，执行智能合并：

1. **阅读上游变更**：理解上游改了什么、为什么改（查看 commit message 和 diff）。
2. **阅读本地文件**：理解当前本地版本的内容和定制点。
3. **判断合并策略**：
   - **移植**：上游新增的功能、修复的 bug、改进的指令——移植到本地文件中，但要适配本地的路径约定和架构。
   - **保留**：本地定制清单（第四节）中列出的所有内容——原封不动保留。
   - **跳过**：上游的变更与本地定制冲突，且本地方案更优——跳过，但在摘要中说明原因。
   - **适配**：上游变更了路径/变量名/结构——移植时适配为本地约定（如 `openspec/changes/` → `ai/output/changes/`）。
4. **执行修改**：使用 edit 工具修改本地文件。

### 步骤 7：输出变更摘要

完成所有合并后，输出一份变更摘要，格式如下：

```
## 上游同步变更摘要

### OpenSpec (<last-sync> → <new-commit>)

变更提交：
- <commit-sha> <commit-message>
- ...

文件级变更：
| 本地文件 | 变更类型 | 说明 |
|---|---|---|
| ai/config/skills/goal-spec-explore/SKILL.md | 移植 | 从上游移植了 XXX 改进 |
| ai/config/skills/goal-spec-propose/SKILL.md | 保留 | 上游改了 YYY，但与本地多仓库定制冲突，跳过 |
| ... | ... | ... |

### SuperPowers (<last-sync> → <new-commit>)

变更提交：
- <commit-sha> <commit-message>
- ...

文件级变更：
| 本地文件 | 变更类型 | 说明 |
|---|---|---|
| ... | ... | ... |

### 破坏性变更提示（如有）
- ⚠️ 上游 OpenSpec 重命名了 XXX 为 YYY，本地已适配，但请注意用户项目中的旧路径可能需要迁移
- ...

### 未变更的本地原创文件
- ai/config/skills/goal-spec-apply/scripts/ledger.sh（本地原创，跳过）
- ...
```

### 步骤 8：等待用户确认

将变更摘要展示给用户，等待用户确认后再继续。如果用户要求调整，按用户反馈修改。

### 步骤 9：更新 Last-Sync 表

用户确认后，更新本文件第五节的「Last-Sync 版本追踪表」：

```markdown
| 仓库 | 上次同步 commit SHA | 同步日期 | 备注 |
|---|---|---|---|
| OpenSpec (Fission-AI/OpenSpec) | <NEW_COMMIT_SHA> | <YYYY-MM-DD> | <简要说明本次同步了什么> |
| SuperPowers (obra/superpowers) | <NEW_COMMIT_SHA> | <YYYY-MM-DD> | <简要说明本次同步了什么> |
```

获取最新 commit SHA：

```bash
git -C "$TMPDIR/upstream-sync/openspec" rev-parse HEAD
git -C "$TMPDIR/upstream-sync/superpowers" rev-parse HEAD
```

### 步骤 10：清理临时目录

```bash
rm -rf "$TMPDIR/upstream-sync"
```

---

## 七、护栏规则

1. **不得修改本地定制清单（第四节）中列出的任何定制内容**。如果上游变更与定制冲突，跳过并在摘要中说明。此规则仅约束"同步时不得让上游覆盖本地定制"，**不阻止**对本地原创/定制文件的独立 bug 修复（例如对 `ledger.sh`、`review-package.sh` 等的修正）——这类修复不在同步工作流范围内，需另行处理。
2. **每个被修改的文件都必须在变更摘要中说明**「移植了什么」+「保留了什么」。
3. **如果上游有破坏性变更**（如重命名、路径变更、结构变更、schema 变更），必须在摘要中用 ⚠️ 高亮提示。
4. **不自动 commit**。所有修改留在工作区，由用户自行决定是否 commit。
5. **不修改 `commands/ai-spec-sync.md`**（本地原创，无上游对应）。
6. **不修改 `ai/config/spec-config.yaml`**（用户项目级配置，非技能文件）。
7. **如果上游新增了全新的技能/命令**（映射表中没有对应的本地文件），在摘要中报告，但不自动创建本地文件——由用户决定是否移植。
8. **如果对某个变更的合并策略不确定**，在摘要中标记为「⚠️ 需人工决策」，不做修改，附上上游变更内容和本地冲突点。
