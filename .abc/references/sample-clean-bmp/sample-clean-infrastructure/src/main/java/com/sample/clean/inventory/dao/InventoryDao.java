package com.sample.clean.inventory.dao;

import com.sample.clean.datasource.config.PrimaryDataSourceConfiguration;
import com.sample.clean.datasource.scanner.RouterMapper;
import com.sample.clean.inventory.data.InventoryDO;
import tk.mybatis.mapper.common.Mapper;

/**
 * 商品库存DAO
 *
 * @author jim
 * @date 2013-05-21
 */
@RouterMapper(dataSource = PrimaryDataSourceConfiguration.DATA_SOURCE)
public interface InventoryDao extends Mapper<InventoryDO> {}
