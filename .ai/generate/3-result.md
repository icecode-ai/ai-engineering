# OpenSpec vs Superpowers 对比分析 & `ai-spec-*` 优化建议

> 分析依据：克隆的 OpenSpec 源码（`.ai/references/openspec-src/`）、Superpowers 源码（`.ai/references/superpowers-src/`）、`.ai/references/openspec_superpowers.html`，以及当前 `commands/ai-spec-*.md` 五个指令。

## 0. 一句话结论

OpenSpec 与 Superpowers **不是竞品，而是互补的两层**：OpenSpec 管「规划与可追溯」（做什么 / 为什么 / 多轮归档），Superpowers 管「执行纪律与隔离」（怎么写好 / TDD / Review / SubAgent 隔离）。当前 `commands/ai-spec-*` 已经是「OpenSpec 结构 + 部分 Superpowers 纪律」的混合体，**但执行层仍是 OpenSpec 式的串行单主代理**——这是最大短板，应优先改造为 SubAgent 驱动。

---

## 1. 两套系统定位

| 维度 | OpenSpec (`/opsx:*`) | Superpowers (skills) |
|---|---|---|
| 本质 | Spec-Driven Development 框架（CLI + slash 命令） | Agentic skills 框架 + 软件开发方法论 |
| 形态 | CLI 引擎（`openspec` 二进制）+ 生成的 skill/命令文件 | 一组自动触发的 skill（`SKILL.md`） |
| 核心抽象 | change（独立目录）+ artifact DAG（proposal→specs→design→tasks）+ Delta/Archive | skill（brainstorming / writing-plans / TDD / subagent-driven-dev / ...） |
| 落盘产物 | `openspec/changes/<id>/{proposal,specs,design,tasks}.md` + `openspec/specs/` 主规范 | `docs/superpowers/specs/*-design.md` + `docs/superpowers/plans/*.md` |
| 多轮归档 | ✅ 每个 change 独立版本化目录，archive 后 Delta 合并进主规范 | ❌ last-write-wins，下一次 brainstorm 覆盖上一次 design |
| spec-of-truth 注入 | ✅ `openspec/AGENTS.md` 新会话自动注入 | ⚠️ 需手动让 AI 读 plan 文件 |
| 工程纪律内建 | ❌ 无 TDD / Review / Worktree（需靠 CLAUDE.md 或外挂 Superpowers） | ✅ TDD（先写测试否则删代码）/ code-review / verification / worktree / systematic-debugging |
| 执行模型 | **串行单主代理**（apply 循环遍历 tasks.md） | **SubAgent 驱动**（每任务一个 fresh subagent）+ 独立任务可并行 |

---

## 2. 三维度对比：探索 / 拆分 / 执行

### 2.1 探索任务（Explore）

