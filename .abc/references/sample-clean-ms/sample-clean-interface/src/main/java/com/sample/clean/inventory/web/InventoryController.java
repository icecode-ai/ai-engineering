package com.sample.clean.inventory.web;

import com.icecode.clean.common.dto.SingleResponse;
import com.sample.clean.inventory.dto.InventoryDTO;
import com.sample.clean.inventory.dto.InventorySaveCommand;
import com.sample.clean.inventory.module.InventoryModule;
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
@RequestMapping("/inventory") // 这里才是定义路径的地方
public class InventoryController {

    @Resource
    private InventoryModule inventoryModule;

    @RequestMapping("save")
    public SingleResponse<InventoryDTO> save(@Valid InventorySaveCommand command) {
        return SingleResponse.success(inventoryModule.save(command));
    }
}
