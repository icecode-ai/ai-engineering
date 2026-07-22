# 微服务架构开发规范

微服务架构 = 轻量分层架构，单一可部署单元。与领域模型/业务中台的区别：**无独立 domain 模块**，业务逻辑较薄，`*Repository` 为具体类（非端口接口），`*Assembler` 直接 Command↔DO 转换（无领域实体中间层）。适合业务较简单、追求快速迭代的微服务。微服务间通过 `client` 模块的 `*OpenService` 接口（Dubbo/RPC）或 REST 通信。

## 分层规范

| 层 | 描述 | 规范文件 |
|---|---|---|
| client 开放层 | 对外发布 API jar（接口 + DTO），无 Lombok，供其他微服务消费 | `ai/config/rules/java/t-java-ms-client-guidelines.md` |
| facade 防腐层 | 二/三方服务隔离，返回 DTO，可移植 | `ai/config/rules/java/u-java-ms-facade-guidelines.md` |
| infrastructure 基础设施层 | Repository 具体类/DAO/DO/MessageProducer/多数据源，可调用 facade | `ai/config/rules/java/v-java-ms-infrastructure-guidelines.md` |
| application 应用编排层 | Module 编排，Assembler 直接 Command↔DO，业务逻辑较薄 | `ai/config/rules/java/w-java-ms-application-guidelines.md` |
| interface 接口层 | Controller/MQ监听/定时任务/OpenServiceImpl，返回 Result 包装 | `ai/config/rules/java/x-java-ms-interface-guidelines.md` |
| starter 启动层 | Application 主类、多环境配置、测试、代码生成器 | `ai/config/rules/java/y-java-ms-starter-guidelines.md` |

## 逻辑关系

### 编译期依赖方向（Maven 模块强制，单向）

```
client / facade   （基础模块，互不依赖）
   ▲        ▲
   │        │
   application ──► client, infrastructure
        ▲              ▲
        │              │
   interface ──► application, facade
        ▲
        │
   starter ──► interface
```

- 【强制】无 domain 模块；application 直接依赖 infrastructure 的 `*Repository` 具体类（非领域端口）。
- 【强制】client 禁止引入 Lombok 或新增依赖（不污染消费方环境）。

### 与 DDD/BMP 的关键区别

| 维度 | 微服务（MS） | DDD / BMP |
|---|---|---|
| domain 模块 | ❌ 无 | ✅ 有 |
| Repository | 具体类 `@Component`（infrastructure） | 端口接口（domain）+ Impl（infrastructure） |
| Assembler 转换 | Command ↔ DO 直接转换 | Command ↔ 领域聚合根 |
| 业务逻辑位置 | Module（application）+ Repository（infrastructure），事务脚本式 | 聚合根方法内聚 |
| 查询条件/消息类型 | `infrastructure.types` | `domain.types` |

### 运行时调用链（创建订单为例）

```
interface: Controller.create(@Valid Command)
  → application: Module.create(command)
      Assembler.from(command) → DO          ← 直接转 DO，无领域实体中间层
      repository.save(DO)                   ← 具体 Repository，非端口
      messageProducer.send(Message)
      EventBus.dispatchAsync(Event)
      Assembler.to(DO) → DTO
  ← 返回 DTO（Module 不包装 Result，Result 仅在 interface 层）
      ↓ 异步事件
application: @EventHandler Module.handler(Event) → 跨域编排（如库存扣减）
infrastructure: Repository.save
   Dao.insertSelective(DO)
   Facade.syncXXX(...)                     ← ACL 三方同步
```