| | OpenSpec `opsx:explore` | Superpowers `brainstorming` |
|---|---|---|
| 定位 | 「思考伙伴」，无固定产出，conversation 而非 generator | 「把想法变成 design doc」，目标导向 |
| 触发 | 用户主动 `/opsx:explore` | 自动触发（创建功能/组件前强制，HARD-GATE 禁止未批准就写码） |
| 流程 | 自由：读码、对比方案、画图、澄清需求；结晶后转 propose | 固定 9 步 checklist：探上下文 → 逐个提问 → 给 2-3 方案 → 分段呈现 design → 逐段批准 → 落盘 design doc → self-review → 用户复审 → 转 writing-plans |
| 产物 | 无（不创建 change、不写 artifact） | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`（git commit） |
| 约束 | 不写码、不写 artifact（可创建 AI artifact） | HARD-GATE：未呈现 design 并获批准前，禁止任何实现动作 |
| 风格 | 开放、发散，让问题形态自然浮现 | 苏格拉底式、收敛，一次一个问题、偏多选 |
| 适合场景 | 模糊问题、陌生代码库、想对比 tradeoff | 明确要做某功能、需要把需求固化成 design |

**结论**：两者职能重叠（都是「动手前先想清楚」），但取向不同。OpenSpec 更开放（适合「我有问题但没方案」），Superpowers 更收敛（适合「我要做 X，帮我把 design 钉死」）。**探索层大致持平**，选哪个取决于问题清晰度。对当前项目，`ai-spec-explore` 已采用 OpenSpec 式开放风格，合理。

### 2.2 拆分任务（Split）

| | OpenSpec `opsx:propose` / tasks artifact | Superpowers `writing-plans` |
|---|---|---|
| 结构 | **强约束四文件 DAG**：proposal → specs → design → tasks（依赖图拓扑排序，DAG 引擎驱动） | **单份 plan 文档**：design 已由 brainstorming 产出，plan 专注任务拆解 |
| 产物路径 | `openspec/changes/<id>/{proposal,specs,design,tasks}.md` | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` |
| tasks 粒度 | **粗**：`## 1. 任务组` + `- [ ] 1.1 描述`，要求「small enough to complete in one session」 | **细**：每步 2-5 分钟（写失败测试 / 跑测试看失败 / 写实现 / 跑测试看通过 / commit 各为一步） |
| 任务内容 | 文字描述为主，模板含占位符 | **精确文件路径 + 完整代码 + 验证命令 + 期望输出**，禁止占位符（"TBD/TODO/类似 Task N" 都是 plan failure） |
| 依赖表达 | artifact 间 DAG（specs requires proposal, tasks requires specs+design） | 任务内 Consumes/Produces 接口块（later task 靠此知道 earlier task 的函数签名） |
| 全局约束 | project config 的 `context`/`rules` 注入每份 artifact | plan header 的 `## Global Constraints`（版本下限、命名规则等，逐字抄自 spec） |
| 可追溯 | ✅ Delta spec（ADDED/MODIFIED/REMOVED/RENAMED）+ Archive 多轮版本化 | ❌ last-write-wins，新 plan 覆盖旧 plan |
| 执行就绪度 | 中（任务描述偏宏观，AI 需自行补实现细节） | **高**（plan 即「可照抄的剧本」，subagent 几乎是转写+测试） |

**结论**：
- **可追溯 / 多轮迭代**：OpenSpec 胜（Delta/Archive + spec-of-truth 注入是 Superpowers 没有的闭环环节）。
- **执行就绪度**：Superpowers 胜（2-5 分钟粒度 + 精确路径 + 完整代码 + 验证步骤，subagent 拿到就能干）。
- 二者**互补**：理想组合是 OpenSpec 的四文件结构 + Delta/Archive，配 Superpowers 的 plan 粒度作为 tasks.md 的填写标准。

### 2.3 执行任务（Execute）—— 并行 vs 串行 / SubAgent 调用

这是两者**差异最大**的一层。

| | OpenSpec `opsx:apply` | Superpowers `subagent-driven-development` | Superpowers `dispatching-parallel-agents` |
|---|---|---|---|
| 执行主体 | **主会话单代理**，循环遍历 tasks.md | **每任务派发一个 fresh subagent**（隔离上下文） | **多个 subagent 并发**（一条消息多个 Task 调用 = 并行） |
| 串/并行 | **纯串行**（一个任务做完 → 标记 → 下一个） | **任务间串行**（一次一个 implementer，禁止并行实现以免冲突）但每任务在隔离上下文 | **真并行**（2+ 独立问题域同时跑） |
| 上下文隔离 | ❌ 无（全在主会话，上下文随任务累积污染） | ✅ 强隔离（subagent 不继承会话历史，controller 精确构造其上下文；大件以文件传递而非粘贴） | ✅ 同左 |
| TDD | ❌ 不内建（需 CLAUDE.md 要求或外挂 Superpowers） | ✅ 每个 implementer subagent 走 RED-GREEN-REFACTOR | 视子代理任务而定 |
| Review | ❌ 不内建 | ✅ **两阶段**：每任务后 task-reviewer（spec 合规 + 代码质量双判定）+ 全分支 final review | 完成后 controller 整合 + 跑全套测试 |
| 失败处理 | pause 问用户 | 状态机：DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED，按情况补上下文/换更强模型/拆任务/升级人工 | 各 agent 独立返回 summary，controller 查冲突 |
| 持久化进度 | tasks.md 复选框 | **progress ledger**（`.superpowers/sdd/progress.md` 记 commit 区间，抗 compaction） | 无（一次性并行调度） |
| 模型选择 | 不区分 | ✅ 按任务复杂度选模型（机械任务用便宜模型，设计/判断用强模型，dispatch 时显式指定） | 各 agent 可指定模型 |
| Worktree 隔离 | ❌ 不内建 | ✅ 配合 `using-git-worktrees`（失败可整体丢弃，主分支零污染） | 通常在 worktree 内 |
| 适用 | 任务有依赖、需顺序执行 | 任务基本独立、同会话内快速迭代 | 多个无共享状态的独立问题域（如 3 个不同测试文件各自失败） |

