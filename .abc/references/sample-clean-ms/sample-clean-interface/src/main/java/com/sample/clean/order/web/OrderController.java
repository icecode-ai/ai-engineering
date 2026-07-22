package com.sample.clean.order.web;

import com.icecode.clean.common.dto.PageResponse;
import com.icecode.clean.common.dto.SingleResponse;
import com.sample.clean.order.dto.OrderCreateCommand;
import com.sample.clean.order.dto.OrderDTO;
import com.sample.clean.order.module.OrderModule;
import com.sample.clean.order.types.OrderSearchQuery;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 商品库存接口服务
 *
 * <pre>
 * 规范 - 接口层：
 * - 不包含业务逻辑，基本不包含 if 判断等
 * - 返回 Result 类型 SingleResponse、PageResponse
 * - 异常走拦截器统一拦截，不需要 try catch，除非有弱依赖调用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@RestController
@RequestMapping("/order")
public class OrderController {

    @Resource
    private OrderModule orderModule;

    @RequestMapping("create")
    public SingleResponse<OrderDTO> create(@Valid OrderCreateCommand command) {
        return SingleResponse.success(orderModule.create(command));
    }

    @RequestMapping("search")
    public PageResponse<OrderDTO> search(@Valid OrderSearchQuery query) {
        return orderModule.search(query);
    }
}
