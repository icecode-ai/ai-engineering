https://icecode-ai.github.io/ai-engineering/#overview


# AI Engineering

> 语言：[English](README.md) | [中文](README_zh.md)

为 AI Agent 提供一套端到端工作流

- Git 多仓库管理
- 只读依赖隔离
- 增强 OpenSpec 工作流
- 自包含 Superpowers 风格执行（子代理驱动、TDD、两阶段审查）

## 安装

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

安装完成后，请**重启 Agent**，并执行 `/ai-env-init` 命令完成环境初始化。

> **在 workspace 根目录启动。** 务必在同时包含 `ai/` 与 `modules/` 的项目根目录启动 Agent——技能脚本路径均相对此根。
>
> **权限。** Claude Code 与 Qoder 的安装配置已预放行技能脚本与常规 git 写操作（`add`/`commit`/`stash`），工作流不再逐次弹窗；项目级 allow 规则在一次性 workspace trust 后生效。OpenCode 无需权限配置（bash 默认放行）。
>
> **环境要求。** 需 POSIX shell——macOS 与 Linux 自带 bash；Windows 请使用 Git Bash（随 Git for Windows 附带）或 WSL。`/ai-env-init` 用到的 `rsync` 等可选命令缺失时会自动跳过。

## 工程结构

执行 `/ai-env-init` 后，在你的项目中生成以下目录结构：

```text
{project}/                            # 主项目根目录
├── AGENTS.md                         # 主项目指导文件
├── ai/                               # AI 工作目录（过程产物）
│   ├── config/                       # 配置目录
│   │   ├── rules/                    # AI 执行规则与规范；相关时应用
│   │   │   └── {rule}.md
│   │   ├── skills/                   # 按需技能；仅当用户明确请求时调用
│   │   └── spec-config.yaml          # 规格配置文件
│   ├── input/                        # PRD、启始 Prompt、原型等入口 (用户唯一干预路径)
│   │   └── {user}/{seq}/{prd}.md
│   └── output/                       # 产物输出目录
│       ├── changes/                  # 变更目录 (explore/propose 产出)
│       │   └── archive/              # 归档变更历史；需要时或需求不明确时阅读
│       ├── memories/                 # 不良案例与经验；需要时阅读以获取长期上下文
│       │   └── {memory}.md
│       └── specs/                    # 系统行为规格的事实来源；需要时或需求不明确时阅读
│           └── {spec}/
├── modules/                          # 独立项目，每个都是独立 git 仓库 + 指导文件
│   └── {module}/                     # 模块 git 库
│       └── AGENTS.md
└── readonly-dependencies/            # 只读依赖引用；切勿修改
    └── {dependency}/                 # 依赖 git 库
```

## 流程

增强 OpenSpec 工作流，自包含 Superpowers 风格执行——子代理驱动开发、TDD、两阶段审查——实现从探索想法到归档的完整闭环。无需安装外部 Superpowers 插件。

```
1. explore  →  2. propose  →  3. apply  →  4. archive
```

1. **explore** — 探索想法，调研问题，明确需求
2. **propose** — 提出变更，一步生成全部产物
3. **apply** — 按 TDD 实现任务、审查、验证
4. **archive** — 归档已完成变更，同步规格

```bash
USER> /ai-spec-explore @ai/input/jim/0/prd.md
AI>   已进入探索模式，正在分析 PRD 并梳理需求...
USER> 创建变更 或 /ai-spec-propose
AI>   创建变更中..
USER> /ai-spec-apply
```

## 命令

五大类命令，覆盖环境、模块、Spec 工作流、Git 操作与目标编排。

### 环境指令

- **`/ai-env-init`** — 初始化或更新项目环境，创建标准目录结构并生成指导文件

### 模块和依赖指令

- **`/ai-module-add`** — 新增模块（git 仓库）到 modules/ 目录
- **`/ai-module-remove`** — 从 modules/ 目录中删除模块
- **`/ai-dependency-add`** — 新增依赖（git 仓库）到 readonly-dependencies/ 目录
- **`/ai-dependency-remove`** — 从 readonly-dependencies/ 目录中删除依赖

### Spec 指令

- **`/ai-spec-explore`** — 进入探索模式，梳理想法、调研问题、明确需求
- **`/ai-spec-propose`** — 提出新变更，一步创建并生成全部产物
- **`/ai-spec-apply`** — 按照 spec 变更实现任务，融入 TDD 与代码审查
- **`/ai-spec-archive`** — 归档已完成的变更
- **`/ai-spec-sync`** — 将 spec 内容同步到相关 module 模块

### Git 指令

- **`/ai-git-checkout`** — 拉取主项目、模块或依赖的指定分支
- **`/ai-git-pull`** — 拉取全部、主项目、模块或依赖的最新内容
- **`/ai-git-push`** — 提交并推送全部、主项目或模块的 Git 更改
- **`/ai-git-merge`** — 将主干代码合并到当前分支，支持全部、主项目、模块、依赖

### 目标指令

- **`/ai-goal-auto`** — 自动化流程：探索、创建变更、执行、测试，不涉及 git 提交/发布，过程不询问用户
- **`/ai-goal-e2e-explore`** — 探索式端到端流程：在基础设施、git 提交、发布、归档步骤询问用户确认
- **`/ai-goal-e2e-auto`** — 自动化端到端流程：探索、创建变更、执行、提交、发布、测试、归档，过程不询问用户

---

AI Engineering - MIT
