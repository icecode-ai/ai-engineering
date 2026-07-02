`commonds/` 目录下的指令，生成主项目指导文件部分，我想按以下模版生成

```markdown
# <ProjectName>

This is a multi-project workspace, **not** a buildable project. There is no build / test / lint / typecheck / task runner at the root.

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

Stores **read-only references** to private dependencies for local reading. Not part of the build; depended on by modules.

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

1. Module guidance file: `modules/<name>/AGENTS.md`
2. Standards under `ai/baselines/` relevant to the module's tech stack, if any

In case of conflict, the module guidance file takes precedence.

## Guardrails

- `readonly-dependencies/` is a read-only knowledge base: writing / modifying / git pushing / deleting files within it is prohibited.
```

生成步骤
1. `<ProjectName>` 下面的描述不变
2. `Directory Structure` 部分包括描述不变
3. `modules` 扫描 `modules/` 目录下的模块，完善表格内容
4. `readonly-dependencies` 扫描 `readonly-dependencies/` 目录下的依赖，完善表格内容
5. `baselines` 扫描 `ai/baselines/` 目录下的规范，完善表格内容
6. `Workflow` 部分包括描述不变
7. `Guardrails` 部分包括描述不变

其他要求，看下生成主项目指导文件现有部分，以下要求保留
1. 如果用户用的是 `claude code`，新建 或 更新 `CLAUDE.md`
2. 如果用户用的是 `其他agent`，则新建 或 更新 `AGENTS.md`
3. 如果内容变化不大则不更新


看下 `commonds/` 目录下的哪些指令需要修改，统一改掉