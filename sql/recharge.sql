/*
 Navicat Premium Data Transfer

 Source Server         : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com
 Source Server Type    : MySQL
 Source Server Version : 50726
 Source Host           : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com:3306
 Source Schema         : recharge

 Target Server Type    : MySQL
 Target Server Version : 50726
 File Encoding         : 65001

 Date: 02/06/2020 15:13:37
*/

CREATE DATABASE IF NOT EXISTS recharge;
USE recharge;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for guid_first_recharge
-- ----------------------------
DROP TABLE IF EXISTS `guid_first_recharge`;
CREATE TABLE `guid_first_recharge` (
  `guid` int(11) NOT NULL,
  `bag_id` varchar(255) DEFAULT NULL COMMENT '渠道包ID',
  `payment_amt` double(11,2) DEFAULT NULL COMMENT '玩家首次充值金额',
  `pay_succ_time` timestamp NULL DEFAULT NULL COMMENT '玩家首次充值时间',
  `id` varchar(64) DEFAULT NULL COMMENT '玩家首次充值记录的ID',
  `day_payment_amt` double(11,2) DEFAULT NULL COMMENT '玩家首天充值金额',
  `seniorpromoter` int(11) DEFAULT NULL COMMENT '所属推广员ID',
  PRIMARY KEY (`guid`) USING BTREE,
  KEY `idx_time_bag` (`pay_succ_time`,`bag_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for guid_last_order_time
-- ----------------------------
DROP TABLE IF EXISTS `guid_last_order_time`;
CREATE TABLE `guid_last_order_time` (
  `guid` int(11) NOT NULL COMMENT '(该表防止玩家使用工具连续提交订单)',
  `time` timestamp NULL DEFAULT NULL COMMENT '用户最近一次下单的时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_agent_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_agent_recharge_order`;
CREATE TABLE `t_agent_recharge_order` (
  `transfer_id` varchar(64) NOT NULL,
  `proxy_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `player_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `transfer_type` int(8) NOT NULL COMMENT '0 代理商间转账 1 代理商给玩家转账 2 玩家回退代理商金币 3 代理商手机银行直接转账',
  `transfer_money` bigint(50) DEFAULT '0' COMMENT '实际游戏币',
  `proxy_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '状态:                       1 proxy_guid扣钱成功',
  `player_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '状态:0 player_guid 待加钱  1 充值成功 ',
  `proxy_before_money` bigint(50) DEFAULT '0' COMMENT 'proxy交易前游戏币',
  `proxy_after_money` bigint(50) DEFAULT '0' COMMENT 'proxy交易后游戏币',
  `player_before_money` bigint(50) DEFAULT '0' COMMENT 'player交易前游戏币',
  `player_after_money` bigint(50) DEFAULT '0' COMMENT 'player交易后游戏币',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  `channel_id` varchar(255) DEFAULT NULL COMMENT '渠道号',
  `seniorpromoter` int(11) NOT NULL DEFAULT '0' COMMENT '所属推广员guid',
  PRIMARY KEY (`transfer_id`,`created_at`) USING BTREE,
  KEY `guid_index_cp_s` (`created_at`,`proxy_status`,`player_status`) USING BTREE,
  KEY `guid_index_pl_s` (`player_guid`,`created_at`,`proxy_status`,`player_status`) USING BTREE,
  KEY `guid_index_pr_s` (`proxy_guid`,`created_at`,`proxy_status`,`player_status`) USING BTREE,
  KEY `index_success_s` (`updated_at`,`proxy_status`,`player_status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='充值订单';

-- ----------------------------
-- Table structure for t_agent_recharge_order_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_agent_recharge_order_copy`;
CREATE TABLE `t_agent_recharge_order_copy` (
  `transfer_id` varchar(64) NOT NULL,
  `proxy_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `player_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `transfer_type` int(8) NOT NULL COMMENT '0 代理商间转账 1 代理商给玩家转账 2 玩家回退代理商金币 3 代理商手机银行直接转账',
  `transfer_money` int(50) NOT NULL DEFAULT '0' COMMENT '实际游戏币',
  `proxy_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '状态:                       1 proxy_guid扣钱成功',
  `player_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '状态:0 player_guid 待加钱  1 充值成功 ',
  `proxy_before_money` int(50) NOT NULL DEFAULT '0' COMMENT 'proxy交易前游戏币',
  `proxy_after_money` int(50) NOT NULL DEFAULT '0' COMMENT 'proxy交易后游戏币',
  `player_before_money` int(50) NOT NULL DEFAULT '0' COMMENT 'player交易前游戏币',
  `player_after_money` int(50) NOT NULL DEFAULT '0' COMMENT 'player交易后游戏币',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  `channel_id` varchar(255) DEFAULT NULL COMMENT '渠道号',
  PRIMARY KEY (`transfer_id`,`created_at`) USING BTREE,
  KEY `guid_index_cp_s` (`created_at`,`proxy_status`,`player_status`) USING BTREE,
  KEY `guid_index_pl_s` (`player_guid`,`created_at`,`proxy_status`,`player_status`) USING BTREE,
  KEY `guid_index_pr_s` (`proxy_guid`,`created_at`,`proxy_status`,`player_status`) USING BTREE,
  KEY `index_success_s` (`updated_at`,`proxy_status`,`player_status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='充值订单';

-- ----------------------------
-- Table structure for t_cash
-- ----------------------------
DROP TABLE IF EXISTS `t_cash`;
CREATE TABLE `t_cash` (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `bag_id` varchar(255) NOT NULL DEFAULT '' COMMENT '渠道号',
  `ip` varchar(255) NOT NULL DEFAULT '' COMMENT 'IP',
  `phone_type` varchar(255) NOT NULL DEFAULT '' COMMENT '手机类型ios，android',
  `phone` varchar(255) NOT NULL DEFAULT '' COMMENT '手机具体类型',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `coins` bigint(20) NOT NULL DEFAULT '0' COMMENT '提款金币',
  `pay_money` bigint(20) NOT NULL COMMENT '实际获得金额',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功 5挂起',
  `status_c` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家',
  `reason` varchar(500) DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由',
  `return_c` varchar(500) DEFAULT NULL COMMENT 'C++返回扣币是否成功数据',
  `return` varchar(500) DEFAULT NULL COMMENT '打款端返回是否打款成功数据',
  `unusual_status` tinyint(2) DEFAULT '0' COMMENT '异常状态：0 默认 1 黑名单支付宝 2 黑名单Guid 3 风控异常 4 风控洗钱 5 风控羊毛党',
  `is_unusual` tinyint(2) DEFAULT '0' COMMENT '异常订单处理：0 默认 1 不处理 2 可处理',
  `check_name` varchar(64) DEFAULT NULL COMMENT '审核人',
  `check_time` timestamp NULL DEFAULT NULL COMMENT '审核时间',
  `before_money` bigint(20) DEFAULT NULL COMMENT '提现前金钱',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '提现前银行金钱',
  `after_money` bigint(20) DEFAULT NULL COMMENT '提现后金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '提现后银行金钱',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `type` tinyint(4) DEFAULT '1' COMMENT '提现类型 1用户提现 2用户给代理商转账 3获取兑换码',
  `agent_guid` int(11) DEFAULT '0' COMMENT '代理商的guid',
  `exchange_code` varchar(256) DEFAULT '' COMMENT '兑换码',
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  `cash_channel` smallint(6) DEFAULT '0' COMMENT '兑换渠道：0=默认，与t_cash_channel关联',
  `seniorpromoter` int(11) NOT NULL DEFAULT '0' COMMENT '所属推广员guid',
  PRIMARY KEY (`order_id`,`created_at`) USING BTREE,
  KEY `idx_created_at` (`created_at`,`bag_id`) USING BTREE,
  KEY `idx_updated_at` (`updated_at`,`bag_id`) USING BTREE,
  KEY `index_guid_created` (`guid`,`created_at`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='提现表';

-- ----------------------------
-- Table structure for t_cash_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_channel`;
CREATE TABLE `t_cash_channel` (
  `serial` int(11) NOT NULL COMMENT '序号',
  `plat_id` int(11) NOT NULL DEFAULT '0' COMMENT '分发平台ID',
  `id` int(11) NOT NULL COMMENT '第三方兑换具体兑换方式ID',
  `name` varchar(255) DEFAULT NULL COMMENT '第三方兑换具体兑换方式名称',
  `ratio` decimal(5,3) unsigned NOT NULL DEFAULT '0.000' COMMENT '第三方兑换的百分费率',
  `pay_business` varchar(255) DEFAULT NULL COMMENT '第三方兑换商家',
  `pay_select` varchar(255) DEFAULT NULL COMMENT '支持的兑换方式',
  `percentage` smallint(6) unsigned NOT NULL DEFAULT '0' COMMENT '百分比(越大权重越高)',
  `min_money` int(11) unsigned NOT NULL DEFAULT '10' COMMENT '单次最小兑换金额(单位元)',
  `max_money` int(11) unsigned NOT NULL DEFAULT '3000' COMMENT '单次最大兑换金额(单位元)',
  `day_limit` int(11) unsigned NOT NULL DEFAULT '900000000' COMMENT '该兑换方式每天的限额(单位元)',
  `day_sum` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '该兑换方式今天的已兑换额度(单位元,每笔订单兑换完成都要在此处进行累加)',
  `day_sum_time` timestamp NULL DEFAULT NULL COMMENT '该兑换方式今日累加金额的时间',
  `is_test` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:正在测试, 1:完成测试',
  `is_online` tinyint(1) NOT NULL DEFAULT '0' COMMENT '上线开关，1:开，0关',
  `is_show` tinyint(1) DEFAULT '1' COMMENT '是否可在配置页面配置',
  `alarm_line` decimal(3,3) NOT NULL DEFAULT '0.000' COMMENT '兑换警报百分比',
  `object_name` varchar(255) DEFAULT NULL COMMENT '实现该兑换渠道的PHP对象名',
  `callback_url` varchar(255) DEFAULT '' COMMENT '传递给第三方的回调地址',
  `risk_config` varchar(255) DEFAULT '' COMMENT '风控配置',
  `more_config` varchar(255) DEFAULT '' COMMENT '可能需要配置的更多参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`serial`) USING BTREE,
  UNIQUE KEY `unq_pay_id` (`plat_id`,`id`) USING BTREE,
  UNIQUE KEY `unq_pay_name` (`plat_id`,`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='兑换渠道商对应平台表配置表';

-- ----------------------------
-- Table structure for t_cash_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_copy`;
CREATE TABLE `t_cash_copy` (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `bag_id` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '渠道号',
  `ip` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT 'IP',
  `phone_type` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '手机类型ios，android',
  `phone` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '手机具体类型',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `coins` bigint(20) NOT NULL DEFAULT '0' COMMENT '提款金币',
  `pay_money` bigint(20) NOT NULL COMMENT '实际获得金额',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功 5挂起',
  `status_c` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家',
  `reason` varchar(500) CHARACTER SET utf8 DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由',
  `return_c` varchar(500) CHARACTER SET utf8 DEFAULT NULL COMMENT 'C++返回扣币是否成功数据',
  `return` varchar(500) CHARACTER SET utf8 DEFAULT NULL COMMENT '打款端返回是否打款成功数据',
  `unusual_status` tinyint(2) DEFAULT '0' COMMENT '异常状态：0 默认 1 黑名单支付宝 2 黑名单Guid 3 风控异常 4 风控洗钱 5 风控羊毛党',
  `is_unusual` tinyint(2) DEFAULT '0' COMMENT '异常订单处理：0 默认 1 不处理 2 可处理',
  `check_name` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '审核人',
  `check_time` timestamp NULL DEFAULT NULL COMMENT '审核时间',
  `before_money` bigint(20) DEFAULT NULL COMMENT '提现前金钱',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '提现前银行金钱',
  `after_money` bigint(20) DEFAULT NULL COMMENT '提现后金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '提现后银行金钱',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `type` tinyint(4) DEFAULT '1' COMMENT '提现类型 1用户提现 2用户给代理商转账 3获取兑换码',
  `agent_guid` int(11) DEFAULT '0' COMMENT '代理商的guid',
  `exchange_code` varchar(256) CHARACTER SET utf8 DEFAULT '' COMMENT '兑换码',
  `platform_id` varchar(256) CHARACTER SET utf8 DEFAULT '0' COMMENT '平台id',
  `cash_channel` smallint(6) DEFAULT '0' COMMENT '兑换渠道：0=默认，与t_cash_channel关联',
  `seniorpromoter` int(11) NOT NULL DEFAULT '0' COMMENT '所属推广员guid',
  PRIMARY KEY (`order_id`,`created_at`) USING BTREE,
  KEY `index_guid_created` (`guid`,`created_at`) USING BTREE,
  KEY `idx_created_at` (`created_at`,`bag_id`) USING BTREE,
  KEY `idx_updated_at` (`updated_at`,`bag_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='提现表';

-- ----------------------------
-- Table structure for t_cash_param
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_param`;
CREATE TABLE `t_cash_param` (
  `description` varchar(64) DEFAULT NULL COMMENT '提现类型描述',
  `cash_type` int(11) NOT NULL COMMENT '提现类型',
  `time_value` int(11) NOT NULL COMMENT '提现间隔时间',
  `money_max` bigint(2) NOT NULL DEFAULT '3000000' COMMENT '单笔提现上限 单位分',
  `cash_max_count` int(11) NOT NULL DEFAULT '50' COMMENT '提现处理条数上限',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`cash_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='提现校验参数表';

-- ----------------------------
-- Table structure for t_cash_white
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_white`;
CREATE TABLE `t_cash_white` (
  `guid` int(11) NOT NULL COMMENT '(该表是提现测试白名单)',
  `account` varchar(64) DEFAULT NULL COMMENT '玩家账号',
  `cash_switch` int(11) NOT NULL COMMENT '兑换渠道号',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_instructor_weixin
-- ----------------------------
DROP TABLE IF EXISTS `t_instructor_weixin`;
CREATE TABLE `t_instructor_weixin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `weixin` varchar(255) DEFAULT NULL COMMENT '微信号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_proxy_ad
-- ----------------------------
DROP TABLE IF EXISTS `t_proxy_ad`;
CREATE TABLE `t_proxy_ad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` smallint(6) DEFAULT '0' COMMENT '平台id',
  `proxy_uid` int(11) DEFAULT '0' COMMENT '代理ID',
  `proxy_name` char(64) DEFAULT '' COMMENT '代理名称',
  `min_recharge` bigint(20) DEFAULT '0' COMMENT '最小充值额度(单位：分)',
  `proxy_alipay` char(64) DEFAULT '' COMMENT '代理支付宝',
  `proxy_weixi` char(64) DEFAULT '' COMMENT '代理微信',
  `proxy_qq` char(20) DEFAULT '' COMMENT '代理QQ',
  `proxy_phone` char(32) DEFAULT '' COMMENT '代理电话',
  `ad_sort` tinyint(2) DEFAULT '0' COMMENT '广告顺序',
  `show_proxy` tinyint(1) DEFAULT '1' COMMENT '是否显示代理商(0不显示1显示)',
  `created_at` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_proxy_ad_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_proxy_ad_copy`;
CREATE TABLE `t_proxy_ad_copy` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` smallint(6) DEFAULT '0' COMMENT '平台id',
  `proxy_uid` int(11) DEFAULT '0' COMMENT '代理ID',
  `proxy_name` char(64) DEFAULT '' COMMENT '代理名称',
  `min_recharge` bigint(20) DEFAULT '0' COMMENT '最小充值额度(单位：分)',
  `proxy_alipay` char(64) DEFAULT '' COMMENT '代理支付宝',
  `proxy_weixi` char(64) DEFAULT '' COMMENT '代理微信',
  `proxy_qq` char(20) DEFAULT '' COMMENT '代理QQ',
  `proxy_phone` char(32) DEFAULT '' COMMENT '代理电话',
  `ad_sort` tinyint(2) DEFAULT '0' COMMENT '广告顺序',
  `created_at` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_re_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_re_recharge`;
CREATE TABLE `t_re_recharge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '0默认 成功',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '增加类型',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '对应id',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_guid_status` (`guid`,`status`) USING BTREE,
  KEY `index_order_id_type` (`order_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='补充表';

-- ----------------------------
-- Table structure for t_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge`;
CREATE TABLE `t_recharge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` tinyint(4) NOT NULL DEFAULT '1' COMMENT '充值平台ID,与recharge.r_platform表关联',
  `guid` int(11) DEFAULT NULL COMMENT '账号ID,与account.t_account关联',
  `interactive` tinyint(1) NOT NULL DEFAULT '1' COMMENT '交互：1 服务端 2支付端 3客户端',
  `param` varchar(5000) DEFAULT NULL COMMENT '发送参数',
  `returns` varchar(5000) DEFAULT NULL COMMENT '返回参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='充值日志表';

-- ----------------------------
-- Table structure for t_recharge_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel`;
CREATE TABLE `t_recharge_channel` (
  `serial` int(11) NOT NULL COMMENT '序号',
  `plat_id` int(11) DEFAULT '0' COMMENT '分发平台ID',
  `id` int(11) DEFAULT NULL COMMENT '第三方支付具体支付方式ID',
  `name` varchar(255) DEFAULT NULL COMMENT '第三方支付具体支付方式名称',
  `ratio` decimal(5,3) unsigned DEFAULT '0.000' COMMENT '第三方支付的百分费率',
  `pay_business` varchar(255) DEFAULT NULL COMMENT '第三方支付商家',
  `yunwei_key` varchar(255) NOT NULL DEFAULT '' COMMENT '运维支付所用的渠道标识key,如com1pay',
  `pay_select` varchar(255) DEFAULT NULL COMMENT '支持的支付方式',
  `yunwei_type` varchar(255) NOT NULL DEFAULT '' COMMENT '运维支付所用的渠道具体类型,如CS_ALI_QRCODE',
  `percentage` smallint(6) unsigned DEFAULT '0' COMMENT '百分比(越大权重越高)',
  `min_money` int(11) unsigned DEFAULT '10' COMMENT '单次最小金额(单位元)',
  `max_money` int(11) unsigned DEFAULT '3000' COMMENT '单次最多金额(单位元)',
  `day_limit` int(11) unsigned DEFAULT '90000000' COMMENT '该支付方式每天的限额(单位元)',
  `day_sum` int(11) unsigned DEFAULT '0' COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  `day_sum_time` timestamp NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间',
  `test_statu` tinyint(1) DEFAULT '0' COMMENT '0:正在测试, 1:完成测试',
  `is_online` tinyint(1) DEFAULT '0' COMMENT '上线开关，1:开，0关',
  `is_show` tinyint(1) DEFAULT '1' COMMENT '是否可在配置页面配置',
  `alarm_line` decimal(3,3) DEFAULT '0.000' COMMENT '充值成功率报警线，如0.300指低于30.0%报警',
  `object_name` varchar(255) DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  `callback_url` varchar(255) DEFAULT '' COMMENT '传递给第三方的回调地址',
  `more_config` text COMMENT '可能需要配置的更多参数',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`serial`) USING BTREE,
  UNIQUE KEY `unq_pay_id` (`plat_id`,`id`) USING BTREE,
  UNIQUE KEY `unq_pay_name` (`plat_id`,`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_channel.bak0826
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel.bak0826`;
CREATE TABLE `t_recharge_channel.bak0826` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '(权重分配:如果该支付渠道,已经‘上线使用’,并且未超单天额度,并且金额区间囊括此次充值金额，就可以进入权重分配)',
  `name` varchar(255) NOT NULL COMMENT '分配的渠道名字',
  `ratio` decimal(5,3) unsigned NOT NULL DEFAULT '0.000' COMMENT '支付渠道的百分费率',
  `p_id` int(11) NOT NULL COMMENT '平台iD(与t_recharge_platform的id对应)',
  `pay_select` varchar(255) NOT NULL COMMENT '支持的支付方式',
  `percentage` smallint(6) NOT NULL DEFAULT '0' COMMENT '百分比(越大权重越高)',
  `min_money` double(11,0) DEFAULT NULL COMMENT '单次最小金额(单位元)',
  `max_money` double(11,0) DEFAULT NULL COMMENT '单次最多金额(单位元)',
  `day_limit` double(11,0) DEFAULT NULL COMMENT '该支付方式每天的限额(单位元)',
  `day_sum` double(11,0) DEFAULT NULL COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  `day_sum_time` timestamp NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间',
  `test_statu` tinyint(1) DEFAULT '0' COMMENT 'ä0:尚未测试, 1:正在测试, 2:完成测试',
  `is_online` tinyint(1) DEFAULT '0' COMMENT '上线开关，1:开，0关',
  `alarm_line` decimal(3,3) DEFAULT '0.000' COMMENT '充值成功率报警线，如0.300指低于30.0%报警',
  `object_name` varchar(255) DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unq_name` (`name`) USING BTREE,
  UNIQUE KEY `unq_way` (`p_id`,`pay_select`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_channel_bak
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel_bak`;
CREATE TABLE `t_recharge_channel_bak` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `p_id` int(11) DEFAULT NULL COMMENT '平台iD',
  `name` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '分配的渠道名字',
  `pay_select` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '支持的支付方式',
  `percentage` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '百分比(越大权重越高)',
  `max_money` double(11,0) DEFAULT NULL COMMENT '最多金额',
  `min_money` double(11,0) DEFAULT NULL COMMENT '最小金额',
  `is_online` int(255) DEFAULT '0' COMMENT '0下线1上线 是否启用',
  `merchantKey` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '商户密钥',
  `merchantId` varchar(100) CHARACTER SET utf8 DEFAULT NULL COMMENT '商户id',
  `request_url` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '请求地址',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_channel_copy0827
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel_copy0827`;
CREATE TABLE `t_recharge_channel_copy0827` (
  `serial` int(11) NOT NULL COMMENT '序号',
  `plat_id` int(11) NOT NULL DEFAULT '0' COMMENT '分发平台ID',
  `id` int(11) NOT NULL COMMENT '第三方支付具体支付方式ID',
  `name` varchar(255) DEFAULT NULL COMMENT '第三方支付具体支付方式名称',
  `ratio` decimal(5,3) unsigned NOT NULL DEFAULT '0.000' COMMENT '第三方支付的百分费率',
  `pay_business` varchar(255) DEFAULT NULL COMMENT '第三方支付商家',
  `pay_select` varchar(255) DEFAULT NULL COMMENT '支持的支付方式',
  `percentage` smallint(6) unsigned NOT NULL DEFAULT '0' COMMENT '百分比(越大权重越高)',
  `min_money` int(11) unsigned NOT NULL DEFAULT '10' COMMENT '单次最小金额(单位元)',
  `max_money` int(11) unsigned NOT NULL DEFAULT '3000' COMMENT '单次最多金额(单位元)',
  `day_limit` int(11) unsigned NOT NULL DEFAULT '90000000' COMMENT '该支付方式每天的限额(单位元)',
  `day_sum` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  `day_sum_time` timestamp NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间',
  `test_statu` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:正在测试, 1:完成测试',
  `is_online` tinyint(1) NOT NULL DEFAULT '0' COMMENT '上线开关，1:开，0关',
  `is_show` tinyint(1) DEFAULT '1' COMMENT '是否可在配置页面配置',
  `alarm_line` decimal(3,3) NOT NULL DEFAULT '0.000' COMMENT '充值成功率报警线，如0.300指低于30.0%报警',
  `object_name` varchar(255) DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  `callback_url` varchar(255) DEFAULT NULL COMMENT '传递给第三方的回调地址',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`serial`) USING BTREE,
  UNIQUE KEY `unq_pay_id` (`plat_id`,`id`) USING BTREE,
  UNIQUE KEY `unq_pay_name` (`plat_id`,`name`) USING BTREE,
  UNIQUE KEY `unq_pay_select` (`plat_id`,`pay_business`,`pay_select`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_config
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_config`;
CREATE TABLE `t_recharge_config` (
  `channel_id` varchar(255) NOT NULL COMMENT '渠道',
  `charge_success_num` int(11) NOT NULL COMMENT '充值成功次数阈值',
  `agent_success_num` int(11) NOT NULL COMMENT '代理充值成功次数阈值',
  `agent_rate_def` int(10) NOT NULL COMMENT '基础显示机率',
  `charge_max` int(10) NOT NULL COMMENT '充值单次最大金额',
  `charge_time` int(10) NOT NULL COMMENT '充值间隔时间',
  `charge_times` int(10) NOT NULL COMMENT '充值超过次数',
  `charge_moneys` int(10) NOT NULL COMMENT '充值金钱超过数量',
  `agent_rate_other` int(10) NOT NULL COMMENT 'charge_times与charge_moneys 达标后 代理显示机率',
  `agent_rate_add` int(10) NOT NULL COMMENT '每次增加机率',
  `agent_close_times` int(10) NOT NULL COMMENT '关闭次数',
  `agent_rate_decr` int(10) NOT NULL COMMENT '每次减少机率',
  `status` tinyint(2) DEFAULT NULL COMMENT '1 激活 其它未激活',
  PRIMARY KEY (`channel_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_order`;
CREATE TABLE `t_recharge_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_order_no` varchar(50) NOT NULL COMMENT '支付流水订单号',
  `guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `bag_id` varchar(255) DEFAULT NULL,
  `account_ip` varchar(16) NOT NULL DEFAULT '0.0.0.0' COMMENT 'IP地址',
  `area` varchar(50) DEFAULT NULL COMMENT '根据IP获得地区',
  `device` varchar(256) DEFAULT NULL COMMENT '设备号',
  `platform_id` int(11) NOT NULL DEFAULT '0' COMMENT '充值平台号',
  `seller_id` varchar(16) NOT NULL DEFAULT '0.0.0.0' COMMENT '商家id',
  `trade_no` varchar(200) DEFAULT NULL COMMENT '交易订单号',
  `channel_id` int(11) DEFAULT NULL COMMENT '渠道ID',
  `recharge_type` tinyint(2) NOT NULL DEFAULT '2' COMMENT '充值类型',
  `point_card_id` varchar(200) DEFAULT NULL COMMENT '点卡ID',
  `payment_amt` double(11,2) DEFAULT '0.00' COMMENT '支付金额',
  `actual_amt` double(11,2) DEFAULT '0.00' COMMENT '实付进金额',
  `currency` varchar(10) NOT NULL DEFAULT 'RMB' COMMENT '支持货币',
  `exchange_gold` int(50) NOT NULL DEFAULT '0' COMMENT '实际游戏币',
  `channel` varchar(20) DEFAULT NULL COMMENT '支付渠道编码:alipay aliwap tenpay weixi applepay',
  `callback` varchar(500) NOT NULL COMMENT '回调服务端口地址',
  `order_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '订单状态：1 生成订单 2 支付订单 3 订单失败 4 订单补发',
  `pay_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '支付返回状态: 0默认 1充值成功 2充值失败 ',
  `pay_succ_time` timestamp NULL DEFAULT NULL COMMENT '支付成功的时间',
  `pay_returns` varchar(5000) DEFAULT NULL COMMENT '支付回调数据',
  `server_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '服务端返回状态:0默认 1充值成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家',
  `server_returns` varchar(5000) DEFAULT NULL COMMENT '服务端回调数据',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '充值前银行金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '充值后银行金钱',
  `sign` varchar(100) DEFAULT NULL COMMENT '签名',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `seniorpromoter` int(11) NOT NULL DEFAULT '0' COMMENT '所属推广员guid',
  PRIMARY KEY (`id`,`created_at`) USING BTREE,
  UNIQUE KEY `idx_order` (`serial_order_no`,`created_at`) USING BTREE,
  KEY `idx_group` (`created_at`,`bag_id`) USING BTREE,
  KEY `guid_index_p_s` (`guid`,`pay_status`,`server_status`) USING BTREE,
  KEY `idx_succ` (`pay_succ_time`,`bag_id`) USING BTREE,
  KEY `succ_time_and_seniorpromoter` (`pay_succ_time`,`seniorpromoter`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8 COMMENT='充值订单';

-- ----------------------------
-- Table structure for t_recharge_platform
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_platform`;
CREATE TABLE `t_recharge_platform` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '充值平台唯一ID',
  `name` varchar(100) DEFAULT NULL COMMENT '接入充值平台名称',
  `developer` varchar(64) DEFAULT NULL COMMENT '开发者',
  `client_type` varchar(20) DEFAULT 'all' COMMENT '客户端类型：all 全部, iOS 苹果, android 安卓等 ',
  `is_online` tinyint(4) DEFAULT '0' COMMENT '是否上线：0下线 1上线',
  `desc` varchar(1000) DEFAULT NULL COMMENT '描述',
  `object_name` varchar(50) DEFAULT NULL COMMENT '对象名',
  `pay_select` varchar(255) DEFAULT NULL COMMENT '支持的支付方式',
  `created_at` timestamp NULL DEFAULT NULL COMMENT '开发时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='充值平台表';

-- ----------------------------
-- Table structure for temprecharge
-- ----------------------------
DROP TABLE IF EXISTS `temprecharge`;
CREATE TABLE `temprecharge` (
  `guid` int(11) DEFAULT NULL,
  `money` int(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;
