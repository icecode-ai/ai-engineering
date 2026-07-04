## 需求

现有 `commands/ai-env-init.md` 指令中，生成的目录结构要做下调整

生成改成结构和顺序如下
- `ai` 不变
- 新增 `ai/config`
- `ai/baselines` 改成 `ai/config/rules`
- 新增 `ai/config/skills`
- `ai/config.yaml` 改成 `ai/config/spec-config.yaml`，内容生成逻辑和步骤不变
- `ai/archetypes` 改成 `ai/input`
- `ai/changes` 改成 `ai/output/changes`
- `ai/changes/archive` 改成 `ai/output/changes/archive`
- `ai/memories` 改成 `ai/output/memories`
- `ai/specs` 改成 `ai/output/specs`
- `modules` 不变
- `readonly-dependencies` 不变

## 实现

1. 逐步阅读 `commands` 目录下的指令，看下哪些需要修改，然后改掉
2. 阅读 `index.html` 和 `README` 文件，看下哪些需要修改，然后改掉