帮我检查下 commands 目录下的指令包括指令内的bash脚本是否有问题，有问题按以下要求重新生成，当你向用户提出问题时，使用中文提问

## 背景

这套 ai engineering 可以被安装在各种 Agent 里面，比如 claude code、opencode、qoder 等

## 指令列表

| command | 功能描述                                                                                      |
|---|-------------------------------------------------------------------------------------------|
| ai-env-init | 初始化或更新环境                                                                                  |
| ai-module-add | 新增模块 (git 仓库)                                                                             |
| ai-module-remove | 删除模块                                                                                      |
| ai-dependency-add | 新增依赖 (git 仓库)                                                                             |
| ai-dependency-remove | 删除依赖                                                                                      |
| ai-git-checkout | 拉取 MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency} 依赖 git 分支                         |
| ai-git-pull | 拉取 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency} 依赖 git 最新内容           |
| ai-git-push | 提交 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块 git 推送                             |
| ai-git-merge | 将相关 git 库主干代码，合并到当前 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency} 依赖等分支 |
| ai-spec-explore | Enter explore mode - think through ideas, investigate problems, clarify requirements      |
| ai-spec-propose | Propose a new change - create it and generate all artifacts in one step                   |
| ai-spec-apply | Implement tasks from a spec change                                                        |
| ai-spec-archive | Archive a completed change in the experimental workflow                                   |
| ai-spec-sync | 将 spec 内容，同步到相关 module 模块                                                                 |

## 公共规范

### 所有 command 文件写入 `commands/` 目录，带 `.md` 及 `YAML frontmatter`

```YAML
---
description: <精确描述>
argument-hint: ＜参数提示>（仅需要参数的 command）
---
```

### 生成指导文件规范，主项目和子模块生成指导文件要求和提示词

#### 1. 要求
* 如果用户用的是 `claude code`，新建 或 更新 `CLAUDE.md`，`claude code` agent 内部执行 `/init` skill，如果 skill 不存在，fallback 到`其他agent`的生成方式。如果 `CLAUDE.md` 不存在，则新建；如果已经存在，查看`主项目或子模块`和`CLAUDE.md`的描述差异，如果变化大不则不更新，如果变化大，则更新，注意保留用户的特殊引用，比如 `开发规范` 等
* 如果用户用的是 `其他agent`，则新建 或 更新 `主项目或子模块` 中的 `AGENTS.md`，`其他agent` 内部执行简单描述，可以看下 `提示词格式参考`部分。如果 `AGENTS.md` 不存在，则新建，如果已经存在，查看`主项目或子模块`和`AGENTS.md`的描述差异，如果变化大不则不更新，如果变化大，则更新，注意保留用户的特殊引用，比如 `开发规范` 等
* `主项目`中的 `CLAUDE.md` 或 `AGENTS.md` 文件必须标注：`readonly-dependencies/` READ-ONLY 知识库，禁止写入、修改、删除。

#### 2. 提示词格式参考（仅供参考，以下是`主项目`生成指导文件提示词示例，`非主项目` 没有 `Include` 部分）

```markdown
4. **Re-generate the main project guidance file**

   Detect the target guidance file (`CLAUDE.md` for Claude Code, `AGENTS.md` for other agents) at the project root.
    
    - **Claude Code**: If the `/init` skill is available, execute it to create or update `CLAUDE.md`. If no `/init` skill is available, fall back to the opencode-style generation below.
    - **Other agents** (and Claude Code fallback): Read the project's key configuration files (README, manifests, build/test/lint config, CI workflows, existing instruction files) and extract only high-signal, project-specific facts (exact commands, test shortcuts, architecture boundaries, framework quirks, conventions that differ from defaults).

   Include:
    - **Required marking**: `readonly-dependencies/` is a READ-ONLY knowledge base — never write, modify, or delete — must be explicitly marked

   Follow the dual-environment and incremental strategies:
    - If the target file already exists in another environment (e.g. `AGENTS.md` exists but targeting `CLAUDE.md`), use it as the primary fact source to generate the target
    - **Incremental update**: If the target already exists, re-extract facts and compare with existing content. Update ONLY on substantive differences (new/changed commands, architecture, added/removed modules or dependencies); keep as-is (do not rewrite) if only wording, formatting, or unchanged facts differ
    - **Preserve user-specific content**: When updating, preserve the user's special references/sections (e.g. development specs, custom conventions) — only update the factual, project-derived portions
```

