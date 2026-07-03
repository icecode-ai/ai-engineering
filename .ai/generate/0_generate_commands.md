帮我检查下 commands 目录下的指令包括指令内的bash脚本是否有问题，有问题按以下要求重新生成，当你向用户提出问题时，使用中文提问

## 背景

这套 ai engineering 可以被安装在各种 Agent 里面，比如 claude code、opencode、qoder 等

## 指令列表

| command              | 功能描述                                                                                       |
|----------------------|--------------------------------------------------------------------------------------------|
| ai-env-init          | 初始化或更新环境                                                                                   |
| ai-module-add        | 新增模块 (git 仓库)                                                                              |
| ai-module-remove     | 删除模块                                                                                       |
| ai-dependency-add    | 新增依赖 (git 仓库)                                                                              |
| ai-dependency-remove | 删除依赖                                                                                       |
| ai-git-checkout      | 拉取 MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency} 依赖 git 分支                          |
| ai-git-pull          | 拉取 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency} 依赖 git 最新内容            |
| ai-git-push          | 提交 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块 git 推送                              |
| ai-git-merge         | 将相关 git 库主干代码，合并到当前 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency} 依赖等分支 |
| ai-spec-explore      | Enter explore mode - think through ideas, investigate problems, clarify requirements       |
| ai-spec-propose      | Propose a new change - create it and generate all artifacts in one step                    |
| ai-spec-apply        | Implement tasks from a spec change                                                         |
| ai-spec-archive      | Archive a completed change in the experimental workflow                                    |
| ai-spec-sync         | 将 spec 内容，同步到相关 module 模块                                                                  |

## 公共规范

### 所有 command 文件写入 `commands/` 目录，带 `.md` 及 `YAML frontmatter`

```YAML
---
description: <精确描述>
argument-hint: ＜参数提示>（仅需要参数的 command）
---
```

### bash 脚本规范

* 脚本开头加 `set -euo pipefail`
* 项目根目录发现模式：从当前目录向上查找，直到存在 `ai/` 和 `modules/` 目录
  ```bash
  PROJECT_ROOT="$(pwd)"
  while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
  done
  [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
  cd "$PROJECT_ROOT"
  ```
* 写入多行文件时，使用 `{ echo '...'; echo '...'; } > "$file"` 写法，**禁止**使用 `cat > file <<'EOF'` 写法
* 使用脚本以避免 AI 的不稳定性

### 生成指导文件规范

指导文件分两种，生成方式不同：

#### 1. 模块指导文件（`modules/<module>/CLAUDE.md` 或 `AGENTS.md`）

自由提取方式：

* **Claude Code** → 生成 `CLAUDE.md`，执行 `/init` skill，如 skill 不存在则 fallback
  到以下提取方式。如已存在，重新提取事实并比较，仅在有实质性差异时更新，更新后 re-merge 用户特殊段落
* **其他 agent** → 生成 `AGENTS.md`，读取项目关键配置文件（README、manifests、build/test/lint config、CI
  workflows、已有指令文件），提取高信号、项目特有的事实（精确命令、测试捷径、架构边界、框架特性、与默认不同的约定）
* 模块指导文件**不含** `readonly-dependencies/` READ-ONLY 标记

#### 2. 主项目指导文件（根目录 `CLAUDE.md` 或 `AGENTS.md`）

**使用固定模板**，不使用自由提取，不使用 `/init` skill。主项目是 multi-project workspace，非可构建项目。

**模板**（固定部分保持原样，仅填充扫描到的表格）：

```markdown
# <ProjectName>

This is a multi-project workspace, **not** a buildable project. There is no build / test / lint / typecheck / task
runner at the root.

## Directory Structure

| Path | Description |
|------|-------------|
| `ai/specs/` | Project spec artifacts |
| `ai/baselines/` | Baseline standards collection |
| `ai/memories/` | Memory artifacts |
| `modules/` | Independent projects collection |
| `readonly-dependencies/` | Read-only knowledge base |

## modules

Each project under `modules/` is an independent git repository with its own git remote, toolchain, and `guidance file`.

| Module Name | Path | Guidance File | Description |
|-------------|------|---------------|-------------|
| <module> | `modules/<module>` | `modules/<module>/<AGENTS or CLAUDE>.md` | <description> |

## readonly-dependencies

Stores **read-only references** to private dependencies for local reading. Not part of the build; depended on by
modules.

| Dependency Name | Path | Description |
|-----------------|------|-------------|
| <dependency> | `readonly-dependencies/<dependency>` | <description> |

## baselines

Baseline standards

| Standard | Path | Description |
|----------|------|-------------|
| <standard> | `ai/baselines/<standard_file>` | <description> |

## Workflow

When working under `modules/`, read the standards in the following order:

1. The module's guidance file (`AGENTS.md`, or `CLAUDE.md` for Claude Code) at the module root
2. Standards under `ai/baselines/` relevant to the module's tech stack, if any

In case of conflict, the module guidance file takes precedence.

## Guardrails

- `readonly-dependencies/` is a read-only knowledge base: writing / modifying / git pushing / deleting files within it
  is prohibited.
```

