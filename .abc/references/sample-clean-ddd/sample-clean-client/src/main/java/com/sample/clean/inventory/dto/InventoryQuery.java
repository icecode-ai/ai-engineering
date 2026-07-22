package com.sample.clean.inventory.dto;

import com.icecode.clean.common.cqrs.Query;

/**
 * 商品库存查询条件
 *
 * <pre>
 * 规范 - 数据传输对象：
 * - Query、Command 中的属性，尽量都用基本类型，省略不必要的 null 判断
 * - 开放层不使用 lombok，不要污染别人的环境
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
public class InventoryQuery extends Query {

    /** 商品ID */
    long itemId;

    public long getItemId() {
        return itemId;
    }

    public void setItemId(long itemId) {
        this.itemId = itemId;
    }
}
