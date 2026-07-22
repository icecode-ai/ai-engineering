package com.sample.clean.order.dto;

import com.icecode.clean.common.cqrs.Command;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 订单创建指令
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
public class OrderCreateCommand extends Command {

    /** 用户ID */
    private String userId;

    /** 商品ID */
    private long itemId;
}
