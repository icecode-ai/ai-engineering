package com.sample.clean.order.domain.service;

import com.sample.clean.inventory.repository.InventoryRepository;
import com.sample.clean.order.repository.OrderRepository;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

/**
 * 订单领域服务
 *
 * <pre>
 * 规范 - 领域服务：
 * - ⚠️只有 多/跨领域变更(Save/Update/Delete)，才需要建 领域服务 DomainService，
 * - 编排多个领域的调用，各领域本身的变更内聚各自领域
 * - 异常走拦截器统一拦截，不需要try catch，除非有弱依赖调用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Component
public class OrderService {

    @Resource
    private OrderRepository orderRepository;

    @Resource
    private InventoryRepository inventoryRepository;
}
