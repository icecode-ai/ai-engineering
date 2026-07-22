package com.sample.clean.order.repository;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.sample.clean.order.dao.OrderDao;
import com.sample.clean.order.data.OrderDO;
import com.sample.clean.order.types.OrderSearchQuery;
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
public class OrderRepository {

    @Resource
    private OrderDao orderDao;

    @Resource
    private PartnerFacade partnerFacade;

    public void save(OrderDO order) {
        if (Objects.isNull(order.getOrderId())) {
            int id = orderDao.insertSelective(order);

            partnerFacade.syncOrder(id);
        } else {
            orderDao.updateByPrimaryKeySelective(order);
        }
    }

    public Optional<OrderDO> find(long orderId) {
        return Optional.of(orderDao.selectByPrimaryKey(orderId));
    }

    public PageInfo<OrderDO> search(OrderSearchQuery query) {
        Weekend<OrderDO> weekend = Weekend.of(OrderDO.class);
        // weekend.selectProperties("orderId", "userId");

        if (StringUtils.isNotBlank(query.getOrderBy())) {
            // weekend.orderBy(condition.getOrderBy());
            weekend.setOrderByClause(query.getOrderBy() + " " + query.getOrderDirection());
        }

        WeekendCriteria<OrderDO, Object> where = weekend.weekendCriteria();
        if (StringUtils.isNotBlank(query.getUserId())) {
            where.andEqualTo(OrderDO::getUserId, query.getUserId());
        }

        if (Objects.nonNull(query.getItemId())) {
            where.andEqualTo(OrderDO::getItemId, query.getItemId());
        }

        if (StringUtils.isNotBlank(query.getUserId())) {
            where.andEqualTo(OrderDO::getUserId, query.getUserId());
        }

        PageHelper.startPage(query.getPageIndex(), query.getPageSize(), query.isNeedTotalCount());
        List<OrderDO> list = orderDao.selectByExample(weekend);

        return new PageInfo<>(list);
    }
}
