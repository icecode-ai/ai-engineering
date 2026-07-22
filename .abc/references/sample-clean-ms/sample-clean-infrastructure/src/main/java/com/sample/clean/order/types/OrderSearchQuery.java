package com.sample.clean.order.types;

import com.icecode.clean.common.cqrs.PageQuery;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 订单查询条件
 *
 * @author jim
 * @date 2013-05-21
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class OrderSearchQuery extends PageQuery {

    private String userId;

    private Long itemId;
}
