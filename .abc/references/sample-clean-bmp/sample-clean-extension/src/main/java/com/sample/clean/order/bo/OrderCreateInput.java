package com.sample.clean.order.bo;

import com.sample.clean.common.BaseInput;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 创建订单上下文
 *
 * @author jim
 * @date 2013-05-21
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class OrderCreateInput extends BaseInput {

    /** 商品ID */
    private long itemId;

    /** 用户ID */
    private String userId;
}
