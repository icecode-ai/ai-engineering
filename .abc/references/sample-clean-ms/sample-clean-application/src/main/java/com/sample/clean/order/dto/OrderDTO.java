package com.sample.clean.order.dto;

import com.icecode.clean.common.dto.DTO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;
import java.util.Map;

/**
 * 订单传输对象
 *
 * <pre>
 * 规范 - 数据传输对象：
 * - DTO 中的属性，都用包装类型
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class OrderDTO extends DTO {

    /** 订单ID */
    private Long orderId;

    /** 是否主子一体订单 */
    private Boolean one;

    /** 是否主订单 */
    private Boolean main;

    /** 商品ID */
    private Long itemId;

    /** 商品标签 */
    private List<Integer> itemTags;

    /** 子订单列表 */
    private List<OrderDTO> subOrders;

    /** 订单状态 */
    private String status;

    /** 订单属性 */
    private Map<String, Object> attributes;
}
