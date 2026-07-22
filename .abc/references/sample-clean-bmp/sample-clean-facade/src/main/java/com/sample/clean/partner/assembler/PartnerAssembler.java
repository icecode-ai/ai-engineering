package com.sample.clean.partner.assembler;

import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * 合作伙伴包装器
 *
 * <p>外部DTO <-> 内部DTO 数据转换包装器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface PartnerAssembler {

    PartnerAssembler INSTANCE = Mappers.getMapper(PartnerAssembler.class);
}
