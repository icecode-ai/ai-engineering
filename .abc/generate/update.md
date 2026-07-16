## 一、背景

本项目的 spec 相关技能是基于两个上游开源项目改造融合而来：

1、OpenSpec
本地路径：`.abc/references/openspec-1-4-1`
git 地址：`https://github.com/Fission-AI/OpenSpec.git`

2、SuperPowers
本地路径：`.abc/references/superpowers-6-1-1`
git 地址：`https://github.com/obra/superpowers.git`

本项目在融合时做了大量本地化改造（多仓库支持、独立 subagent 架构、持久化进度账本、command→skill 包装模式等）
* 创建变更目录改成了 `ai/output/changes`
* 归档spec同步路径改成了 `ai/output/specs`
* 读取配置改成了 `ai/config/spec-config.yaml`
* 创建变更时，改成 `.spec.yaml`
* `ai/config/skills/goal-spec-propose/SKILL.md` 和 `ai/config/skills/goal-spec-apply/SKILL.md` 整合了 OpenSpec 和 SuperPowers 的 SubAgent 并行执行能力

## 二、需求

帮我看下整合和改造的怎么样，有问题没，有需要优化的地方没