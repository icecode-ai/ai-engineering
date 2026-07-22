package com.sample.clean.order.messaging;

import com.sample.clean.order.types.OrderMessage;

/**
 * 订单消息生产者
 *
 * @author jim
 * @date 2013-05-21
 */
public interface OrderMessageProducer {

    void send(OrderMessage message);
}
