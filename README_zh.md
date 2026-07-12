https://icecode-ai.github.io/ai-engineering/#overview


# AI Engineering

为 AI Agent 提供一套端到端工作流。

![端到端交付](https://img.shields.io/badge/端到端交付-blue)
![自进化](https://img.shields.io/badge/自进化-green)
![安全护栏](https://img.shields.io/badge/安全护栏-orange)
![断点续跑](https://img.shields.io/badge/断点续跑-yellow)
![按需扩展](https://img.shields.io/badge/按需扩展-purple)
![多仓统管](https://img.shields.io/badge/多仓统管-teal)

---

## 安装

AI Engineering 支持四种 AI Agent，请选择你使用的那一个并按对应说明操作。

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

> 安装完成后，请**重启 Agent**，并执行 `/ai-env-init` 命令完成环境初始化。

---

## 工程结构

执行 `/ai-env-init` 后，在你的项目中生成以下目录结构：

```
{project}/                            # 主项目根目录
├── AGENTS.md                         # 主项目指导文件
├── ai/                               # AI 工作目录（过程产物）
│   ├── config/                       # 配置目录
│   │   ├── rules/                    # AI 执行规则与规范 (需求相关时应用)
│   │   │   └── {rule}.md
│   │   ├── skills/                   # 按需技能 (仅当用户明确请求时调用)
│   │   └── spec-config.yaml          # 规格配置文件
│   ├── input/                        # PRD、启始 Prompt、原型等入口 (用户唯一工作目录)
│   │   └── {user}/{seq}/{prd}.md
│   └── output/                       # 过程产物输出目录
│       ├── changes/                  # 变更目录 (explore/propose 产出)
│       │   └── archive/              # 归档变更历史 (需要时或需求不明确时阅读)
│       ├── memories/                 # 不良案例与经验 (需要时阅读以获取长期上下文)
│       │   └── {memory}.md
│       └── specs/                    # 系统行为规格的事实来源 (需要时或需求不明确时阅读)
│           └── {spec}/
├── modules/                          # 模块 (结果产物)
│   └── {module}/                     # 模块 git 库
│       └── AGENTS.md
└── readonly-dependencies/            # 依赖 (只读，被modules引用的知识)
    └── {dependency}/                 # 依赖 git 库
```

---

## 流程

AI Engineering 提供四种流程，以匹配不同的自动化程度：

### 自动化端到端流程

全程自动，无需人工干预 · 含 Git 提交、发布、回归测试与归档。

```
USER> /ai-goal-e2e-auto @ai/input/jim/0/prd.md
AI>  全自动端到端流程启动，无需干预，正在执行...
AI>  流程完成，报告已生成：ai/output/changes/user-login/report.md
```

| 步骤 | 命令 | 模式 |
|------|------|------|
| 1 | explore — 探索需求，明确范围 | 自动 |
| 2 | propose — 创建变更，生成产物 | 自动 |
| 3 | apply — 实现变更，审查验证 | 自动 |
| 4 | push — 提交并推送代码 | 自动 |
| 5 | release — 发布到目标环境 | 自动 |
| 6 | test — 运行回归测试 | 自动 |
| 7 | archive — 归档变更，同步规格 | 自动 |

### 探索式端到端流程

关键步骤需用户确认 · 探索、Git 提交、发布、归档前会询问。

```
USER> /ai-goal-e2e-explore @ai/input/jim/0/prd.md
AI>  探索式端到端流程启动，关键步骤将询问你确认...
USER> 确认
AI>  已提交并发布，继续归档...
```

| 步骤 | 命令 | 模式 |
|------|------|------|
| 1 | explore — 探索需求，明确范围 | 确认 |
| 2 | propose — 创建变更，生成产物 | 自动 |
| 3 | apply — 实现变更，审查验证 | 自动 |
| 4 | push — 提交并推送代码 | 确认 |
| 5 | release — 发布到目标环境 | 确认 |
| 6 | test — 运行回归测试 | 自动 |
| 7 | archive — 归档变更，同步规格 | 确认 |

### 自动化流程

全程自动，但不含 Git 提交、发布与归档 · 产物留在本地由你提交。

```
USER> /ai-goal-auto @ai/input/jim/0/prd.md
AI>  自动化流程启动，不含 Git 提交与发布，正在执行...
AI>  实现完成，产物已留在本地，报告已生成
```

| 步骤 | 命令 | 模式 |
|------|------|------|
| 1 | explore — 探索需求，明确范围 | 自动 |
| 2 | propose — 创建变更，生成产物 | 自动 |
| 3 | apply — 实现变更，审查验证 | 自动 |
| 4 | test — 运行回归测试 | 自动 |

### 手动流程

手动流程 · 逐步执行 `/ai-spec-*` 命令，完全由你掌控。

```
USER> /ai-spec-explore @ai/input/jim/0/prd.md
AI>  已进入探索模式，正在分析 PRD 并梳理需求...
USER> 创建变更 或 /ai-spec-propose
AI>  创建变更中..
USER> /ai-spec-apply
```

| 步骤 | 命令 | 模式 |
|------|------|------|
| 1 | explore — 探索需求，明确范围 | 手动 |
| 2 | propose — 创建变更，生成产物 | 手动 |
| 3 | apply — 实现变更，审查验证 | 手动 |
| 4 | archive — 归档变更，同步规格 | 手动 |

---

## 命令

五大类命令，覆盖环境、模块、工作流、Spec 与 Git 操作。

### 环境指令

| 命令 | 说明 |
|------|------|
| `/ai-env-init` | 初始化或更新项目环境，创建标准目录结构并生成指导文件 |

### 模块和依赖指令

| 命令 | 说明 |
|------|------|
| `/ai-module-add` | 新增模块（git 仓库）到 `modules/` 目录 |
| `/ai-module-remove` | 从 `modules/` 目录中删除模块 |
| `/ai-dependency-add` | 新增依赖（git 仓库）到 `readonly-dependencies/` 目录 |
| `/ai-dependency-remove` | 从 `readonly-dependencies/` 目录中删除依赖 |

### 工作流指令

| 命令 | 说明 |
|------|------|
| `/ai-goal-e2e-auto` | 自动化端到端流程：探索、创建变更、执行、提交、发布、测试、归档，过程不询问用户 |
| `/ai-goal-e2e-explore` | 探索式端到端流程：在基础设施、git 提交、发布、归档步骤询问用户确认 |
| `/ai-goal-auto` | 自动化流程：探索、创建变更、执行、测试，不涉及 git 提交/发布，过程不询问用户 |

### Spec 指令

| 命令 | 说明 |
|------|------|
| `/ai-spec-explore` | 进入探索模式，梳理想法、调研问题、明确需求 |
| `/ai-spec-propose` | 提出新变更，一步创建并生成全部产物 |
| `/ai-spec-apply` | 按照 spec 变更实现任务，融入 TDD 与代码审查 |
| `/ai-spec-archive` | 归档已完成的变更 |
| `/ai-spec-sync` | 将 spec 内容同步到相关 module 模块 |

### Git 指令

| 命令 | 说明 |
|------|------|
| `/ai-git-checkout` | 拉取主项目、模块或依赖的指定分支 |
| `/ai-git-pull` | 拉取全部、主项目、模块或依赖的最新内容 |
| `/ai-git-push` | 提交并推送全部、主项目或模块的 Git 更改 |
| `/ai-git-merge` | 将主干代码合并到当前分支，支持全部、主项目、模块、依赖 |

---

## 许可证

MIT
