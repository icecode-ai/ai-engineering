package com.sample.clean.order.module;

import com.github.pagehelper.PageInfo;
import com.icecode.clean.common.dto.PageResponse;
import com.icecode.clean.cqrs.EventBus;
import com.icecode.clean.log.annotation.CleanLog;
import com.sample.clean.common.assembler.PageAssembler;
import com.sample.clean.order.assembler.OrderAssembler;
import com.sample.clean.order.data.OrderDO;
import com.sample.clean.order.dto.OrderCreateCommand;
import com.sample.clean.order.dto.OrderDTO;
import com.sample.clean.order.event.OrderEvent;
import com.sample.clean.order.messaging.OrderMessageProducer;
import com.sample.clean.order.repository.OrderRepository;
import com.sample.clean.order.types.OrderMessage;
import com.sample.clean.order.types.OrderSearchQuery;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

/**
 * 订单处理模块
 *
 * <pre>
 * 规范 - 流程编排层：
 * - 不包含业务逻辑，基本不包含 if 判断、计算逻辑等
 * - 尽量都返回 DTO，不要包装 Result
 * - 异常走拦截器统一拦截，不需要try catch，除非有弱依赖调用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Component
public class OrderModule {

    @Resource
    private OrderRepository orderRepository;

    @Resource
    private OrderMessageProducer orderMessageProducer;

    /**
     * 创建订单
     *
     * @param command 订单创建指令
     *
     * @return 订单传输对象
     */
    @CleanLog(biz = "订单", method = "创建")
    public OrderDTO create(OrderCreateCommand command) {
        OrderDO order = OrderAssembler.INSTANCE.from(command);

        orderRepository.save(order);
        orderMessageProducer.send(new OrderMessage(order.getOrderId()));

        EventBus.dispatchAsync(new OrderEvent(command.getItemId()));

        return OrderAssembler.INSTANCE.to(order);
    }

    /**
     * 搜索订单
     *
     * @param query 订单搜索条件
     *
     * @return 订单分页结果
     */
    public PageResponse<OrderDTO> search(OrderSearchQuery query) {
        PageInfo<OrderDO> pageInfo = orderRepository.search(query);

        return PageAssembler.to(pageInfo, OrderAssembler.INSTANCE::to);
    }
}
