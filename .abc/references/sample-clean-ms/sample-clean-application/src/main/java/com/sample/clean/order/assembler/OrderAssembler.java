package com.sample.clean.order.assembler;

import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.alibaba.fastjson2.TypeReference;
import com.sample.clean.order.data.OrderDO;
import com.sample.clean.order.dto.OrderCreateCommand;
import com.sample.clean.order.dto.OrderDTO;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 订单包装器
 *
 * <p>DTO <-> Domain 数据转换包装器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface OrderAssembler {

    OrderAssembler INSTANCE = Mappers.getMapper(OrderAssembler.class);

    @Mapping(target = "status", constant = "paid")
    @Mapping(target = "orderId", ignore = true)
    @Mapping(target = "one", ignore = true)
    @Mapping(target = "main", ignore = true)
    @Mapping(target = "itemTags", ignore = true)
    @Mapping(target = "gmtModified", ignore = true)
    @Mapping(target = "gmtCreate", ignore = true)
    @Mapping(target = "attributes", ignore = true)
    OrderDO from(OrderCreateCommand command);

    @Mapping(target = "subOrders", ignore = true)
    OrderDTO to(OrderDO order);

    default List<Integer> fromItemTags(String itemTags) {

        if (StringUtils.isBlank(itemTags)) {
            return Collections.emptyList();
        }

        return JSONArray.parseArray(itemTags, Integer.class);
    }

    default String toItemTags(List<Integer> itemTags) {

        if (CollectionUtils.isEmpty(itemTags)) {
            return null;
        }

        return JSONArray.toJSONString(itemTags);
    }

    default Map<String, Object> fromAttributes(String attributes) {

        if (attributes == null || attributes.isEmpty()) {
            return new HashMap<>();
        }

        return JSONObject.parseObject(attributes, new TypeReference<Map<String, Object>>() {});
    }

    default String toAttributes(Map<String, Object> attributes) {
        return attributes == null ? null : JSONObject.toJSONString(attributes);
    }
}
