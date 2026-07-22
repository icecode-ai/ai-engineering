package com.sample.clean.order.repository;

import com.github.pagehelper.PageInfo;
import com.icecode.clean.ddd.repository.Repository;
import com.sample.clean.order.domain.entity.Order;
import com.sample.clean.order.types.OrderId;
import com.sample.clean.order.types.OrderSearchCondition;
import com.sample.clean.order.types.OrderUpdateCondition;

/**
 * 订单持久层
 *
 * @author jim
 * @date 2013-05-21
 */
public interface OrderRepository extends Repository<Order, OrderId> {

    /**
     * 搜索订单
     *
     * @param condition 订单搜索条件
     *
     * @return 订单分页信息
     */
    PageInfo<Order> search(OrderSearchCondition condition);

    /**
     * 更新订单
     *
     * @param order     订单
     * @param condition 订单更新条件
     */
    void update(Order order, OrderUpdateCondition condition);
}
