package com.sample.clean.order.dto;

import com.icecode.clean.common.cqrs.Command;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 订单更新指令
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
public class OrderUpdateCommand extends Command {

    /** 订单状态 */
    @Pattern(regexp = "^(PAID|SHIPPED)$", message = "状态必须是指定范围内的值")
    private String status;
}
