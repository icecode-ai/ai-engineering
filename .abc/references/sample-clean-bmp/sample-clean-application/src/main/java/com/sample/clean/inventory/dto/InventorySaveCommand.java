package com.sample.clean.inventory.dto;

import com.icecode.clean.common.cqrs.Command;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 商品库存保存指令
 *
 * <pre>
 * 规范 - 数据传输对象：
 * - Query、Command 中的属性，尽量都用基本类型，省略不必要的 null 判断
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class InventorySaveCommand extends Command {

    /** 商品ID */
    long itemId;

    /** 商品可用库存 */
    @Min(value = 0, message = "库存不能小于0")
    @Max(value = 99, message = "库存不能大于99")
    int availableStock;
}
