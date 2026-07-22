package com.sample.clean.order.blank;

import com.icecode.clean.extension.Extension;
import com.sample.clean.order.bo.OrderCreateInput;
import com.sample.clean.order.extension.OrderExtPt;

import java.util.Map;

/**
 * 订单默认扩展点实现
 *
 * @author jim
 * @date 2013-05-21
 */
@Extension
public class BlankOrderExt implements OrderExtPt {

    @Override
    public Map<String, Object> createAttributes(OrderCreateInput input) {
        return Map.of();
    }
}
