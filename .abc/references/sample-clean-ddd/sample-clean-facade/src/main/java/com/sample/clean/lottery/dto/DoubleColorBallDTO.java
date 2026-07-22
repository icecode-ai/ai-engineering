package com.sample.clean.lottery.dto;

import com.icecode.clean.common.dto.DTO;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.TreeSet;

/**
 * 双色球数据
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
public class DoubleColorBallDTO extends DTO {

    private Integer issueNo;

    private TreeSet<Integer> blueResults;

    private TreeSet<Integer> redResults;

    public Integer blueNo() {
        return blueResults.first();
    }
}
