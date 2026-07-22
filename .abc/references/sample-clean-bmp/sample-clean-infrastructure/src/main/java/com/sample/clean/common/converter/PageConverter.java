package com.sample.clean.common.converter;

import com.github.pagehelper.PageInfo;

import java.util.List;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 分页数据转换器
 *
 * <p>Domain <-> DO 数据转换转换器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
public class PageConverter {

    public static <DO, E> PageInfo<E> toEntity(PageInfo<DO> pageInfo, Function<DO, E> converter) {
        List<E> list = pageInfo.getList().stream().filter(Objects::nonNull).map(converter).collect(Collectors.toList());

        PageInfo<E> entityPageInfo = new PageInfo<>();
        entityPageInfo.setTotal(pageInfo.getTotal());
        entityPageInfo.setPages(pageInfo.getPages());
        entityPageInfo.setPageNum(pageInfo.getPageNum());
        entityPageInfo.setList(list);

        return entityPageInfo;
    }
}