**扫描脚本**（输出驱动表格填充）：

```bash
echo "PROJECT:$(basename "$PROJECT_ROOT")"
for d in "${PROJECT_ROOT}/modules"/*/; do
  [ -d "$d" ] || continue
  gf="AGENTS.md"; [ -f "${d}CLAUDE.md" ] && gf="CLAUDE.md"
  echo "M:$(basename "$d")|modules/$(basename "$d")|modules/$(basename "$d")/$gf"
done
for d in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
  [ -d "$d" ] || continue
  echo "D:$(basename "$d")|readonly-dependencies/$(basename "$d")"
done
for f in "${PROJECT_ROOT}/ai/baselines"/*; do
  [ -f "$f" ] || continue
  echo "B:$(basename "$f")|ai/baselines/$(basename "$f")"
done
```

**描述格式**（一行，≤100 字符，格式 `<purpose/domain> — <key tech stack>`）：

* 读取各条目的 `README.md`（modules & dependencies）或内容（baselines）
* 优先业务域 + 关键框架/语言，省略废话
* 示例：`E-commerce backend — Go/Gin/PostgreSQL` · `Coding standards — naming/formatting/structure`
* 无信息可用 → 目录名 / 文件名
* 空表格 → 仅保留表头行（保留 section）

#### 3. 通用规则（适用于两种指导文件）

* **create vs update**：目标文件不存在则创建；已存在则重新提取/重新生成并比较，仅
  wording/formatting/未变事实差异则不更新，有实质性差异（新增/变更命令、架构、增删模块或依赖）才更新
* **跨环境同步**：如另一环境的指导文件已存在（如目标 `CLAUDE.md` 但只有 `AGENTS.md`），以其为主要事实来源，生成目标文件，保留另一文件，两者保持同步
* **保留用户特殊内容**：更新时保留用户的特殊引用/段落（如开发规范、自定义约定），仅更新事实性、项目派生部分

### config.yaml 规范

* `ai-env-init` 生成 `ai/config.yaml`，包含 `schema`、`context`（可选）、`rules`（可选）字段
* `ai-spec-propose` 及 `ai-spec-explore` 创建变更时，加载 `ai/config.yaml`（如存在）：
    - `context` → 应用为**所有** artifact（proposal、specs、design、tasks）的背景
    - `rules[<artifactId>]` → 作为强制约束应用，有效 ID：`proposal`、`specs`、`design`、`tasks`
* 如文件不存在，正常进行（默认 schema 为 `spec-driven`）

### git 相关

* git 相关指令，在执行 git 命令时如有冲突，由 AI 自动解决，不询问用户
* **冲突解决流程**：
    1. 用 `git diff --name-only --diff-filter=U` 列出冲突文件
    2. 读取 `<<<<<<<`、`=======`、`>>>>>>>` 标记及周围代码，理解双方意图
    3. 编辑产生正确的合并结果：合并非重叠变更；真正冲突处选择语义正确的一方；移除所有冲突标记
    4. `git add <file>` 暂存已解决文件
    5. 如 merge 仍在进行中，`git commit` 完成合并
    6. 不 abort、不丢弃变更、不询问确认

## 指令详情

### 环境指令

#### ai-env-init

初始化或更新环境。当用户在 Agent 中，执行 `/ai-env-init` 命令后，AI 会执行初始化或更新项目环境

无需入参

第 1 步：用户项目下，判断以下目录是否存在，不存在则生成；其次添加 `readonly-dependencies` 到 `.gitignore`（注意：不要添加
`modules/` 到 `.gitignore`）

> 注：使用脚本以避免 AI 的不稳定性

- ai
- ai/archetypes
- ai/changes
- ai/changes/archive
- ai/memories
- ai/specs
- ai/baselines
- modules
- readonly-dependencies

