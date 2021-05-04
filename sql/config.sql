/*
 Navicat Premium Data Transfer

 Source Server         : 8.135.114.94-youyu
 Source Server Type    : MariaDB
 Source Server Version : 100508
 Source Host           : 172.16.5.58:3306
 Source Schema         : config

 Target Server Type    : MariaDB
 Target Server Version : 100508
 File Encoding         : 65001

 Date: 04/05/2021 15:23:30
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_cluster_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_cluster_cfg`;
CREATE TABLE `t_cluster_cfg` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET latin1 NOT NULL,
  `host` varchar(255) CHARACTER SET latin1 NOT NULL,
  `port` int(255) NOT NULL,
  `conf` text CHARACTER SET latin1 DEFAULT NULL,
  `is_launch` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=229 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_db_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_db_cfg`;
CREATE TABLE `t_db_cfg` (
  `id` int(11) NOT NULL,
  `name` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `host` varchar(255) CHARACTER SET latin1 NOT NULL,
  `port` int(255) DEFAULT NULL,
  `user` varchar(255) CHARACTER SET latin1 NOT NULL,
  `password` varchar(255) CHARACTER SET latin1 NOT NULL,
  `database` varchar(255) CHARACTER SET latin1 NOT NULL,
  `pool` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_game_server_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_game_server_cfg`;
CREATE TABLE `t_game_server_cfg` (
  `game_id` int(11) NOT NULL COMMENT '游戏ID',
  `game_name` varchar(256) CHARACTER SET utf8 DEFAULT '' COMMENT '游戏名字',
  `is_start` int(11) NOT NULL DEFAULT 0 COMMENT '1启动服务器，0已经关闭',
  `is_open` int(11) NOT NULL COMMENT '是否开启该游戏配置',
  `ip` varchar(256) CHARACTER SET utf8 DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `using_login_validatebox` int(11) NOT NULL COMMENT '是否开启登陆验证框',
  `default_lobby` int(11) NOT NULL COMMENT '是否拥有默认大厅',
  `first_game_type` int(11) NOT NULL DEFAULT 0 COMMENT '一级菜单：5斗地主，6扎金花，8百人牛牛 ，12老虎机',
  `second_game_type` int(11) NOT NULL DEFAULT 0 COMMENT '二级菜单：斗地主（1新手场2初级场3高级场4富豪场）,扎金花（1乞丐场2平民场3中端场4富豪场5贵宾场）,百人牛牛（1高倍场,2低倍场）,老虎机(1练习场,3发财场,4爆机场)',
  `player_limit` int(11) NOT NULL COMMENT '人数限制',
  `table_count` int(11) NOT NULL DEFAULT 0 COMMENT '多少桌子',
  `money_limit` int(11) NOT NULL DEFAULT 0 COMMENT '进入房间钱限制',
  `cell_money` int(11) NOT NULL DEFAULT 0 COMMENT '底注',
  `tax_open` int(11) NOT NULL DEFAULT 1 COMMENT '是否开启税收',
  `tax_show` int(11) NOT NULL DEFAULT 1 COMMENT '客户端是否显示税收',
  `tax` int(11) NOT NULL DEFAULT 0 COMMENT '多少税',
  `room_lua_cfg` text CHARACTER SET utf8 DEFAULT NULL COMMENT '房间lua配置',
  `game_switch_is_open` int(11) NOT NULL DEFAULT 0 COMMENT '单个游戏开关',
  `platform_id` varchar(255) CHARACTER SET utf8 DEFAULT '0,1' COMMENT '平台ID',
  `title` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  PRIMARY KEY (`game_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_global_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_global_cfg`;
CREATE TABLE `t_global_cfg` (
  `key` varchar(256) CHARACTER SET latin1 NOT NULL,
  `value` text CHARACTER SET latin1 DEFAULT NULL,
  PRIMARY KEY (`key`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_redis_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_redis_cfg`;
CREATE TABLE `t_redis_cfg` (
  `id` bigint(20) NOT NULL COMMENT 'id',
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `host` varchar(256) CHARACTER SET utf8 DEFAULT '' COMMENT 'ip',
  `port` int(11) NOT NULL COMMENT '端口',
  `db` int(11) NOT NULL DEFAULT 0 COMMENT '数据库号',
  `auth` varchar(256) CHARACTER SET utf8 DEFAULT '' COMMENT 'redis密码',
  `cluster` tinyint(1) DEFAULT NULL COMMENT '集群',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_service_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_service_cfg`;
CREATE TABLE `t_service_cfg` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` int(11) NOT NULL COMMENT '1:db; 2:config; 3:login; 4:gm; 5:gate; 6:game;',
  `name` varchar(255) NOT NULL,
  `is_launch` tinyint(4) NOT NULL,
  `cluster` int(11) NOT NULL,
  `conf` text DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=439 DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