**关键澄清**：OpenSpec 源码中的 "parallel" 一词（如 `openspec-parallel-merge-plan.md`、`bulk-archive`、`concepts.md` "Can create in parallel with specs"）指的是**并行 change（多人/多 change 文件夹同时进行）**或 **artifact DAG 上的并行创建**（design 与 specs 都只依赖 proposal，可并行生成），**不是 apply 阶段的并行任务执行**。`opsx:apply` 在执行层面是纯粹的串行单主代理——OpenSpec 源码中唯一的 Task 工具调用出现在 `archive-change.ts`，用于派发 `openspec-sync-specs` 子代理做 spec 同步，与任务实现无关。

**结论（执行层）**：**Superpowers 明显更优**。三个核心优势：
1. **上下文隔离**：fresh subagent per task，主会话上下文不被实现细节污染，长任务链也不会因上下文膨胀而漂移；
2. **两阶段 review 闸门**：spec 合规 + 代码质量双判定，配合 fix→re-review 循环，质量保障远强于单主代理「写完即过」；
3. **独立任务可并行**：`dispatching-parallel-agents` 对无依赖任务真并行，缩短墙钟时间。

---

## 3. 哪个更优（分维度裁决）

| 维度 | 更优 | 理由 |
|---|---|---|
| 探索 | 持平（OpenSpec 偏开放，Superpowers 偏收敛） | 取向差异，非优劣 |
| 拆分 | **各有胜负**：可追溯→OpenSpec；执行就绪度→Superpowers | 互补 |
| 执行 | **Superpowers** | 上下文隔离 + 两阶段 review + 并行能力 + 工程纪律内建，OpenSpec apply 全无 |
| 多轮迭代闭环 | **OpenSpec** | Delta/Archive + spec-of-truth 自动注入，Superpowers 做不到 |
| 跨工具兼容 | OpenSpec（CLI 引擎 + 25+ 工具适配） | Superpowers 也多工具，但 OpenSpec 的 schema 驱动更易定制 |

**总裁决**：二者**互补不互斥**。社区已有 `superpowers-bridge` schema（见 OpenSpec `docs/customization.md`）专门「把 OpenSpec 的 artifact 治理与 Superpowers 的执行 skill（brainstorming / writing-plans / TDD via subagents / code review）桥接」，印证这正是正确组合方向。当前项目的 `ai-spec-*` 命令其实已经在走这条路（OpenSpec 结构 + 引用 Superpowers 的 TDD/review/verification skill），**但执行层还停留在 OpenSpec 串行单代理**——这正是要补的短板。

---

## 4. 当前 `commands/ai-spec-*` 现状诊断

| 命令 | 来源 | 现状 | 问题 |
|---|---|---|---|
| `ai-spec-explore` | 改自 `opsx-explore` | 去掉 `openspec` CLI，改用 bash 检查 changes/；开放风格 | 基本无问题，与 OpenSpec 探索取向一致 |
| `ai-spec-propose` | 改自 `opsx-propose` | 去掉 CLI，bash 直接 mkdir + echo 模板；四文件 DAG；支持 `spec-config.yaml` 的 context/rules | tasks.md 模板粒度粗（任务组 + 描述），缺精确文件路径/验证步骤 |
| `ai-spec-apply` | 改自 `opsx-apply` | **去 CLI**；**已引用 Superpowers skill**（`/test-driven-development`、`/requesting-code-review`、`/verification-before-completion`）；TDD 三分类（Strict/Exploratory/Visual） | **执行串行单主代理**：5a TDD→5b 标记→5c review 全在主会话；无 SubAgent 隔离；无 progress ledger；无 worktree；单阶段 review；无并行 |
| `ai-spec-archive` | 改自 `opsx-archive` | 去 CLI，bash mv 到 archive/；Delta spec 合并逻辑保留 | 基本无问题 |
| `ai-spec-sync` | 项目新增 | 主项目 specs/memories 同步到 modules/ | OpenSpec/Superpowers 均无对应物，项目特有，无需改 |

