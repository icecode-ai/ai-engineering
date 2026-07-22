package com.sample.clean.inventory.repository;

import com.icecode.clean.exception.Assert;
import com.sample.clean.inventory.dao.InventoryDao;
import com.sample.clean.inventory.data.InventoryDO;
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
public class InventoryRepository {

    @Resource
    private InventoryDao inventoryDao;

    public void save(InventoryDO inventory) {
        int count;
        if (Objects.nonNull(inventory.getItemId())) {
            count = inventoryDao.updateByPrimaryKeySelective(inventory);
        } else {
            count = inventoryDao.insertSelective(inventory);
        }

        Assert.isTrue(count > 0, "保存库存失败");
    }

    public void remove(long itemId) {
        Weekend<InventoryDO> weekend = Weekend.of(InventoryDO.class);

        WeekendCriteria<InventoryDO, Object> where = weekend.weekendCriteria();
        where.andEqualTo(InventoryDO::getItemId, itemId);

        inventoryDao.deleteByExample(weekend);
    }

    public Optional<InventoryDO> find(long itemId) {
        return Optional.of(inventoryDao.selectByPrimaryKey(itemId));
    }
}
