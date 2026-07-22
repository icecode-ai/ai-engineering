package com.sample.clean.inventory.service;

import com.icecode.clean.common.dto.SingleResponse;
import com.sample.clean.inventory.dto.InventoryDTO;
import com.sample.clean.inventory.dto.InventoryQuery;

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
public interface InventoryOpenService {

    /**
     * 查询商品库存
     *
     * @param query 商品库存查询条件
     *
     * @return 商品库存传输对象
     */
    SingleResponse<InventoryDTO> query(InventoryQuery query);
}
