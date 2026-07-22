package com.sample.clean.inventory.assembler;

import com.sample.clean.inventory.domain.entity.Inventory;
import com.sample.clean.inventory.dto.InventoryDTO;
import com.sample.clean.inventory.dto.InventorySaveCommand;
import com.sample.clean.inventory.types.ItemId;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.Objects;

/**
 * 商品库存包装器
 *
 * <p>DTO <-> Domain 数据转换包装器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface InventoryAssembler {

    InventoryAssembler INSTANCE = Mappers.getMapper(InventoryAssembler.class);

    Inventory from(InventorySaveCommand command);

    InventoryDTO to(Inventory inventory);

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
