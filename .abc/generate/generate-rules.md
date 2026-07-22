帮我生成以下开发规范

## `ai/config/rules/java-development-guidelines.md`

内容模版

```markdown
# Java 开发规范

包含两部分
1. 通用规范：Java 通用开发规范
2. 特定架构规范：基于特定架构的规范

约束力强弱及故障敏感性
{这地方参考 `.abc/references/alibaba-java-specification.md` 中的内容，注意格式结构化，去掉没用啰嗦的描述}

## 通用规范

{这地方参考 `.abc/references/alibaba-java-specification.md` 中的内容，注意格式结构化，去掉没用啰嗦的描述}

## 特定架构规范

{识别架构模式}

｜架构模式｜识别方式｜规范文件｜
｜---｜---｜---｜
｜业务中台架构｜{扫描 `.abc/references/sample-clean-bmp` 下的项目分层划分}｜`ai/config/rules/java/a-java-bmp-guidelines.md`｜
｜领域模型架构｜{扫描 `.abc/references/sample-clean-ddd` 下的项目分层划分}｜`ai/config/rules/java/k-java-ddd-guidelines.md`｜
｜微服务架构｜{扫描 `.abc/references/sample-clean-ms` 下的项目分层划分}｜`ai/config/rules/java/s-java-ms-guidelines.md`｜

```

## 引用文件 

扫描 `.abc/references/sample-clean-bmp`、`.abc/references/sample-clean-ddd`、`.abc/references/sample-clean-ms` 总结规范

依次生成引用文件规范，按序号 `a - z` 开头索引

`ai/config/rules/java/a-java-bmp-guidelines.md`
`ai/config/rules/java/k-java-ddd-guidelines.md`
`ai/config/rules/java/s-java-ms-guidelines.md`

除了上面三个以外，还要包含它们的子模块规范
比如 `ai/config/rules/java/b-java-bmp-application-guidelines.md`

```markdown

# 业务中台架构开发规范

## 分成规范

｜层｜描述｜规范文件｜
｜---｜---｜---｜
｜application层｜{描述}｜`ai/config/rules/java/b-java-bmp-application-guidelines.md`｜
｜domain层｜{描述}｜`ai/config/rules/java/c-java-bmp-domain-guidelines.md`｜
｜xxx｜{描述}｜`ai/config/rules/java/<seq>-java-bmp-domain-guidelines.md`｜

## 逻辑关系

{调用依赖关系}

```

