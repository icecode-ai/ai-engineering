package com.sample.clean.order.types;

/**
 * 订单消息
 *
 * <pre>
 * 规范 - 值对象：
 * - 大部分是领域对象中的属性
 * - 属于业务中的一部分，大部分包含自己的业务计算逻辑
 * - ID类的，主要是用来代替 int、long 这种没有业务含义的类型，其次是防止传错
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
public record OrderMessage(OrderId orderId, OrderStatus status) {}
