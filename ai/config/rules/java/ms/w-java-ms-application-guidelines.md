# 微服务 - application 应用编排层规范

## 职责
流程编排层：将 Command 与 DO 互转（**无领域实体中间层**），调用 Repository 持久化，发送消息与领域事件，返回 DTO。与 DDD/BMP 的区别：业务逻辑较薄，事务脚本式编排，直接操作 `*DO`。

## 包结构
```
{package}.{biz}.
  module        {Name}Module @Component
  assembler     {Name}Assembler @Mapper（Command ↔ DO，直接转换）
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
| 转换器 | `{Name}Assembler @Mapper`（Command↔DO） | `OrderAssembler` |

## 规则
- 【强制】`Assembler` 直接做 Command↔DO 转换（无领域聚合根中间层），与 DDD/BMP 的 Command↔领域实体不同。
- 【强制】尽量返回 DTO，不要包装 `Result`（`SingleResponse`/`PageResponse` 仅在 interface 层）。
- 【强制】禁止依赖 facade；外部交互须经 infrastructure 的 Repository（其内部调 facade）。
- 【强制】异常走拦截器统一拦截，不 try-catch（弱依赖除外）。
- 【强制】Command/Query 字段用基本类型（避免 null 判断）；DTO 字段用包装类型。
- 【强制】跨域异步处理用 `@EventHandler(name=...)` 订阅领域事件，禁止跨域直接调用。
- 【强制】业务逻辑保持轻量；复杂业务规则应抽取为独立方法或考虑升级为 DDD/BMP 架构。
- 【推荐】转换用 MapStruct `@Mapper`，`INSTANCE = Mappers.getMapper(...)`；JSON 列用 `default` 方法 + FastJSON2。
- 【推荐】`@CleanLog(biz=..., method=...)` 声明式日志。

## 依赖
- 可依赖：`client`、`infrastructure`、`clean-spring-cqrs-starter`、`clean-spring-log-starter`、validation、MapStruct、Lombok、FastJSON2
- 禁止：`facade`、`interface`

## 示例
```java
@Component
public class OrderModule {
    @Resource private OrderRepository orderRepository;
    @Resource private OrderMessageProducer orderMessageProducer;

    @CleanLog(biz = "订单", method = "创建")
    public OrderDTO create(OrderCreateCommand command) {
        OrderDO order = OrderAssembler.INSTANCE.from(command);   // 直接转 DO
        orderRepository.save(order);
        orderMessageProducer.send(new OrderMessage(order.getOrderId()));
        EventBus.dispatchAsync(new OrderEvent(command.getItemId()));
        return OrderAssembler.INSTANCE.to(order);                // DO → DTO
    }

    public PageResponse<OrderDTO> search(OrderSearchQuery query) {
        PageInfo<OrderDO> pageInfo = orderRepository.search(query);
        return PageAssembler.to(pageInfo, OrderAssembler.INSTANCE::to);
    }
}
```
