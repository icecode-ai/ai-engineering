# 领域模型架构 - domain 领域层规范

## 职责
领域核心：聚合根、值对象、领域服务、领域事件、Repository/消息端口接口。业务逻辑内聚在聚合根方法内。不感知 DB/MQ/三方服务

## 包结构
| 包路径 | 说明 |
|---|---|
| `{package}.{biz}.domain.entity` | 聚合根 implements Aggregate<{Name}Id> |
| `{package}.{biz}.domain.service` | 领域服务 @Component（仅跨/多领域编排） |
| `{package}.{biz}.domain.event` | 领域事件 record implements Event |
| `{package}.{biz}.repository` | 端口接口 {Name}Repository extends Repository<E,ID> |
| `{package}.{biz}.messaging` | 消息端口接口 {Name}MessageProducer |
| `{package}.{biz}.types` | 值对象（entity子属性 / {Name}Id record / 枚举 / *Condition / *Message 等） |

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 聚合根 | `{Name} implements Aggregate<{Name}Id>` | `Order` |
| 值对象 ID | `{Name}Id record implements Identifier` | `OrderId` |
| 枚举 | `{Name}` | `OrderStatus` |
| 领域事件 | `{Name}Event record implements Event` | `OrderEvent` |
| 领域服务 | `{Name}Service @Component` | `OrderService` |
| Repository 端口 | `{Name}Repository extends Repository<E,ID>` | `OrderRepository` |
| 消息端口 | `{Name}MessageProducer` | `OrderMessageProducer` |
| 查询条件 | `{Name}SearchCondition extends PageQuery` | `OrderSearchCondition` |
| 更新条件 | `{Name}UpdateCondition` | `OrderUpdateCondition` |

## 规则
- 【强制】业务逻辑内聚在聚合根方法内，禁止抽到工具类（尤其计算相关）
- 【强制】单领域变更（Save/Update/Delete）：外部依赖（repository/producer）以方法参数传入，保持框架无关、可单测
- 【强制】只有多/跨领域变更(Save/Update/Delete)，才需要建领域服务，领域服务编排多个领域调用，各领域变更内聚各自聚合根
- 【强制】业务变体差异通过策略模式或参数显式处理，禁止散落的 if-else 业务线判断
- 【强制】domain 禁止依赖 facade / infrastructure / interface / application
- 【强制】异常走拦截器统一拦截，不 try-catch（弱依赖调用除外）
- 【强制】聚合根 `@Data`（Lombok）允许；业务属性可有默认值
- 【推荐】值对象 ID 用 `record` 代替裸 `long`/`int`，防传错、增语义
- 【推荐】领域事件用 `record`，经 `EventBus.dispatchAsync` 进程内异步消费
- 【推荐】设计模式相关的，比如策略工厂，放在 `{package}.{biz}.domain.service` 目录下

## 示例
```java
@Data
public class Order implements Aggregate<OrderId> {
    private OrderId orderId;
    private ItemId itemId;
    private OrderStatus status;

    public void create(OrderRepository repository, OrderMessageProducer producer) {
        this.status = OrderStatus.PAID;
        repository.save(this);
        producer.send(new OrderMessage(orderId, status));
        EventBus.dispatchAsync(new OrderEvent(orderId, itemId));
    }
}
```
