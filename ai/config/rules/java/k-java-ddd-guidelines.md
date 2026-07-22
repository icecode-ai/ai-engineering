# 领域模型架构开发规范

领域模型架构（DDD）= 严格分层 + 富领域模型 + 端口适配器（依赖倒置）。业务逻辑内聚在聚合根，领域层通过端口接口声明对外依赖，基础设施层提供实现。与业务中台架构的区别：**无扩展点（SPI）机制**，不区分业务变体插件。

## 分层规范

| 层 | 描述 | 规范文件 |
|---|---|---|
| client 开放层 | 对外发布 API jar（接口 + DTO），无 Lombok，供外部消费 | `ai/config/rules/java/l-java-ddd-client-guidelines.md` |
| domain 领域层 | 聚合根/值对象/领域服务/领域事件/Repository 端口，业务逻辑内聚 | `ai/config/rules/java/m-java-ddd-domain-guidelines.md` |
| facade 防腐层 | 二/三方服务隔离，返回 DTO，可移植 | `ai/config/rules/java/n-java-ddd-facade-guidelines.md` |
| application 应用编排层 | Module 编排，DTO↔Domain 转换，无业务逻辑，返回 DTO 不包装 Result | `ai/config/rules/java/o-java-ddd-application-guidelines.md` |
| infrastructure 基础设施层 | Repository 实现/DAO/DO/Converter/多数据源，可调用 facade | `ai/config/rules/java/p-java-ddd-infrastructure-guidelines.md` |
| interface 接口层 | Controller/MQ监听/定时任务/OpenServiceImpl，返回 Result 包装 | `ai/config/rules/java/q-java-ddd-interface-guidelines.md` |
| starter 启动层 | Application 主类、多环境配置、测试、代码生成器 | `ai/config/rules/java/r-java-ddd-starter-guidelines.md` |

## 逻辑关系

### 编译期依赖方向（Maven 模块强制，单向）

```
client / facade   （基础模块，互不依赖）
   ▲        ▲
   │        │
   application ──► client, domain
        ▲
        │
   domain   （纯核心，仅依赖 clean 框架 + spring-context/tx）
        ▲
        │
   infrastructure ──► domain, facade
        ▲
        │
   interface ──► application, facade
        ▲
        │
   starter ──► interface, infrastructure
```

- 【强制】domain 与 application 禁止依赖 facade。
- 【强制】client 禁止引入 Lombok 或新增依赖（不污染消费方环境）。

### 运行时调用链（创建订单为例）

```
interface: Controller.create(@Valid Command)
  → application: Module.create(command)
      Assembler.from(command) → 领域聚合根
      聚合根.create(repository, producer)        ← domain 业务逻辑内聚
         repository.save(聚合根)                  ← 端口
         producer.send(Message)                   ← 端口
         EventBus.dispatchAsync(Event)            ← 跨域异步事件
      Assembler.to(聚合根) → DTO
  ← 返回 DTO（Module 不包装 Result，Result 仅在 interface 层）
      ↓ 异步事件
application: @EventHandler Module.handler(Event) → 跨域编排（如库存扣减）
infrastructure: RepositoryImpl.save
   Converter.to(聚合根) → DO
   Dao.insertSelective(DO)
   Facade.syncXXX(...)                          ← ACL 三方同步
```

### 端口-适配器（依赖倒置）

| 端口（接口，定义在 domain/client） | 适配器（实现，在 infrastructure/interface） |
|---|---|
| `{Name}Repository extends Repository<E,ID>`（domain） | `{Name}RepositoryImpl @Component`（infrastructure） |
| `{Name}MessageProducer`（domain） | `{Name}MessageProducerImpl @Component`（infrastructure） |
| `{Name}OpenService`（client） | `{Name}OpenServiceImpl`（interface） |

领域层不感知 DB/MQ/三方服务，仅声明端口；基础设施层提供实现。与业务中台相比，无 `extension`/`extension-apps` 模块，业务变体差异须在聚合根内以策略/参数显式处理而非插件路由。
