package com.sample.clean.inventory.converter;

import com.sample.clean.inventory.data.InventoryDO;
import com.sample.clean.inventory.domain.entity.Inventory;
import com.sample.clean.inventory.types.ItemId;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.Objects;

/**
 * 商品库存数据转换器
 *
 * <p>Domain <-> DO 数据转换转换器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface InventoryConverter {

    InventoryConverter INSTANCE = Mappers.getMapper(InventoryConverter.class);

    @Mapping(target = "gmtModified", ignore = true)
    @Mapping(target = "gmtCreate", ignore = true)
    InventoryDO to(Inventory inventory);

    Inventory from(InventoryDO inventory);

    default ItemId fromItemId(long itemId) {
        return new ItemId(itemId);
    }

    default Long toItemId(ItemId itemId) {

        if (Objects.isNull(itemId)) {
            return null;
        }

        return itemId.value();
    }
}
