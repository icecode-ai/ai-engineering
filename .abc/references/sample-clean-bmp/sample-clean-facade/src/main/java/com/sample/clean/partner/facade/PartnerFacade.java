package com.sample.clean.partner.facade;

import com.icecode.clean.log.util.CleanLogUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 合作伙伴防腐层
 *
 * <pre>
 * 规范 - 防腐层：
 * - 直接返回 DTO，不要返回 Result 包装类型
 * - 异常走拦截器统一拦截，不需要 try catch，除非有弱依赖调用
 * - 上层业务根据场景按强弱依赖处理
 * - 不包含任何业务逻辑，可沉淀，可被其他项目拷贝直接使用
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@Slf4j
@Component
public class PartnerFacade {

    /**
     * 同步订单
     *
     * @param orderId 订单ID
     */
    public void syncOrder(long orderId) {
        CleanLogUtils.success("合作伙伴", "订单同步", System.currentTimeMillis(), orderId);
    }
}
