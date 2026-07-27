# 领域模型架构 - domain 领域层规范

## 职责
领域核心：领域模型/聚合根、值对象、领域服务、领域事件、Repository/消息端口接口。业务逻辑内聚在聚合根方法内。不感知 DB/MQ/三方服务

## 包结构
| 包路径 | 说明 |
|---|---|
| `{package}.{biz}.domain.entity` | 领域模型、聚合根 implements Aggregate<{Name}Id> |
| `{package}.{biz}.domain.service` | 领域服务 @Component（仅跨/多领域编排） |
| `{package}.{biz}.domain.event` | 领域事件 record implements Event |
| `{package}.{biz}.repository` | 端口接口 {Name}Repository extends Repository<E,ID> |
| `{package}.{biz}.messaging` | 消息端口接口 {Name}MessageProducer |
| `{package}.{biz}.types` | 值对象（entity子属性 / {Name}Id record / 枚举 / *Condition / *Message 等） |

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 领域模型 | `{Name}` | `Item` |
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
- 【强制】domain 禁止依赖 facade / infrastructure / interface / application
- 【强制】异常走拦截器统一拦截，不 try-catch（弱依赖除外）

- 【强制】领域模型/聚合根 `@Data`（Lombok）允许；业务属性可有默认值
- 【强制】业务逻辑内聚在领域模型/聚合根方法内，禁止抽到工具类或散落在其他地方

- 【强制】单领域变更（Save/Update/Delete）：外部依赖（repository/producer）以方法参数传入，保持框架无关、可单测

- 【强制】只有多/跨领域变更(Save/Update/Delete)，才需要建领域服务，领域服务编排多个领域调用，各领域变更内聚各自聚合根
- 【强制】领域服务，能用具体类实现时，不要定义接口，除非场景需要有多个实现类或需要保留扩展能力
- 【推荐】设计模式相关的，比如策略工厂，放在 `{package}.{biz}.domain.service` 目录下

- 【推荐】值对象 ID 用 `record` 代替裸 `long`/`int`，防传错、增语义

- 【强制】只有场景需要领域事件时，才设计领域事件，不要随便添加
- 【推荐】领域事件用 `record`，经 `EventBus.dispatchAsync` 进程内异步消费

- 【强制】业务变体差异通过策略模式或参数显式处理，禁止散落的 if-else 业务线判断

## 示例

### 单领域变更
单领域变更（Save/Update/Delete）：外部依赖（repository/producer）以方法参数传入，业务逻辑内聚在聚合根方法内，业务变体通过策略模式或参数显式处理

```java
// domain 层：业务逻辑内聚在聚合根方法内，依赖以参数传入，业务变体通过策略模式或参数显式处理
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

// application 层：Module 编排入口，直接调用聚合根方法（传递依赖）
@Component
public class OrderModule {

    @Resource
    private OrderRepository orderRepository;
    
    @Resource
    private OrderMessageProducer orderMessageProducer;

    public OrderDTO create(OrderCreateCommand command) {
        Order order = OrderAssembler.INSTANCE.from(command);
        order.create(orderRepository, orderMessageProducer);
        
        return OrderAssembler.INSTANCE.to(order);
    }
}
```

### 多/跨领域变更
多/跨领域变更（Save/Update/Delete）：建领域服务编排多个领域调用，各领域变更内聚在各自聚合根方法内

```java
// domain 层：各领域变更内聚在各自聚合根
@Data
public class Inventory implements Aggregate<ItemId> {

    private ItemId itemId;
    
    private Quantity available;

    public void deduct(Quantity quantity, InventoryRepository repository) {
        Assert.isTrue(available.ge(quantity), "INVENTORY_NOT_ENOUGH", "库存不足");
       
        this.available = available.subtract(quantity);
       
        repository.save(this);
       
        EventBus.dispatchAsync(new InventoryEvent(itemId, available));
    }
}


// domain 层：领域服务编排多个领域变更，各领域变更内聚在各自聚合根
@Component
public class OrderService {

    @Resource
    private OrderRepository orderRepository;
    @Resource
    private OrderMessageProducer orderMessageProducer;
    @Resource
    private InventoryRepository inventoryRepository;

    /**
     * 下单：跨 Order 与 Inventory 两个领域变更
     * 领域服务负责编排，各领域变更内聚在各自聚合根方法内
     */
    public void placeOrder(Order order, ItemId itemId, Quantity quantity) {
        // Order 领域变更
        order.create(orderRepository, orderMessageProducer);

        // Inventory 领域变更：加载聚合根后内聚变更
        Optional<Inventory> optional = inventoryRepository.find(itemId);
        Assert.isTrue(optional.isPresent(), "INVENTORY_NOT_FOUND", "库存不存在");
        optional.get().deduct(quantity, inventoryRepository);
    }
}

// application 层：Module 编排入口，调用领域服务
@Component
public class OrderModule {

    @Resource
    private OrderService orderService;

    public OrderDTO placeOrder(OrderCreateCommand command) {
        Order order = OrderAssembler.INSTANCE.from(command);
        
        orderService.placeOrder(
            order, 
            new ItemId(command.getItemId()),
            new Quantity(command.getQuantity())
        );
        
        return OrderAssembler.INSTANCE.to(order);
    }
}
```