### git 相关

* git 相关的指令，在执行 git 命令时，如果有 git 冲突，由 AI 解决

## 指令详情

### 环境指令

#### ai-env-init

初始化或更新环境。当用户在 Agent 中，执行 `/ai-env-init` 命令后，AI 会执行初始化或更新项目环境

无需入参

第 1 步：判断用户项目下，以下目录是否存在，不存在则生成，其次添加 `readonly-dependencies` 目录到 `gitignore`

> 注：使用脚本以避免 AI 的不稳定性

- ai
- ai/archetypes
- ai/changes
- ai/changes/archive
- ai/memories
- ai/specs
- modules
- readonly-dependencies

第 2 步：用户项目下，新建或更新 `各模块` 的指导文件，参考 `公共规范` 中的要求

第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

### 模块和依赖指令

#### ai-module-add
添加 模块 到 `modules/` 目录

接收 2 个入参
* git 地址，必填
* 分支名称，可选，默认`主干分支`，或git命令执行时不用加分支参数

第 1 步：用户项目下，判断 `模块` 是否存在，如果已经存在，询问用户是否删除重新添加。如果是空模块空目录则代表不存在
第 2 步：用户项目下，新建或更新 `新增模块` 的指导文件，参考 `公共规范` 中的要求
第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

#### ai-module-remove

从 `modules/` 目录中删除模块

接收 1 个入参
* 模块名称，必填

第 1 步：用户项目下，从 `modules/` 目录中删除 `模块`
第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

#### ai-dependency-add

添加 依赖 到 `readonly-dependencies/` 目录

接收 2 个入参
* git 地址，必填
* 分支名称，可选，默认`主干分支`，或git命令执行时不用加分支参数

第 1 步：用户项目下，判断 `依赖` 是否存在，如果已经存在，询问用户是否删除重新添加。如果是空依赖空目录则代表不存在
第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

#### ai-dependency-remove

从 `readonly-dependencies/` 目录中删除依赖

接收 1 个入参
* 依赖名称，必填

第 1 步：用户项目下，从 `readonly-dependencies/` 目录中删除 `依赖`
第 2 步：用户项目下，新建或更新主项目的指导文件，参考 `公共规范` 中的要求

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
* 当探索完成时，询问用户是否需要创建变更，当用户回复类似 `创建`、`创建变更`、`创建变更吧` 等，直接创建，参考 `commands/ai-spec-propose.md` 中的内容或 `.ai/references/open_spec_commands/opsx-propose.md` 中的内容

#### ai-spec-propose

Propose a new change - create it and generate all artifacts in one step

#### ai-spec-explore

Enter explore mode - think through ideas, investigate problems, clarify requirements

参考 `.ai/references/open_spec_commands/opsx-propose.md` 生成

增强部分
* 无

#### ai-spec-apply

Implement tasks from a spec change

参考 `.ai/references/open_spec_commands/opsx-apply.md` 生成

增强部分
* 在 apply 流程中融入 `superpowers` 的工程实践，`superpowers` 插件 (https://github.com/obra/superpowers.git) 用户已经安装，你可以下载下来阅读参考下，参考 `.ai/references/openspec_superpowers.html` 中的实践
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

第 1 步：将 `ai/specs/` 目录下的 spec 内容，同步到对应的 `modules/{module}/ai/specs/` 下一份，注意点：此需是和这个 `{module}` 相关的内容，AI 要判断内容该写在已有文件进行更新，还是新增
第 2 步：将 `ai/memories/` 目录下的记忆内容，同步到对应的 `modules/{module}/ai/memories/` 下一份，注意点：需是和这个 `{module}` 相关的记忆，AI 要判断内容该写在已有文件进行更新，还是新增

### git指令

#### ai-git-checkout

拉取 MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency-name} 依赖 git 分支

