package com.sample.clean.inventory.domain.entity;

import com.icecode.clean.ddd.domain.Aggregate;
import com.icecode.clean.exception.Assert;
import com.sample.clean.inventory.repository.InventoryRepository;
import com.sample.clean.inventory.types.ItemId;
import lombok.Data;

/**
 * 商品库存领域对象
 *
 * <pre>
 * 规范 - 领域对象：
 * - 业务逻辑内聚地
 * - 不要把业务逻辑抽到工具类，尤其是计算相关的
 * - 业务属性可以有默认值
 * - 单领域变更(Save/Update/Delete)，外部依赖通用方法传入
 * - 多/跨领域变更(Save/Update/Delete)，需要建 领域服务 DomainService，由 DomainService 编排多个领域的调用，各领域本身的变更内聚各自领域
 * - 异常走拦截器统一拦截，不需要try catch，除非有弱依赖调用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Data
public class Inventory implements Aggregate<ItemId> {

    /** 商品ID */
    private ItemId itemId;

    /** 可用库存 */
    private int availableStock;

    @Override
    public ItemId getId() {
        return itemId;
    }

    /**
     * 保存商品库存
     *
     * @param repository 商品库存持久层
     */
    public void save(InventoryRepository repository) {
        // ...
        repository.save(this);
        // ...
    }

    /**
     * 库存扣减
     *
     * @param repository 商品库存持久层
     * @param quantity   扣减数量
     */
    public void decrease(InventoryRepository repository, int quantity) {
        Assert.isTrue(availableStock > quantity, "库存不足，无法扣减");

        this.availableStock -= quantity;

        save(repository);
    }
}
