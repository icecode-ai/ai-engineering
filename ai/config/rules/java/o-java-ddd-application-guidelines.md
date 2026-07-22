# 领域模型 - application 应用编排层规范

## 职责
流程编排层：将 DTO 与领域聚合根互转，调用聚合根行为，返回 DTO。不包含业务逻辑。承载领域事件的 `@EventHandler` 消费者。

## 包结构
```
{package}.{biz}.
  module        {Name}Module @Component
  assembler     {Name}Assembler @Mapper（DTO ↔ Domain）
  dto           {Name}Command / {Name}Query / {Name}DTO
  event         {Name}Event record implements Event
common.assembler  PageAssembler（分页转换）
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 编排服务 | `{Name}Module @Component`（不用 Service/ApplicationService） | `OrderModule` |
| 命令 | `{Name}{Action}Command extends Command` | `OrderCreateCommand` |
| 查询 | `{Name}SearchQuery extends PageQuery` | `OrderSearchQuery` |
| 结果 DTO | `{Name}DTO extends DTO` | `OrderDTO` |
| 领域事件 | `{Name}Event record implements Event` | `OrderEvent` |
| 转换器 | `{Name}Assembler @Mapper` | `OrderAssembler` |

## 规则
- 【强制】不含业务逻辑，基本不含 `if` 判断、计算逻辑。
- 【强制】尽量返回 DTO，不要包装 `Result`（`SingleResponse`/`PageResponse` 仅在 interface 层）。
- 【强制】禁止依赖 facade；外部交互须经 infrastructure 的 Repository（其内部调 facade）或领域端口。
- 【强制】异常走拦截器统一拦截，不 try-catch（弱依赖除外）。
- 【强制】Command/Query 字段用基本类型（避免 null 判断）；DTO 字段用包装类型。
- 【强制】跨域异步处理用 `@EventHandler(name=...)` 订阅领域事件，禁止跨域直接调用。
- 【推荐】转换用 MapStruct `@Mapper`，`INSTANCE = Mappers.getMapper(...)`。
- 【推荐】`@CleanLog(biz=..., method=...)` 声明式日志。

## 依赖
- 可依赖：`client`、`domain`、`clean-spring-cqrs-starter`、`clean-spring-log-starter`、validation、MapStruct、Lombok
- 禁止：`facade`、`infrastructure`、`interface`

## 示例
```java
@Component
public class OrderModule {
    @Resource private OrderRepository orderRepository;
    @Resource private OrderMessageProducer orderMessageProducer;

    @CleanLog(biz = "订单", method = "创建")
    public OrderDTO create(OrderCreateCommand command) {
        Order order = OrderAssembler.INSTANCE.from(command);
        order.create(orderRepository, orderMessageProducer);
        return OrderAssembler.INSTANCE.to(order);
    }

    @EventHandler(name = "库存扣减 - 订单消息监听")
    public void inventoryHandler(OrderEvent event) {
        // 跨域异步编排：查询库存并扣减
    }
}
```
