package com.sample.clean.order.extension;

import com.icecode.clean.extension.ExtensionPoint;
import com.sample.clean.order.bo.OrderCreateInput;

import java.util.Map;

/**
 * 订单扩展点
 *
 * @author jim
 * @date 2013-05-21
 */
public interface OrderExtPt extends ExtensionPoint {

    /**
     * 创建订单属性
     *
     * @param input 创建订单上下文
     *
     * @return 订单属性
     */
    Map<String, Object> createAttributes(OrderCreateInput input);
}