**核心短板**：`ai-spec-apply` 虽引用了 Superpowers 的工程纪律 skill，但执行模型仍是 OpenSpec 式的「主会话循环」，**没有用 Task 工具派发 SubAgent**。这导致：
- 主会话上下文随任务累积污染，长 change 后期容易漂移/遗忘；
- 每任务的 review 只在主会话内单阶段做（`/requesting-code-review`），无独立 task-reviewer subagent 的 spec 合规 + 代码质量双判定；
- 独立任务无法并行，墙钟时间长；
- 无 progress ledger，compaction 后可能重派已完成任务（Superpowers 文档指出这是「观测到的最昂贵失败」）。

---

## 5. `commands/ai-spec-*` 优化建议（按优先级）

### P0 — `ai-spec-apply` 改 SubAgent 驱动执行（最高价值）

将「主会话逐任务实现」改为「主会话作 controller，每任务派发独立 implementer subagent」。对齐 Superpowers `subagent-driven-development`。

**改造要点**：
1. **每任务一个 fresh subagent**：用 Task 工具（`subagent_type: "general"`）派发，dispatch prompt 含：任务在项目中的位置（一句话）、task brief 文件路径（作为唯一需求源）、跨任务接口与决策、对歧义的预先裁决、report 文件路径与 report 契约。**不粘贴会话历史**。
2. **文件交接而非粘贴**：task brief 写到 `.ai/output/changes/<name>/.sdd/task-N-brief.md`，implementer 的报告写到 `task-N-report.md`；controller 只收回状态 + commit + 一行测试摘要 + concerns。避免大段文本驻留 controller 上下文。
3. **状态机处理**：DONE→生成 review package 并派 task-reviewer；DONE_WITH_CONCERNS→先读 concerns；NEEDS_CONTEXT→补上下文重派；BLOCKED→补上下文/换更强模型/拆任务/升级人工。**禁止**忽略升级或同模型无变更重试。
4. **任务间串行**：一次只派一个 implementer（避免文件冲突），但每个任务在隔离上下文执行——这已比当前串行单主代理大幅改善。
5. **进度 ledger**：每任务 review 通过后，在同一轮追加一行到 `.ai/output/changes/<name>/.sdd/progress.md`：`Task N: complete (commits <base7>..<head7>, review clean)`。compaction 后先读 ledger + `git log` 恢复进度，**不重派已完成任务**。

### P0 — 独立任务并行派发

在 `ai-spec-apply` 读取 tasks.md 后，**识别无依赖、无共享状态的任务组**（不同模块/不同测试文件），用**一条消息多个 Task 调用**并行派发（对齐 `dispatching-parallel-agents`：multiple dispatches in one response = parallel）。

**判定准则**：任务触及不同文件、无接口依赖、不会互相干扰 → 可并行；同文件/有 Consumes-Produces 依赖 → 串行。并行完成后 controller 整合、查冲突、跑全套测试。可在 tasks.md 模板里加 `**Parallelizable:** yes/no` 字段辅助判定。

### P1 — 两阶段 Review 闸门

替换当前「主会话内单阶段 `/requesting-code-review`」为：
1. **每任务 task-reviewer subagent**：拿到 task brief + implementer report + review package（`git diff` 写到文件），给两份判定——**spec 合规**（是否多建/少建）+ **代码质量**（Critical/Important/Minor）。Critical/Important 必须派 fix subagent 修复并 re-review，Minor 记入 ledger 交 final review triage。
2. **全分支 final review**：所有任务完成后派一个 code-reviewer subagent（用最强模型），review package 为 `MERGE_BASE..HEAD`，一次性收所有 findings 派**一个** fix subagent（不要每 finding 一个 fixer）。
3. **禁止预判**：dispatch prompt 不得写「不要 flag X」「最多算 Minor」——让 reviewer 自行 raise，controller 在 review loop 里裁决。

### P1 — Progress Ledger 抗 compaction

见 P0 第 5 点。这是「观测到的最昂贵失败」的防线，必须与 SubAgent 改造一起上。当前仅靠 tasks.md 复选框，compaction 后 controller 可能丢失「哪些任务已派发且 review 通过」的记忆。

### P2 — 可选 Git Worktree 隔离

