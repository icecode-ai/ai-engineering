package com.sample.clean.order.module;

import com.alibaba.fastjson2.JSONObject;
import com.alibaba.fastjson2.JSONWriter;
import com.icecode.clean.common.dto.PageResponse;
import com.sample.clean.BaseTest;
import com.sample.clean.inventory.dto.InventorySaveCommand;
import com.sample.clean.inventory.module.InventoryModule;
import com.sample.clean.order.dto.OrderCreateCommand;
import com.sample.clean.order.dto.OrderDTO;
import com.sample.clean.order.types.OrderSearchQuery;
import jakarta.annotation.Resource;
import org.junit.jupiter.api.Test;

/**
 * 订单模块测试
 *
 * @author jim
 * @date 2013-05-21
 */
class OrderModuleTest extends BaseTest {

    @Resource
    private InventoryModule inventoryModule;

    @Resource
    private OrderModule orderModule;

    @Test
    void create() {
        long itemId = 123L;

        InventorySaveCommand inventorySaveCommand = new InventorySaveCommand();
        inventorySaveCommand.setItemId(itemId);
        inventorySaveCommand.setAvailableStock(999);

        inventoryModule.save(inventorySaveCommand);

        OrderCreateCommand orderCreateCommand = new OrderCreateCommand();
        orderCreateCommand.setUserId("张三");
        orderCreateCommand.setItemId(itemId);

        OrderDTO orderDTO = orderModule.create(orderCreateCommand);

        System.out.println("================💫💫💫💫💫💫💫=====================");
        System.out.println(JSONObject.toJSONString(orderDTO, JSONWriter.Feature.PrettyFormat));
        System.out.println("================💫💫💫💫💫💫💫=====================");
    }

    @Test
    void search() {
        OrderSearchQuery condition = new OrderSearchQuery();

        PageResponse<OrderDTO> response = orderModule.search(condition);

        System.out.println("================💫💫💫💫💫💫💫=====================");
        System.out.println(JSONObject.toJSONString(response, JSONWriter.Feature.PrettyFormat));
        System.out.println("================💫💫💫💫💫💫💫=====================");
    }
}