接收 2 个入参
* 第 1 个入参 target：必填，MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称、{dependency-name} 依赖名
* 第 2 个入参 branch：分支，必填

如果 target 是 `MAIN`
* 第 1 步：用户项目下，拉取 `主项目` 对应的分支
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target 是 `{module-name}` 模块名称
* 第 1 步：用户项目下，拉取 `模块` 对应的分支
* 第 2 步：用户项目下，新建或更新 `target模块` 的指导文件，参考 `公共规范` 中的要求
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target `{dependency-name}` 依赖名称
* 第 1 步：用户项目下，拉取 `依赖` 对应的分支
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

#### ai-git-pull

拉取 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency-name} 依赖 git 最新内容

接收 1 个入参
* 第1个入参 target：可选，ALL (全部，默认)、MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称、{dependency-name} 依赖名

如果 target 是 `ALL`
* 第 1 步：用户项目下，拉取 `主项目`、`模块`、`依赖` 最新的内容
* 第 2 步：用户项目下，新建或更新 `各模块` 的指导文件，参考 `公共规范` 中的要求
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target 是 `MAIN`
* 第 1 步：用户项目下，拉取 `主项目` 最新的内容
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target 是 `{module-name}` 模块名称
* 第 1 步：用户项目下，拉取 `模块` 最新的内容
* 第 2 步：用户项目下，新建或更新 `target模块` 的指导文件，参考 `公共规范` 中的要求
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target `{dependency-name}` 依赖名称
* 第 1 步：用户项目下，拉取 `依赖` 最新的内容
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

#### ai-git-merge

将相关 git 库主干代码，合并到当前 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块、{dependency-name} 依赖等分支

接收 1 个入参
* 第 1 个入参 target：可选，ALL (全部，默认)、MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称、{dependency-name} 依赖名

如果 target 是 `ALL`
* 第 1 步：用户项目下，将 `主项目`、`模块`、`依赖` 主干分支内容合并到前分支
* 第 2 步：用户项目下，新建或更新 `各模块` 的指导文件，参考 `公共规范` 中的要求
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target 是 `MAIN`
* 第 1 步：用户项目下，将 `主项目` 主干分支内容合并到前分支
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target 是 `{module-name}` 模块名称
* 第 1 步：用户项目下，将 `模块` 主干分支内容合并到前分支
* 第 2 步：用户项目下，新建或更新 `target模块` 的指导文件，参考 `公共规范` 中的要求
* 第 3 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

如果 target `{dependency-name}` 依赖名称
* 第 1 步：用户项目下，将 `依赖` 主干分支内容合并到前分支
* 第 2 步：用户项目下，新建或更新 `主项目` 的指导文件，参考 `公共规范` 中的要求

#### ai-git-push

提交 ALL (全部，默认)、MAIN (当前项目，根目录git为主项目)、{module-name} 模块 git 推送

特别注意
* 不要提交 `readonly-dependencies` 目录下的任何内容 

接收1个入参
* 第1个入参 target：可选，ALL (全部，默认)、MAIN (用户当前项目，根目录git为主项目)、{module-name} 模块名称

如果 target 是 `ALL` 或 `MAIN`
* 第 1 步：判断 `ai/changes` 是否有 `未完成任务或变更`、`未归档的变更`，可以参考 `commands/ai-spec-xx.md` 中的 `bash脚本` 如何判断任务或变更状态 
* 第 2 步：如果都完成了，则进行提交；未完成，提示用户处理

如果 target 是 `{module-name}` 模块名称
* 第 1 步：提交执行 push 推送
