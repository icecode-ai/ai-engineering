package com.sample.clean.lottery.dto;

import com.icecode.clean.common.dto.DTO;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 双色球返回结果
 *
 * <pre>
 * 规范 - 数据传输对象：
 * - DTO 中的属性，都用包装类型
 * </pre>
 *
 * @author jim
 * @date 2013-05-21
 */
@EqualsAndHashCode(callSuper = true)
@Data
public class ResultDTO<T> extends DTO {

    private T result;
}
