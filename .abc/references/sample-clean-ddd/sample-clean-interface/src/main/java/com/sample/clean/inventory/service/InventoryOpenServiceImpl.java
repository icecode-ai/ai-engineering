package com.sample.clean.inventory.service;

import com.icecode.clean.common.dto.SingleResponse;
import com.icecode.clean.exception.Assert;
import com.sample.clean.inventory.dto.InventoryDTO;
import com.sample.clean.inventory.dto.InventoryQuery;
import com.sample.clean.inventory.module.InventoryModule;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;

import java.util.Optional;

/**
 * 商品库存开放服务
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
// @DubboService(version = "${dubbo.version}", group = "DEFAULT")
public class InventoryOpenServiceImpl implements InventoryOpenService {

    @Resource
    private InventoryModule inventoryModule;

    @Override
    public SingleResponse<InventoryDTO> query(@Valid InventoryQuery query) {
        Optional<InventoryDTO> optional = inventoryModule.query(query);
        Assert.isTrue(optional.isPresent(), "商品库存不存在");

        return SingleResponse.success(optional.get());
    }
}
