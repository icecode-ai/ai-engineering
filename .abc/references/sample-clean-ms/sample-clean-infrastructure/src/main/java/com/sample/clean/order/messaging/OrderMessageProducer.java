package com.sample.clean.order.messaging;

import com.icecode.clean.log.util.CleanLogUtils;
import com.sample.clean.order.types.OrderMessage;
import org.springframework.stereotype.Component;

/**
 * 订单消息生产者
 *
 * @author jim
 * @date 2013-05-21
 */
@Component
public class OrderMessageProducer {

    public void send(OrderMessage message) {
        CleanLogUtils.success("订单", "消息", System.currentTimeMillis(), message.orderId());
    }
}
