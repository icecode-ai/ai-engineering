package com.sample.clean.order.dao;

import com.sample.clean.datasource.config.PrimaryDataSourceConfiguration;
import com.sample.clean.datasource.scanner.RouterMapper;
import com.sample.clean.order.data.OrderDO;
import tk.mybatis.mapper.common.Mapper;

/**
 * 订单DAO
 *
 * @author jim
 * @date 2013-05-21
 */
@RouterMapper(dataSource = PrimaryDataSourceConfiguration.DATA_SOURCE)
public interface OrderDao extends Mapper<OrderDO> {}