第 2 步：用户项目下，生成 `ai/config.yaml`（如不存在），参考 `config.yaml 规范`

第 3 步：用户项目下，新建或更新 `各模块` 的指导文件，参考 `公共规范` 中的 `模块指导文件`

第 4 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的 `主项目指导文件`

### 模块和依赖指令

#### ai-module-add

添加 模块 到 `modules/` 目录

接收 2 个入参

* git 地址，必填
* 分支名称，可选，默认`主干分支`，或git命令执行时不用加分支参数

第 1 步：用户项目下，判断 `模块` 是否存在，如果已经存在，询问用户是否删除重新添加。如果是空模块空目录则代表不存在
第 2 步：用户项目下，新建或更新 `新增模块` 的指导文件，参考 `公共规范` 中的 `模块指导文件`
第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的 `主项目指导文件`

#### ai-module-remove

从 `modules/` 目录中删除模块

接收 1 个入参

* 模块名称，必填

第 1 步：用户项目下，从 `modules/` 目录中删除 `模块`
第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的 `主项目指导文件`

#### ai-dependency-add

添加 依赖 到 `readonly-dependencies/` 目录

接收 2 个入参

* git 地址，必填
* 分支名称，可选，默认`主干分支`，或git命令执行时不用加分支参数

第 1 步：用户项目下，判断 `依赖` 是否存在，如果已经存在，询问用户是否删除重新添加。如果是空依赖空目录则代表不存在
第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的 `主项目指导文件`

#### ai-dependency-remove

从 `readonly-dependencies/` 目录中删除依赖

接收 1 个入参

* 依赖名称，必填

第 1 步：用户项目下，从 `readonly-dependencies/` 目录中删除 `依赖`
第 2 步：用户项目下，新建或更新主项目的指导文件，参考 `公共规范` 中的 `主项目指导文件`

### spec 指令

`ai-spec-xx` 相关指令，是基于 `openspec` 进行改造，部分指令我做了增强

* `openspec` 开源库: https://github.com/Fission-AI/OpenSpec.git ，下载来阅读参考下
* `openspec` 生成的 `command` 指令在 `.ai/references/open_spec_commands` 目录下
* `openspec` 生成的 `command` 指令内容执行的 `openspec xx` 命令，我都替换成了 `bash脚本`
* `openspec` 生成的 `command` 指令内容中类似 `/opsx-xxx` 部分，我都替换成了 `/ai-spec-xx`

#### ai-spec-explore

Enter explore mode - think through ideas, investigate problems, clarify requirements

参考 `.ai/references/open_spec_commands/opsx-explore.md` 生成

增强部分

* 当探索完成时，询问用户是否需要创建变更，当用户回复类似 `创建`、`创建变更`、`创建变更吧` 等，直接创建变更，参考
  `commands/ai-spec-propose.md` 中的内容或 `.ai/references/open_spec_commands/opsx-propose.md` 中的内容（包含创建变更目录、生成所有
  artifact、加载 config.yaml 等完整流程）

#### ai-spec-propose

Propose a new change - create it and generate all artifacts in one step

参考 `.ai/references/open_spec_commands/opsx-propose.md` 生成

增强部分

* 创建 artifact 前，加载 `ai/config.yaml`（如存在），参考 `config.yaml 规范`

#### ai-spec-apply

Implement tasks from a spec change

参考 `.ai/references/open_spec_commands/opsx-apply.md` 生成

增强部分

* 在 apply 流程中融入 `superpowers` 的工程实践，`superpowers` 插件 (https://github.com/obra/superpowers.git)
  用户已经安装，你可以下载下来阅读参考下，参考 `.ai/references/openspec_superpowers.html` 中的实践
    - 实现任务时，使用 test-driven-development 技能的 TDD cycle，并对任务分类（Strict TDD / Exploratory / Visual）
    - 每个任务完成后 invoke requesting-code-review 技能
    - 全部任务完成后，invoke verification-before-completion 技能进行最终验证

#### ai-spec-archive

Archive a completed change in the experimental workflow

参考 `.ai/references/open_spec_commands/opsx-archive.md` 生成

增强部分

* 无

#### ai-spec-sync

将 spec 内容，同步到相关 `module` 模块

我自己实现的，没有参考 `openspec`

第 1 步：将 `ai/specs/` 目录下的 spec 内容，同步到对应的 `modules/{module}/ai/specs/` 下一份，注意点：此需是和这个
`{module}` 相关的内容，AI 要判断内容该写在已有文件进行更新，还是新增
第 2 步：将 `ai/memories/` 目录下的记忆内容，同步到对应的 `modules/{module}/ai/memories/` 下一份，注意点：需是和这个
`{module}` 相关的记忆，AI 要判断内容该写在已有文件进行更新，还是新增

### git指令

#### ai-git-checkout

拉取 MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency-name} 依赖 git 分支

