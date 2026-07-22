package com.sample.clean.inventory.repository;

import com.icecode.clean.exception.Assert;
import com.sample.clean.inventory.converter.InventoryConverter;
import com.sample.clean.inventory.dao.InventoryDao;
import com.sample.clean.inventory.data.InventoryDO;
import com.sample.clean.inventory.domain.entity.Inventory;
import com.sample.clean.inventory.types.ItemId;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;
import tk.mybatis.mapper.weekend.Weekend;
import tk.mybatis.mapper.weekend.WeekendCriteria;

import java.util.Objects;
import java.util.Optional;

/**
 * 商品库存数据持久层
 *
 * <pre>
 * 规范 - 持久层：
 * - 可以封装数据库调用，也可以封装二、三方服务调用，转换成自己的领域
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Component
public class InventoryRepositoryImpl implements InventoryRepository {

    @Resource
    private InventoryDao inventoryDao;

    @Override
    public void save(Inventory inventory) {
        InventoryDO inventoryDO = InventoryConverter.INSTANCE.to(inventory);

        int count;

        Optional<Inventory> optional = find(inventory.getItemId());
        if (optional.isPresent()) {
            count = inventoryDao.updateByPrimaryKeySelective(inventoryDO);
        } else {
            count = inventoryDao.insertSelective(inventoryDO);
        }

        Assert.isTrue(count > 0, "保存库存失败");
    }

    @Override
    public void remove(Inventory aggregate) {
        Weekend<InventoryDO> weekend = Weekend.of(InventoryDO.class);

        WeekendCriteria<InventoryDO, Object> where = weekend.weekendCriteria();
        where.andEqualTo(InventoryDO::getItemId, aggregate.getItemId().value());

        inventoryDao.deleteByExample(weekend);
    }

    @Override
    public Optional<Inventory> find(ItemId itemId) {
        InventoryDO inventoryDO = inventoryDao.selectByPrimaryKey(itemId.value());
        if (Objects.isNull(inventoryDO)) {
            return Optional.empty();
        }

        return Optional.of(InventoryConverter.INSTANCE.from(inventoryDO));
    }
}
