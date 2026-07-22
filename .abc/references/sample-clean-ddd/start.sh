eval exec "\"$JAVA_HOME/bin/java\"" -Dserver.port=8080 -Dmanagement.port=7002 -Dmanagement.server.port=7002 \
        -classpath "\"${APP_HOME}/target/${APP_NAME}\"" \
        -Dapp.location="\"${APP_HOME}/target/${APP_NAME}\""

$JAVA_HOME/bin/java -Dserver.port=8080 -Dmanagement.port=7002 -Dmanagement.server.port=7002 -classpath "{xxx}/sample-clean/sample-clean-starter/target/sample-clean" -DappLocation="{xxx}/sample-clean/sample-clean-starter/target/sample-clean"

podman run -d --name mysql-cleandb -p 3308:3306 -v ~/Documents/podman/volume/mysql/cleandb:/var/lib/mysql:Z --restart always -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=cleandb -e MYSQL_USER=admin -e MYSQL_PASSWORD=admin -e TZ=Asia/Shanghai docker.io/library/mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

podman exec -it mysql-cleandb mysql -u admin -p cleandb

CREATE TABLE `inventory` (
  `item_id` bigint(20) NOT NULL COMMENT '商品ID',
  `available_stock` int(11) NOT NULL DEFAULT '0' COMMENT '商品可用库存',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='商品库存表';

CREATE TABLE `user_order` (
    `order_id`     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单ID',
    `user_id`      VARCHAR(64)     NOT NULL COMMENT '用户ID',
    `one`          TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '是否主子一体订单 (0-否, 1-是)',
    `main`         TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '是否主订单 (0-否, 1-是)',
    `item_id`      BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
    `item_tags`    VARCHAR(512)             DEFAULT NULL COMMENT '商品标签',
    `status`       VARCHAR(32)     NOT NULL COMMENT '订单状态',
    `attributes`   TEXT                     DEFAULT NULL COMMENT '订单垂直属性 (JSON或长文本)',
    `gmt_create`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `gmt_modified` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`order_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户订单表';