package com.sample.clean.common.assembler;

import com.github.pagehelper.PageInfo;
import com.icecode.clean.common.dto.PageResponse;

import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 分页数据包装器
 *
 * <p>DTO <-> Domain 数据转换包装器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
public class PageAssembler {

    public static <E, DTO> PageResponse<DTO> to(PageInfo<E> pageInfo, Function<E, DTO> assembler) {
        PageResponse<DTO> response = new PageResponse<>();
        response.setSuccess(true);
        response.setTotalCount((int) pageInfo.getTotal());
        response.setTotalPage(pageInfo.getPages());
        response.setPageIndex(pageInfo.getPageNum());
        response.setData(pageInfo.getList()
            .stream()
            .filter(Objects::nonNull)
            .map(assembler)
            .collect(Collectors.toList()));

        return response;
    }

    public static <E, DTO> PageResponse<DTO> to(PageResponse<E> pageInfo, Function<E, DTO> assembler) {
        PageResponse<DTO> response = new PageResponse<>();
        response.setSuccess(pageInfo.isSuccess());
        response.setErrorCode(pageInfo.getErrorCode());
        response.setErrorMessage(pageInfo.getErrorMessage());
        response.setTotalCount(pageInfo.getTotalCount());
        response.setTotalPage(pageInfo.getTotalPage());
        response.setPageIndex(pageInfo.getPageIndex());

        if (pageInfo.isSuccess()) {
            response.setData(pageInfo.getData()
                .stream()
                .filter(Objects::nonNull)
                .map(assembler)
                .collect(Collectors.toList()));
        }

        return response;
    }
}
