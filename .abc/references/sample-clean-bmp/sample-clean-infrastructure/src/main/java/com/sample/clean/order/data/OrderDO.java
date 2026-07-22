package com.sample.clean.order.data;

import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.util.Date;

/**
 * 订单数据
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
@Table(name = "user_order")
public class OrderDO {

    /** 订单ID */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long orderId;

    /** 用户ID */
    private String userId;

    /** 是否主子一体订单 */
    private Boolean one;

    /** 是否主订单 */
    private Boolean main;

    /** 商品ID */
    private Long itemId;

    /** 商品标签 */
    private String itemTags;

    /** 订单状态 */
    private String status;

    /** 订单垂直属性 */
    private String attributes;

    /** 创建时间 */
    private Date gmtCreate;

    /** 更新时间 */
    private Date gmtModified;
}
