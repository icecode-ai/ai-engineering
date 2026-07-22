package com.sample.clean.order.domain.event;

import com.icecode.clean.cqrs.event.Event;
import com.sample.clean.inventory.types.ItemId;
import com.sample.clean.order.types.OrderId;

/**
 * 订单领域事件
 *
 * <pre>
 * 规范 - 领域事件：
 * - 进程内消费
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
public record OrderEvent(OrderId orderId, ItemId itemId) implements Event {}
