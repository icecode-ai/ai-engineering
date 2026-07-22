package com.sample.clean.lottery.facade;

import com.alibaba.fastjson2.TypeReference;
import com.google.common.base.Splitter;
import com.google.common.collect.Maps;
import com.icecode.clean.common.dto.PageResponse;
import com.icecode.clean.exception.Assert;
import com.icecode.clean.exception.BaseRuntimeException;
import com.icecode.clean.exception.SysException;
import com.sample.clean.lottery.assembler.DoubleColorBallAssembler;
import com.sample.clean.lottery.dto.DoubleColorBallDTO;
import com.sample.clean.lottery.dto.PageResponseDTO;
import com.sample.clean.lottery.dto.ResultDTO;
import lombok.extern.slf4j.Slf4j;
import net.dongliu.requests.RawResponse;
import net.dongliu.requests.Requests;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * 双色球数据防腐层
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
public class DoubleColorBallFacade {

    private static final String URL = "https://mix.lottery.sina.com.cn/gateway/index/entry";

    private static final String PARAMS
        = "__caller__=web&__verno__=1&__version__=1&cat1=gameOpenList&format=json&lottoType=101&page=1&paginationType=1&pageSize=20&dpc=1";

    /**
     * 请求双色球开奖信息
     *
     * @param page 分页
     *
     * @return 双色球开奖信息
     */
    public PageResponse<DoubleColorBallDTO> request(int page) {
        Map<String, String> params = buildParams(page);

        try (
            RawResponse response = Requests.get(URL).timeout(30000).params(params).send()
        ) {
            TypeReference<ResultDTO<PageResponseDTO<DoubleColorBallDTO>>> type = new TypeReference<>() {};
            ResultDTO<PageResponseDTO<DoubleColorBallDTO>> result = response.readToJson(type.getType());
            Assert.notNull(result.getResult(), "REQUEST_DOUBLE_COLOR_BALL_NULL", "请求双色球数据失败为空");

            return DoubleColorBallAssembler.INSTANCE.to(result.getResult());
        } catch (BaseRuntimeException e) {
            throw e;
        } catch (Throwable e) {
            throw new SysException("REQUEST_DOUBLE_COLOR_BALL", "请求双色球数据失败", e);
        }
    }

    private Map<String, String> buildParams(int page) {
        Map<String, String> map = Splitter.on("&").omitEmptyStrings().withKeyValueSeparator("=").split(PARAMS);

        HashMap<String, String> params = Maps.newHashMap(map);
        params.put("page", String.valueOf(page));

        return params;
    }
}
