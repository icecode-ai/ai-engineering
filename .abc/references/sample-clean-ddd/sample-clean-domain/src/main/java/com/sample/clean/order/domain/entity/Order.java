package com.sample.clean.order.domain.entity;

import com.icecode.clean.cqrs.EventBus;
import com.icecode.clean.ddd.domain.Aggregate;
import com.sample.clean.inventory.types.ItemId;
import com.sample.clean.order.domain.event.OrderEvent;
import com.sample.clean.order.messaging.OrderMessageProducer;
import com.sample.clean.order.repository.OrderRepository;
import com.sample.clean.order.types.OrderId;
import com.sample.clean.order.types.OrderMessage;
import com.sample.clean.order.types.OrderStatus;
import com.sample.clean.order.types.OrderUpdateCondition;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * 订单领域对象
 *
 * <pre>
 * 规范 - 领域对象：
 * - 业务逻辑内聚地
 * - 不要把业务逻辑抽到工具类，尤其是计算相关的
 * - 业务属性可以有默认值
 * - 单领域变更(Save/Update/Delete)，外部依赖通用方法传入
 * - 多/跨领域变更(Save/Update/Delete)，需要建 领域服务 DomainService，由 DomainService 编排多个领域的调用，各领域本身的变更内聚各自领域
 * - 异常走拦截器统一拦截，不需要try catch，除非有弱依赖调用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Data
public class Order implements Aggregate<OrderId> {

    /** 订单ID */
    private OrderId orderId;

    /** 用户ID */
    private String userId;

    /** 是否是主子一体订单 */
    private boolean one;

    /** 是否主订单 */
    private boolean main;

    /** 商品ID */
    private ItemId itemId;

    /** 商品标签 */
    private List<Integer> itemTags;

    /** 子订单 */
    private List<Order> subOrders;

    /** 订单状态 */
    private OrderStatus status;

    /** 订单属性 */
    private Map<String, Object> attributes;

    @Override
    public OrderId getId() {
        return orderId;
    }

    /**
     * 创建订单
     *
     * @param repository 订单持久层
     * @param producer   订单消息生产者
     */
    public void create(OrderRepository repository, OrderMessageProducer producer) {
        this.status = OrderStatus.paid;

        // 保存订单
        repository.save(this);

        // 发送订单消息
        producer.send(new OrderMessage(orderId, status));

        // 发送订单领域事件
        EventBus.dispatchAsync(new OrderEvent(orderId, itemId));
    }

    /**
     * 更新订单
     *
     * @param repository 订单持久层
     * @param condition  订单更新条件
     */
    public void update(OrderRepository repository, OrderUpdateCondition condition) {
        repository.update(this, condition);

        EventBus.dispatchAsync(new OrderEvent(orderId, itemId));
    }
}
