package com.sample.clean.inventory.data;

import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.util.Date;

/**
 * 商品库存数据
 *
 * <pre>
 * 规范 - 存储持久化数据：
 * - DO 中的属性，都用包装类型
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Data
@Table(name = "inventory")
public class InventoryDO {

    /** 商品ID */
    @Id
    private Long itemId;

    /** 商品可用库存 */
    private Integer availableStock;

    /** 创建时间 */
    private Date gmtCreate;

    /** 更新时间 */
    private Date gmtModified;
}
