package com.sample.clean.inventory.repository;

import com.icecode.clean.ddd.repository.Repository;
import com.sample.clean.inventory.domain.entity.Inventory;
import com.sample.clean.inventory.types.ItemId;

/**
 * 商品库存持久层
 *
 * @author jim
 * @date 2013-05-21
 */
public interface InventoryRepository extends Repository<Inventory, ItemId> {}
