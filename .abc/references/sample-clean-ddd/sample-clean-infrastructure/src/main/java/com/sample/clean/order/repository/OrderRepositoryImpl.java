package com.sample.clean.order.repository;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.sample.clean.common.converter.PageConverter;
import com.sample.clean.order.converter.OrderConverter;
import com.sample.clean.order.dao.OrderDao;
import com.sample.clean.order.data.OrderDO;
import com.sample.clean.order.domain.entity.Order;
import com.sample.clean.order.types.OrderId;
import com.sample.clean.order.types.OrderSearchCondition;
import com.sample.clean.order.types.OrderUpdateCondition;
import com.sample.clean.partner.facade.PartnerFacade;
import jakarta.annotation.Resource;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Component;
import tk.mybatis.mapper.weekend.Weekend;
import tk.mybatis.mapper.weekend.WeekendCriteria;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * 订单持久层
 *
 * <pre>
 * 规范 - 持久层：
 * - 可以封装数据库调用，也可以封装二、三方服务调用，转换成自己的领域
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Component
public class OrderRepositoryImpl implements OrderRepository {

    @Resource
    private OrderDao orderDao;

    @Resource
    private PartnerFacade partnerFacade;

    @Override
    public PageInfo<Order> search(OrderSearchCondition condition) {
        Weekend<OrderDO> weekend = Weekend.of(OrderDO.class);
        // weekend.selectProperties("orderId", "userId");

        if (StringUtils.isNotBlank(condition.getOrderBy())) {
            // weekend.orderBy(condition.getOrderBy());
            weekend.setOrderByClause(condition.getOrderBy() + " " + condition.getOrderDirection());
        }

        WeekendCriteria<OrderDO, Object> where = weekend.weekendCriteria();
        if (StringUtils.isNotBlank(condition.getUserId())) {
            where.andEqualTo(OrderDO::getUserId, condition.getUserId());
        }

        if (Objects.nonNull(condition.getItemId())) {
            where.andEqualTo(OrderDO::getItemId, condition.getItemId().value());
        }

        if (StringUtils.isNotBlank(condition.getUserId())) {
            where.andEqualTo(OrderDO::getUserId, condition.getUserId());
        }

        PageHelper.startPage(condition.getPageIndex(), condition.getPageSize(), condition.isNeedTotalCount());
        List<OrderDO> list = orderDao.selectByExample(weekend);
        PageInfo<OrderDO> pageInfo = new PageInfo<>(list);

        return PageConverter.toEntity(pageInfo, OrderConverter.INSTANCE::from);
    }

    @Override
    public void update(Order order, OrderUpdateCondition condition) {
        OrderDO orderDO = OrderConverter.INSTANCE.to(order);

        Weekend<OrderDO> weekend = Weekend.of(OrderDO.class);
        WeekendCriteria<OrderDO, Object> where = weekend.weekendCriteria();
        where.andEqualTo(OrderDO::getUserId, condition.userId());

        orderDao.updateByExampleSelective(orderDO, weekend);
    }

    @Override
    public void save(Order order) {
        OrderDO orderDO = OrderConverter.INSTANCE.to(order);
        if (Objects.isNull(orderDO.getOrderId())) {
            int id = orderDao.insertSelective(orderDO);
            order.setOrderId(new OrderId(id));

            partnerFacade.syncOrder(id);
        } else {
            orderDao.updateByPrimaryKeySelective(orderDO);
        }
    }

    @Override
    public void remove(Order aggregate) {
        orderDao.deleteByPrimaryKey(aggregate.getOrderId().value());
    }

    @Override
    public Optional<Order> find(OrderId orderId) {
        OrderDO orderDO = orderDao.selectByPrimaryKey(orderId.value());
        if (Objects.isNull(orderDO)) {
            return Optional.empty();
        }

        return Optional.of(OrderConverter.INSTANCE.from(orderDO));
    }
}
