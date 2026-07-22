package com.sample.clean.lottery.assembler;

import com.icecode.clean.common.dto.PageResponse;
import com.sample.clean.lottery.dto.DoubleColorBallDTO;
import com.sample.clean.lottery.dto.PageResponseDTO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

/**
 * 双色球数据包装器
 *
 * <p>外部DTO <-> 内部DTO 数据转换包装器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface DoubleColorBallAssembler {

    DoubleColorBallAssembler INSTANCE = Mappers.getMapper(DoubleColorBallAssembler.class);

    @Mapping(target = "success", defaultValue = "true", ignore = true)
    @Mapping(target = "errorCode", ignore = true)
    @Mapping(target = "errorMessage", ignore = true)
    @Mapping(target = "totalCount", source = "pagination.totalCount")
    @Mapping(target = "totalPage", source = "pagination.totalPage")
    @Mapping(target = "pageIndex", source = "pagination.page")
    PageResponse<DoubleColorBallDTO> to(PageResponseDTO<DoubleColorBallDTO> dto);
}