`ai-spec-apply` 开头可选创建 git worktree（对齐 `using-git-worktrees`）：失败 change 可整体 `git worktree remove` 丢弃，主分支零污染。可设为 opt-in（命令参数或 `spec-config.yaml` 开关），因为 worktree 会增加初始化成本，小 change 不必。

### P2 — `ai-spec-propose` 任务粒度细化

tasks.md 模板从「任务组 + 描述」升级为 Superpowers `writing-plans` 风格：
- 每任务含 **Files**（Create/Modify/Test 精确路径）、**Interfaces**（Consumes/Produces 签名）、**Steps**（2-5 分钟一步：写失败测试→跑测试看失败→写实现→跑测试看通过→commit）；
- **禁止占位符**（TBD/TODO/类似 Task N/「加上合适的错误处理」均视为 plan failure）；
- plan header 加 `## Global Constraints`（逐字抄自 spec 的版本下限、命名规则等）。
- 这能让 P0 的 SubAgent 拿到「可照抄的剧本」，实现质量与速度双升。

### P3 — 按任务复杂度选模型

dispatch subagent 时显式指定模型（对齐 Superpowers）：机械任务（1-2 文件、spec 完整）用便宜模型；集成/判断任务用标准模型；架构/设计任务用最强模型；final review 用最强模型。**省成本、提速度**，但需平台支持按 dispatch 指定模型。

### 无需大改

- `ai-spec-explore`：开放风格合理，保持。
- `ai-spec-archive`：Delta 合并 + archive 逻辑完整，保持。
- `ai-spec-sync`：项目特有，OpenSpec/Superpowers 均无对应，保持。

---

## 6. 落地优先级与风险

**推荐实施顺序**：
1. **P0 SubAgent 驱动 + Progress Ledger**（一起上，ledger 是 SubAgent 改造的安全网）→ 验证一个真实 change 跑通。
2. **P0 独立任务并行** → 在 tasks.md 标注 parallelizable 字段后启用。
3. **P1 两阶段 Review** → 替换单阶段 review。
4. **P2 Worktree 隔离**（opt-in）+ **P2 任务粒度细化**（改 propose 模板）。
5. **P3 模型选择**（平台支持时）。

**风险与对策**：
- **SubAgent 上下文构造不当** → 严格用 task brief 文件作单一需求源，dispatch prompt 只放位置/接口/裁决/契约，不粘贴历史；参考 Superpowers `subagent-driven-development/implementer-prompt.md`。
- **并行任务文件冲突** → 仅对触及不同文件、无接口依赖的任务并行；并行后必跑全套测试 + 查冲突。
- **review 预判** → dispatch prompt 禁写「不要 flag X」，让 reviewer 自行 raise。
- **compaction 后重派** → ledger + `git log` 双保险，恢复时信任 ledger 胜过自身记忆。
- **Worktree 误删 ledger** → ledger 是 git-ignored scratch，`git clean -fdx` 会删；此时靠 `git log` 恢复。

---

## 7. 参考来源

- OpenSpec 源码：`schemas/spec-driven/schema.yaml`（artifact DAG + apply instruction）、`docs/opsx.md`（fluid actions 工作流）、`docs/explore.md`、`docs/how-commands-work.md`、`src/core/templates/workflows/archive-change.ts`（唯一 Task 工具调用 = sync-specs）、`docs/customization.md`（社区 `superpowers-bridge` schema）。
- Superpowers 源码：`skills/brainstorming/SKILL.md`（HARD-GATE + 9 步）、`skills/writing-plans/SKILL.md`（2-5 min 粒度 + 禁占位符 + Global Constraints）、`skills/subagent-driven-development/SKILL.md`（fresh subagent per task + 两阶段 review + progress ledger + 模型选择 + 状态机）、`skills/executing-plans/SKILL.md`（并行会话批执行）、`skills/dispatching-parallel-agents/SKILL.md`（真并行：一条消息多 Task 调用）。
- 对比文档：`.ai/references/openspec_superpowers.html`（第四层能力对比表 + 三层架构：OpenSpec 需求层 / Superpowers 纪律层 / Claude Code 执行层）。
- 当前指令：`commands/ai-spec-{explore,propose,apply,archive,sync}.md` 与参考版 `.ai/references/open_spec_commands/opsx-*.md`。
