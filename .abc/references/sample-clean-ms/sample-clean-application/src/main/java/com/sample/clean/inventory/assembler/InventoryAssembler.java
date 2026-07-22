package com.sample.clean.inventory.assembler;

import com.sample.clean.inventory.data.InventoryDO;
import com.sample.clean.inventory.dto.InventoryDTO;
import com.sample.clean.inventory.dto.InventorySaveCommand;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

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

    @Mapping(target = "gmtCreate", ignore = true)
    @Mapping(target = "gmtModified", ignore = true)
    InventoryDO from(InventorySaveCommand command);

    InventoryDTO to(InventoryDO inventory);
}
