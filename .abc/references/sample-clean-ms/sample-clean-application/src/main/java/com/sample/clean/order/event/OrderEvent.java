package com.sample.clean.order.event;

import com.icecode.clean.cqrs.event.Event;

/**
 * 订单事件
 *
 * @author jim
 * @date 2013-05-21
 */
public record OrderEvent(long itemId) implements Event {}
