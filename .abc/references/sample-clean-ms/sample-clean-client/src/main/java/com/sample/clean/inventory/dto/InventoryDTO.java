package com.sample.clean.inventory.dto;

import com.icecode.clean.common.dto.DTO;

/**
 * 商品库存传输对象
 *
 * <pre>
 * 规范 - 数据传输对象：
 * - DTO 中的属性，都用包装类型
 * - 开放层不使用 lombok，不要污染别人的环境
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
public class InventoryDTO extends DTO {

    /** 商品ID */
    private Long itemId;

    /** 商品可用库存 */
    private Integer availableStock;

    public Long getItemId() {
        return itemId;
    }

    public void setItemId(Long itemId) {
        this.itemId = itemId;
    }

    public Integer getAvailableStock() {
        return availableStock;
    }

    public void setAvailableStock(Integer availableStock) {
        this.availableStock = availableStock;
    }
}
