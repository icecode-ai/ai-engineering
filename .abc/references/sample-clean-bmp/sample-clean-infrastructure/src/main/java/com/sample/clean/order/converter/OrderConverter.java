package com.sample.clean.order.converter;

import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.alibaba.fastjson2.TypeReference;
import com.sample.clean.inventory.types.ItemId;
import com.sample.clean.order.data.OrderDO;
import com.sample.clean.order.domain.entity.Order;
import com.sample.clean.order.types.OrderId;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.*;

/**
 * 订单数据转换器
 *
 * <p>Domain <-> DO 数据转换转换器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface OrderConverter {

    OrderConverter INSTANCE = Mappers.getMapper(OrderConverter.class);

    @Mapping(target = "gmtModified", ignore = true)
    @Mapping(target = "gmtCreate", ignore = true)
    OrderDO to(Order order);

    @Mapping(target = "subOrders", ignore = true)
    Order from(OrderDO orderDO);

    default ItemId fromItemId(long itemId) {
        return new ItemId(itemId);
    }

    default Long toItemId(ItemId itemId) {

        if (Objects.isNull(itemId)) {
            return null;
        }

        return itemId.value();
    }

    default OrderId fromOrderId(long orderId) {
        return new OrderId(orderId);
    }

    default Long toOrderId(OrderId oderId) {

        if (Objects.isNull(oderId)) {
            return null;
        }

        return oderId.value();
    }

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