接收 2 个入参

* 第 1 个入参 target：必填，MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称、{dependency-name} 依赖名
* 第 2 个入参 branch：分支，必填

如果 target 是 `MAIN`

* 第 1 步：用户项目下，拉取 `主项目` 对应的分支，如有本地变更冲突，自动 stash → 重试 checkout → stash pop，pop 冲突按 `公共规范`
  中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `{module-name}` 模块名称

* 第 1 步：用户项目下，拉取 `模块` 对应的分支，冲突处理同上
* 第 2 步：用户项目下，新建或更新 `target模块` 的指导文件
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `{dependency-name}` 依赖名称

* 第 1 步：用户项目下，拉取 `依赖` 对应的分支，冲突处理同上
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件

#### ai-git-pull

拉取 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency-name} 依赖 git 最新内容

接收 1 个入参

* 第1个入参 target：可选，ALL (全部，默认)、MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称、{dependency-name}
  依赖名

如果 target 是 `ALL`

* 第 1 步：用户项目下，拉取 `主项目`、`模块`、`依赖` 最新的内容，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `各模块` 的指导文件
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `MAIN`

* 第 1 步：用户项目下，拉取 `主项目` 最新的内容，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `{module-name}` 模块名称

* 第 1 步：用户项目下，拉取 `模块` 最新的内容，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `target模块` 的指导文件
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `{dependency-name}` 依赖名称

* 第 1 步：用户项目下，拉取 `依赖` 最新的内容，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件

#### ai-git-merge

将相关 git 库主干代码，合并到当前 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency-name}
依赖等分支

接收 1 个入参

* 第 1 个入参 target：可选，ALL (全部，默认)、MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称、{dependency-name}
  依赖名

主干分支动态检测：优先 `git symbolic-ref refs/remotes/origin/HEAD`，其次 `main`，再其次 `master`，默认 `main`

如果 target 是 `ALL`

* 第 1 步：用户项目下，将 `主项目`、`模块`、`依赖` 主干分支内容合并到当前分支，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `各模块` 的指导文件
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `MAIN`

* 第 1 步：用户项目下，将 `主项目` 主干分支内容合并到当前分支，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `{module-name}` 模块名称

* 第 1 步：用户项目下，将 `模块` 主干分支内容合并到当前分支，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `target模块` 的指导文件
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件

如果 target 是 `{dependency-name}` 依赖名称

* 第 1 步：用户项目下，将 `依赖` 主干分支内容合并到当前分支，冲突按 `公共规范` 中的冲突解决流程处理
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件

#### ai-git-push

提交 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块 git 推送

特别注意

* 不要提交 `readonly-dependencies` 目录下的任何内容

接收1个入参

* 第1个入参 target：可选，ALL (全部，默认)、MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称

如果 target 是 `ALL` 或 `MAIN`

* 第 1 步：判断 `ai/changes` 是否有 `未完成任务或变更`、`未归档的变更`，可以参考 `commands/ai-spec-xx.md` 中的 `bash脚本`
  如何判断任务或变更状态。如果都完成了，继续下一步；未完成，提示用户处理

以下步骤对 target 范围内的每个仓库执行（`ALL` = 主项目 + 所有模块，`MAIN` = 主项目，`{module-name}` = 指定模块）：

* 第 2 步：风险拦截提交 — 检查待提交文件（大文件 >10MB、可疑文件名如 `*.env`/`*.pem`/`*.key`/`id_rsa` 等、密钥内容、未忽略的构建产物如
  `node_modules/`/`dist/`/`build/` 等），逐个询问用户 include/exclude/abort；通过后暂存并提交，生成 conventional-commit
  message（`feat(scope): <summary> [ai-change: <change-name>]`）
* 第 3 步：pull 最新内容，冲突按 `公共规范` 中的冲突解决流程处理
* 第 4 步：将主干分支合并到当前分支，冲突按 `公共规范` 中的冲突解决流程处理
* 第 5 步：push 推送
