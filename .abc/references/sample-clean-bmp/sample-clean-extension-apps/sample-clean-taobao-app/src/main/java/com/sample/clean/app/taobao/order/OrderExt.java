package com.sample.clean.app.taobao.order;

import com.icecode.clean.extension.Extension;
import com.sample.clean.app.taobao.common.Constants;
import com.sample.clean.order.bo.OrderCreateInput;
import com.sample.clean.order.extension.OrderExtPt;

import java.util.HashMap;
import java.util.Map;

/**
 * 订单扩展
 *
 * @author jim
 * @date 2013-05-21
 */
@Extension(bizCode = Constants.BIZ_CODE)
public class OrderExt implements OrderExtPt {

    @Override
    public Map<String, Object> createAttributes(OrderCreateInput input) {
        Map<String, Object> attributes = new HashMap<>();
        attributes.put("source", Constants.BIZ_CODE);

        return attributes;
    }
}
