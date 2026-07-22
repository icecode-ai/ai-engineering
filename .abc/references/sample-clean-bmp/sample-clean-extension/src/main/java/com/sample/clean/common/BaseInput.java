package com.sample.clean.common;

import com.icecode.clean.extension.bo.Input;
import lombok.Data;

import java.util.List;

/**
 * 默认上下文
 *
 * @author jim
 * @date 2013-05-21
 */
@Data
public abstract class BaseInput implements Input {

    /** 商品标签 */
    private List<Integer> itemTags;
}
