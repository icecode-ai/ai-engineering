# 微服务架构开发规范

微服务架构 = 轻量分层架构，单一可部署单元。业务逻辑较薄，`*Repository` 为具体类（非端口接口），`*Assembler` 直接 Command↔DO 转换（无领域实体中间层）。适合业务较简单、追求快速迭代的微服务。微服务间通过 `client` 模块的 `*OpenService` 接口（Dubbo/RPC）或 REST 通信

## Maven 多模块分层规范

| 层 | 描述 | 规范文件 |
|---|---|---|
| facade 防腐层 | 二/三方服务隔离，返回 DTO，可移植 | `ai/config/rules/java/ms/java-ms-facade-guidelines.md` |
| infrastructure 基础设施层 | Repository 具体类/Dao/DO/MessageProducer/多数据源 | `ai/config/rules/java/ms/java-ms-infrastructure-guidelines.md` |
| application 应用编排层 | 业务逻辑处理 | `ai/config/rules/java/ms/java-ms-application-guidelines.md` |
| interface 接口层 | Web接口/RPC服务/MQ监听/定时任务等 | `ai/config/rules/java/ms/java-ms-interface-guidelines.md` |
| client 开放层 | 对外发布 API jar（接口 + DTO），无 Lombok，供其他微服务消费 | `ai/config/rules/java/ms/java-ms-client-guidelines.md` |
| starter 启动层 | Application 主类、多环境配置、测试 | `ai/config/rules/java/ms/java-ms-starter-guidelines.md` |

## Maven 多模块核心逻辑关系

- `starter 启动层` 控制整个应用的启动，仅包含 启动类、应用配置、测试
- `interface 接口层` > `application 应用编排层` > `infrastructure 基础设施层`、`facade 防腐层`
- 【可选】`infrastructure 基础设施层` > `facade 防腐层`

## 其他规范

- 【推荐】校验逻辑，尽量使用 `Assert` 校验，比如：`Assert.isTrue`，减少 if 判断

- 【强制】二/三方服务依赖，比如依赖的 RPC、HTTP 服务等，统一放在 `facade 防腐层`，在 `facade 防腐层` 中定义依赖和版本号
- 【强制】如果用户需求中，没有明确说明需要开放接口，不要在 `client 开放层` 定义接口，接口放在 `interface 接口层`，`interface 接口层` 需要的出入参 `Query`、`Command`、`DTO` 放在 `application 应用编排层`
- 【强制】所有测试放在 `starter 启动层`