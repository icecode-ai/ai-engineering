package com.sample.clean.inventory.module;

import com.icecode.clean.cqrs.event.EventHandler;
import com.icecode.clean.exception.Assert;
import com.icecode.clean.log.annotation.CleanLog;
import com.sample.clean.inventory.assembler.InventoryAssembler;
import com.sample.clean.inventory.domain.entity.Inventory;
import com.sample.clean.inventory.dto.InventoryDTO;
import com.sample.clean.inventory.dto.InventoryQuery;
import com.sample.clean.inventory.dto.InventorySaveCommand;
import com.sample.clean.inventory.repository.InventoryRepository;
import com.sample.clean.inventory.types.ItemId;
import com.sample.clean.order.domain.event.OrderEvent;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * 商品库存处理模块
 *
 * <pre>
 * 规范 - 流程编排层：
 * - 不包含业务逻辑，基本不包含 if 判断、计算逻辑等
 * - 尽量都返回 DTO，不要包装 Result
 * - 异常走拦截器统一拦截，不需要try catch，除非有弱依赖调用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Component
public class InventoryModule {

    @Resource
    private InventoryRepository inventoryRepository;

    /**
     * 保存商品库存
     *
     * @param command 商品库存保存指令
     *
     * @return 商品库存传输对象
     */
    @CleanLog(biz = "商品库存", method = "保存")
    public InventoryDTO save(InventorySaveCommand command) {
        Inventory inventory = InventoryAssembler.INSTANCE.from(command);
        inventory.save(inventoryRepository);

        return InventoryAssembler.INSTANCE.to(inventory);
    }

    /**
     * 查询商品库存
     *
     * @param query 商品库存查询条件
     *
     * @return 商品库存传输对象
     */
    public Optional<InventoryDTO> query(InventoryQuery query) {
        Optional<Inventory> optional = inventoryRepository.find(new ItemId(query.getItemId()));

        return optional.map(InventoryAssembler.INSTANCE::to);
    }

    @EventHandler(name = "库存扣减 - 订单消息监听")
    public void inventoryHandler(OrderEvent event) {
        Optional<Inventory> optional = inventoryRepository.find(event.itemId());
        Assert.isTrue(optional.isPresent(), "商品已下架");

        Inventory inventory = optional.get();
        inventory.decrease(inventoryRepository, 1);
    }
}
