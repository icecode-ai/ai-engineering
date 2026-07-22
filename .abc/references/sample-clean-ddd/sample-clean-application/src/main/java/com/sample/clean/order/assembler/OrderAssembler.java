package com.sample.clean.order.assembler;

import com.sample.clean.inventory.types.ItemId;
import com.sample.clean.order.domain.entity.Order;
import com.sample.clean.order.dto.OrderCreateCommand;
import com.sample.clean.order.dto.OrderDTO;
import com.sample.clean.order.dto.OrderSearchQuery;
import com.sample.clean.order.dto.OrderUpdateCommand;
import com.sample.clean.order.types.OrderId;
import com.sample.clean.order.types.OrderSearchCondition;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.Objects;

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

    @Mapping(target = "subOrders", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "orderId", ignore = true)
    @Mapping(target = "one", ignore = true)
    @Mapping(target = "main", ignore = true)
    @Mapping(target = "itemTags", ignore = true)
    @Mapping(target = "attributes", ignore = true)
    Order from(OrderCreateCommand command);

    @Mapping(target = "userId", ignore = true)
    @Mapping(target = "itemId", ignore = true)
    @Mapping(target = "subOrders", ignore = true)
    @Mapping(target = "orderId", ignore = true)
    @Mapping(target = "one", ignore = true)
    @Mapping(target = "main", ignore = true)
    @Mapping(target = "itemTags", ignore = true)
    @Mapping(target = "attributes", ignore = true)
    Order from(OrderUpdateCommand command);

    OrderSearchCondition from(OrderSearchQuery query);

    OrderDTO to(Order order);

    default ItemId fromItemId(long itemId) {
        return new ItemId(itemId);
    }

    default Long toItemId(ItemId itemId) {

        if (Objects.isNull(itemId)) {
            return null;
        }

        return itemId.value();
    }

    default Long toOrderId(OrderId oderId) {

        if (Objects.isNull(oderId)) {
            return null;
        }

        return oderId.value();
    }
}
