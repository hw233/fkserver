/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : recharge

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:33:30
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS recharge;
CREATE DATABASE recharge;
USE recharge;

-- ----------------------------
-- Table structure for guid_first_recharge
-- ----------------------------
DROP TABLE IF EXISTS `guid_first_recharge`;
CREATE TABLE `guid_first_recharge` (
`guid`  int(11) NOT NULL ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道包ID' ,
`payment_amt`  double(11,2) NULL DEFAULT NULL COMMENT '玩家首次充值金额' ,
`pay_succ_time`  timestamp NULL DEFAULT NULL COMMENT '玩家首次充值时间' ,
`id`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家首次充值记录的ID' ,
`day_payment_amt`  double(11,2) NULL DEFAULT NULL COMMENT '玩家首天充值金额' ,
`seniorpromoter`  int(11) NULL DEFAULT NULL COMMENT '所属推广员ID' ,
PRIMARY KEY (`guid`),
INDEX `idx_time_bag` (`pay_succ_time`, `bag_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of guid_first_recharge
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for guid_last_order_time
-- ----------------------------
DROP TABLE IF EXISTS `guid_last_order_time`;
CREATE TABLE `guid_last_order_time` (
`guid`  int(11) NOT NULL COMMENT '(该表防止玩家使用工具连续提交订单)' ,
`time`  timestamp NULL DEFAULT NULL COMMENT '用户最近一次下单的时间' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of guid_last_order_time
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_agent_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_agent_recharge_order`;
CREATE TABLE `t_agent_recharge_order` (
`transfer_id`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`proxy_guid`  int(11) NOT NULL COMMENT '账号ID,与account.t_account关联' ,
`player_guid`  int(11) NOT NULL COMMENT '账号ID,与account.t_account关联' ,
`transfer_type`  int(8) NOT NULL COMMENT '0 代理商间转账 1 代理商给玩家转账 2 玩家回退代理商金币 3 代理商手机银行直接转账' ,
`transfer_money`  bigint(50) NULL DEFAULT 0 COMMENT '实际游戏币' ,
`proxy_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:                       1 proxy_guid扣钱成功' ,
`player_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:0 player_guid 待加钱  1 充值成功 ' ,
`proxy_before_money`  bigint(50) NULL DEFAULT 0 COMMENT 'proxy交易前游戏币' ,
`proxy_after_money`  bigint(50) NULL DEFAULT 0 COMMENT 'proxy交易后游戏币' ,
`player_before_money`  bigint(50) NULL DEFAULT 0 COMMENT 'player交易前游戏币' ,
`player_after_money`  bigint(50) NULL DEFAULT 0 COMMENT 'player交易后游戏币' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id' ,
`channel_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号' ,
`seniorpromoter`  int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid' ,
PRIMARY KEY (`transfer_id`, `created_at`),
INDEX `guid_index_cp_s` (`created_at`, `proxy_status`, `player_status`) USING BTREE ,
INDEX `guid_index_pl_s` (`player_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE ,
INDEX `guid_index_pr_s` (`proxy_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE ,
INDEX `index_success_s` (`updated_at`, `proxy_status`, `player_status`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值订单'

;

-- ----------------------------
-- Records of t_agent_recharge_order
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_agent_recharge_order_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_agent_recharge_order_copy`;
CREATE TABLE `t_agent_recharge_order_copy` (
`transfer_id`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`proxy_guid`  int(11) NOT NULL COMMENT '账号ID,与account.t_account关联' ,
`player_guid`  int(11) NOT NULL COMMENT '账号ID,与account.t_account关联' ,
`transfer_type`  int(8) NOT NULL COMMENT '0 代理商间转账 1 代理商给玩家转账 2 玩家回退代理商金币 3 代理商手机银行直接转账' ,
`transfer_money`  int(50) NOT NULL DEFAULT 0 COMMENT '实际游戏币' ,
`proxy_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:                       1 proxy_guid扣钱成功' ,
`player_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:0 player_guid 待加钱  1 充值成功 ' ,
`proxy_before_money`  int(50) NOT NULL DEFAULT 0 COMMENT 'proxy交易前游戏币' ,
`proxy_after_money`  int(50) NOT NULL DEFAULT 0 COMMENT 'proxy交易后游戏币' ,
`player_before_money`  int(50) NOT NULL DEFAULT 0 COMMENT 'player交易前游戏币' ,
`player_after_money`  int(50) NOT NULL DEFAULT 0 COMMENT 'player交易后游戏币' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id' ,
`channel_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号' ,
PRIMARY KEY (`transfer_id`, `created_at`),
INDEX `guid_index_cp_s` (`created_at`, `proxy_status`, `player_status`) USING BTREE ,
INDEX `guid_index_pl_s` (`player_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE ,
INDEX `guid_index_pr_s` (`proxy_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE ,
INDEX `index_success_s` (`updated_at`, `proxy_status`, `player_status`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值订单'

;

-- ----------------------------
-- Records of t_agent_recharge_order_copy
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_cash
-- ----------------------------
DROP TABLE IF EXISTS `t_cash`;
CREATE TABLE `t_cash` (
`order_id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`ip`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP' ,
`phone_type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机类型ios，android' ,
`phone`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机具体类型' ,
`money`  bigint(20) NOT NULL COMMENT '提现金额' ,
`coins`  bigint(20) NOT NULL DEFAULT 0 COMMENT '提款金币' ,
`pay_money`  bigint(20) NOT NULL COMMENT '实际获得金额' ,
`status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功 5挂起' ,
`status_c`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家' ,
`reason`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由' ,
`return_c`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'C++返回扣币是否成功数据' ,
`return`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '打款端返回是否打款成功数据' ,
`unusual_status`  tinyint(2) NULL DEFAULT 0 COMMENT '异常状态：0 默认 1 黑名单支付宝 2 黑名单Guid 3 风控异常 4 风控洗钱 5 风控羊毛党' ,
`is_unusual`  tinyint(2) NULL DEFAULT 0 COMMENT '异常订单处理：0 默认 1 不处理 2 可处理' ,
`check_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核人' ,
`check_time`  timestamp NULL DEFAULT NULL COMMENT '审核时间' ,
`before_money`  bigint(20) NULL DEFAULT NULL COMMENT '提现前金钱' ,
`before_bank`  bigint(20) NULL DEFAULT NULL COMMENT '提现前银行金钱' ,
`after_money`  bigint(20) NULL DEFAULT NULL COMMENT '提现后金钱' ,
`after_bank`  bigint(20) NULL DEFAULT NULL COMMENT '提现后银行金钱' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '修改时间' ,
`type`  tinyint(4) NULL DEFAULT 1 COMMENT '提现类型 1用户提现 2用户给代理商转账 3获取兑换码' ,
`agent_guid`  int(11) NULL DEFAULT 0 COMMENT '代理商的guid' ,
`exchange_code`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '兑换码' ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id' ,
`cash_channel`  smallint(6) NULL DEFAULT 0 COMMENT '兑换渠道：0=默认，与t_cash_channel关联' ,
`seniorpromoter`  int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid' ,
PRIMARY KEY (`order_id`, `created_at`),
INDEX `idx_created_at` (`created_at`, `bag_id`) USING BTREE ,
INDEX `idx_updated_at` (`updated_at`, `bag_id`) USING BTREE ,
INDEX `index_guid_created` (`guid`, `created_at`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='提现表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_cash
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_cash_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_channel`;
CREATE TABLE `t_cash_channel` (
`serial`  int(11) NOT NULL COMMENT '序号' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID' ,
`id`  int(11) NOT NULL COMMENT '第三方兑换具体兑换方式ID' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方兑换具体兑换方式名称' ,
`ratio`  decimal(5,3) UNSIGNED NOT NULL DEFAULT 0.000 COMMENT '第三方兑换的百分费率' ,
`pay_business`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方兑换商家' ,
`pay_select`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的兑换方式' ,
`percentage`  smallint(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT '百分比(越大权重越高)' ,
`min_money`  int(11) UNSIGNED NOT NULL DEFAULT 10 COMMENT '单次最小兑换金额(单位元)' ,
`max_money`  int(11) UNSIGNED NOT NULL DEFAULT 3000 COMMENT '单次最大兑换金额(单位元)' ,
`day_limit`  int(11) UNSIGNED NOT NULL DEFAULT 900000000 COMMENT '该兑换方式每天的限额(单位元)' ,
`day_sum`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该兑换方式今天的已兑换额度(单位元,每笔订单兑换完成都要在此处进行累加)' ,
`day_sum_time`  timestamp NULL DEFAULT NULL COMMENT '该兑换方式今日累加金额的时间' ,
`is_test`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:正在测试, 1:完成测试' ,
`is_online`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '上线开关，1:开，0关' ,
`is_show`  tinyint(1) NULL DEFAULT 1 COMMENT '是否可在配置页面配置' ,
`alarm_line`  decimal(3,3) NOT NULL DEFAULT 0.000 COMMENT '兑换警报百分比' ,
`object_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该兑换渠道的PHP对象名' ,
`callback_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '传递给第三方的回调地址' ,
`risk_config`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '风控配置' ,
`more_config`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '可能需要配置的更多参数' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `unq_pay_id` (`plat_id`, `id`) USING BTREE ,
UNIQUE INDEX `unq_pay_name` (`plat_id`, `name`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='兑换渠道商对应平台表配置表'

;

-- ----------------------------
-- Records of t_cash_channel
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_cash_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_copy`;
CREATE TABLE `t_cash_copy` (
`order_id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`ip`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP' ,
`phone_type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机类型ios，android' ,
`phone`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机具体类型' ,
`money`  bigint(20) NOT NULL COMMENT '提现金额' ,
`coins`  bigint(20) NOT NULL DEFAULT 0 COMMENT '提款金币' ,
`pay_money`  bigint(20) NOT NULL COMMENT '实际获得金额' ,
`status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功 5挂起' ,
`status_c`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家' ,
`reason`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由' ,
`return_c`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'C++返回扣币是否成功数据' ,
`return`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '打款端返回是否打款成功数据' ,
`unusual_status`  tinyint(2) NULL DEFAULT 0 COMMENT '异常状态：0 默认 1 黑名单支付宝 2 黑名单Guid 3 风控异常 4 风控洗钱 5 风控羊毛党' ,
`is_unusual`  tinyint(2) NULL DEFAULT 0 COMMENT '异常订单处理：0 默认 1 不处理 2 可处理' ,
`check_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核人' ,
`check_time`  timestamp NULL DEFAULT NULL COMMENT '审核时间' ,
`before_money`  bigint(20) NULL DEFAULT NULL COMMENT '提现前金钱' ,
`before_bank`  bigint(20) NULL DEFAULT NULL COMMENT '提现前银行金钱' ,
`after_money`  bigint(20) NULL DEFAULT NULL COMMENT '提现后金钱' ,
`after_bank`  bigint(20) NULL DEFAULT NULL COMMENT '提现后银行金钱' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '修改时间' ,
`type`  tinyint(4) NULL DEFAULT 1 COMMENT '提现类型 1用户提现 2用户给代理商转账 3获取兑换码' ,
`agent_guid`  int(11) NULL DEFAULT 0 COMMENT '代理商的guid' ,
`exchange_code`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '兑换码' ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id' ,
`cash_channel`  smallint(6) NULL DEFAULT 0 COMMENT '兑换渠道：0=默认，与t_cash_channel关联' ,
`seniorpromoter`  int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid' ,
PRIMARY KEY (`order_id`, `created_at`),
INDEX `index_guid_created` (`guid`, `created_at`) USING BTREE ,
INDEX `idx_created_at` (`created_at`, `bag_id`) USING BTREE ,
INDEX `idx_updated_at` (`updated_at`, `bag_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='提现表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_cash_copy
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_cash_param
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_param`;
CREATE TABLE `t_cash_param` (
`description`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '提现类型描述' ,
`cash_type`  int(11) NOT NULL COMMENT '提现类型' ,
`time_value`  int(11) NOT NULL COMMENT '提现间隔时间' ,
`money_max`  bigint(2) NOT NULL DEFAULT 3000000 COMMENT '单笔提现上限 单位分' ,
`cash_max_count`  int(11) NOT NULL DEFAULT 50 COMMENT '提现处理条数上限' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`update_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间' ,
PRIMARY KEY (`cash_type`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='提现校验参数表'

;

-- ----------------------------
-- Records of t_cash_param
-- ----------------------------
BEGIN;
INSERT INTO `t_cash_param` VALUES ('银行卡兑换', '6', '300', '3000000', '50', '2019-07-15 14:57:00', '2019-07-15 14:57:00');
COMMIT;

-- ----------------------------
-- Table structure for t_cash_white
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_white`;
CREATE TABLE `t_cash_white` (
`guid`  int(11) NOT NULL COMMENT '(该表是提现测试白名单)' ,
`account`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家账号' ,
`cash_switch`  int(11) NOT NULL COMMENT '兑换渠道号' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_cash_white
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_instructor_weixin
-- ----------------------------
DROP TABLE IF EXISTS `t_instructor_weixin`;
CREATE TABLE `t_instructor_weixin` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`weixin`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '微信号' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_instructor_weixin
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_proxy_ad
-- ----------------------------
DROP TABLE IF EXISTS `t_proxy_ad`;
CREATE TABLE `t_proxy_ad` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`platform_id`  smallint(6) NULL DEFAULT 0 COMMENT '平台id' ,
`proxy_uid`  int(11) NULL DEFAULT 0 COMMENT '代理ID' ,
`proxy_name`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理名称' ,
`min_recharge`  bigint(20) NULL DEFAULT 0 COMMENT '最小充值额度(单位：分)' ,
`proxy_alipay`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理支付宝' ,
`proxy_weixi`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理微信' ,
`proxy_qq`  char(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理QQ' ,
`proxy_phone`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理电话' ,
`ad_sort`  tinyint(2) NULL DEFAULT 0 COMMENT '广告顺序' ,
`show_proxy`  tinyint(1) NULL DEFAULT 1 COMMENT '是否显示代理商(0不显示1显示)' ,
`created_at`  timestamp NULL DEFAULT NULL COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_proxy_ad
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_proxy_ad_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_proxy_ad_copy`;
CREATE TABLE `t_proxy_ad_copy` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`platform_id`  smallint(6) NULL DEFAULT 0 COMMENT '平台id' ,
`proxy_uid`  int(11) NULL DEFAULT 0 COMMENT '代理ID' ,
`proxy_name`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理名称' ,
`min_recharge`  bigint(20) NULL DEFAULT 0 COMMENT '最小充值额度(单位：分)' ,
`proxy_alipay`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理支付宝' ,
`proxy_weixi`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理微信' ,
`proxy_qq`  char(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理QQ' ,
`proxy_phone`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理电话' ,
`ad_sort`  tinyint(2) NULL DEFAULT 0 COMMENT '广告顺序' ,
`created_at`  timestamp NULL DEFAULT NULL COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_proxy_ad_copy
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_re_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_re_recharge`;
CREATE TABLE `t_re_recharge` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`money`  bigint(20) NOT NULL COMMENT '提现金额' ,
`status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 成功' ,
`type`  int(11) NOT NULL DEFAULT 0 COMMENT '增加类型' ,
`order_id`  int(11) NOT NULL DEFAULT 0 COMMENT '对应id' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '修改时间' ,
PRIMARY KEY (`id`),
INDEX `index_guid_status` (`guid`, `status`) USING BTREE ,
INDEX `index_order_id_type` (`order_id`, `type`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='补充表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_re_recharge
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge`;
CREATE TABLE `t_recharge` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`platform_id`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '充值平台ID,与recharge.r_platform表关联' ,
`guid`  int(11) NULL DEFAULT NULL COMMENT '账号ID,与account.t_account关联' ,
`interactive`  tinyint(1) NOT NULL DEFAULT 1 COMMENT '交互：1 服务端 2支付端 3客户端' ,
`param`  varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '发送参数' ,
`returns`  varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '返回参数' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值日志表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_recharge
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel`;
CREATE TABLE `t_recharge_channel` (
`serial`  int(11) NOT NULL COMMENT '序号' ,
`plat_id`  int(11) NULL DEFAULT 0 COMMENT '分发平台ID' ,
`id`  int(11) NULL DEFAULT NULL COMMENT '第三方支付具体支付方式ID' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付具体支付方式名称' ,
`ratio`  decimal(5,3) UNSIGNED NULL DEFAULT 0.000 COMMENT '第三方支付的百分费率' ,
`pay_business`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付商家' ,
`yunwei_key`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '运维支付所用的渠道标识key,如com1pay' ,
`pay_select`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式' ,
`yunwei_type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '运维支付所用的渠道具体类型,如CS_ALI_QRCODE' ,
`percentage`  smallint(6) UNSIGNED NULL DEFAULT 0 COMMENT '百分比(越大权重越高)' ,
`min_money`  int(11) UNSIGNED NULL DEFAULT 10 COMMENT '单次最小金额(单位元)' ,
`max_money`  int(11) UNSIGNED NULL DEFAULT 3000 COMMENT '单次最多金额(单位元)' ,
`day_limit`  int(11) UNSIGNED NULL DEFAULT 90000000 COMMENT '该支付方式每天的限额(单位元)' ,
`day_sum`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)' ,
`day_sum_time`  timestamp NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间' ,
`test_statu`  tinyint(1) NULL DEFAULT 0 COMMENT '0:正在测试, 1:完成测试' ,
`is_online`  tinyint(1) NULL DEFAULT 0 COMMENT '上线开关，1:开，0关' ,
`is_show`  tinyint(1) NULL DEFAULT 1 COMMENT '是否可在配置页面配置' ,
`alarm_line`  decimal(3,3) NULL DEFAULT 0.000 COMMENT '充值成功率报警线，如0.300指低于30.0%报警' ,
`object_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名' ,
`callback_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '传递给第三方的回调地址' ,
`more_config`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '可能需要配置的更多参数' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `unq_pay_id` (`plat_id`, `id`) USING BTREE ,
UNIQUE INDEX `unq_pay_name` (`plat_id`, `name`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道商与充值平台中间表'

;

-- ----------------------------
-- Records of t_recharge_channel
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_channel.bak0826
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel.bak0826`;
CREATE TABLE `t_recharge_channel.bak0826` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '(权重分配:如果该支付渠道,已经‘上线使用’,并且未超单天额度,并且金额区间囊括此次充值金额，就可以进入权重分配)' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '分配的渠道名字' ,
`ratio`  decimal(5,3) UNSIGNED NOT NULL DEFAULT 0.000 COMMENT '支付渠道的百分费率' ,
`p_id`  int(11) NOT NULL COMMENT '平台iD(与t_recharge_platform的id对应)' ,
`pay_select`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '支持的支付方式' ,
`percentage`  smallint(6) NOT NULL DEFAULT 0 COMMENT '百分比(越大权重越高)' ,
`min_money`  double(11,0) NULL DEFAULT NULL COMMENT '单次最小金额(单位元)' ,
`max_money`  double(11,0) NULL DEFAULT NULL COMMENT '单次最多金额(单位元)' ,
`day_limit`  double(11,0) NULL DEFAULT NULL COMMENT '该支付方式每天的限额(单位元)' ,
`day_sum`  double(11,0) NULL DEFAULT NULL COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)' ,
`day_sum_time`  timestamp NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间' ,
`test_statu`  tinyint(1) NULL DEFAULT 0 COMMENT 'ä0:尚未测试, 1:正在测试, 2:完成测试' ,
`is_online`  tinyint(1) NULL DEFAULT 0 COMMENT '上线开关，1:开，0关' ,
`alarm_line`  decimal(3,3) NULL DEFAULT 0.000 COMMENT '充值成功率报警线，如0.300指低于30.0%报警' ,
`object_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unq_name` (`name`) USING BTREE ,
UNIQUE INDEX `unq_way` (`p_id`, `pay_select`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道商与充值平台中间表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_recharge_channel.bak0826
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_channel_bak
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel_bak`;
CREATE TABLE `t_recharge_channel_bak` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`p_id`  int(11) NULL DEFAULT NULL COMMENT '平台iD' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '分配的渠道名字' ,
`pay_select`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式' ,
`percentage`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '百分比(越大权重越高)' ,
`max_money`  double(11,0) NULL DEFAULT NULL COMMENT '最多金额' ,
`min_money`  double(11,0) NULL DEFAULT NULL COMMENT '最小金额' ,
`is_online`  int(255) NULL DEFAULT 0 COMMENT '0下线1上线 是否启用' ,
`merchantKey`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '商户密钥' ,
`merchantId`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '商户id' ,
`request_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '请求地址' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='渠道商与充值平台中间表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_recharge_channel_bak
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_channel_copy0827
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel_copy0827`;
CREATE TABLE `t_recharge_channel_copy0827` (
`serial`  int(11) NOT NULL COMMENT '序号' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID' ,
`id`  int(11) NOT NULL COMMENT '第三方支付具体支付方式ID' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付具体支付方式名称' ,
`ratio`  decimal(5,3) UNSIGNED NOT NULL DEFAULT 0.000 COMMENT '第三方支付的百分费率' ,
`pay_business`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付商家' ,
`pay_select`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式' ,
`percentage`  smallint(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT '百分比(越大权重越高)' ,
`min_money`  int(11) UNSIGNED NOT NULL DEFAULT 10 COMMENT '单次最小金额(单位元)' ,
`max_money`  int(11) UNSIGNED NOT NULL DEFAULT 3000 COMMENT '单次最多金额(单位元)' ,
`day_limit`  int(11) UNSIGNED NOT NULL DEFAULT 90000000 COMMENT '该支付方式每天的限额(单位元)' ,
`day_sum`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)' ,
`day_sum_time`  timestamp NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间' ,
`test_statu`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:正在测试, 1:完成测试' ,
`is_online`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '上线开关，1:开，0关' ,
`is_show`  tinyint(1) NULL DEFAULT 1 COMMENT '是否可在配置页面配置' ,
`alarm_line`  decimal(3,3) NOT NULL DEFAULT 0.000 COMMENT '充值成功率报警线，如0.300指低于30.0%报警' ,
`object_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名' ,
`callback_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '传递给第三方的回调地址' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `unq_pay_id` (`plat_id`, `id`) USING BTREE ,
UNIQUE INDEX `unq_pay_name` (`plat_id`, `name`) USING BTREE ,
UNIQUE INDEX `unq_pay_select` (`plat_id`, `pay_business`, `pay_select`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道商与充值平台中间表'

;

-- ----------------------------
-- Records of t_recharge_channel_copy0827
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_config
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_config`;
CREATE TABLE `t_recharge_config` (
`channel_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道' ,
`charge_success_num`  int(11) NOT NULL COMMENT '充值成功次数阈值' ,
`agent_success_num`  int(11) NOT NULL COMMENT '代理充值成功次数阈值' ,
`agent_rate_def`  int(10) NOT NULL COMMENT '基础显示机率' ,
`charge_max`  int(10) NOT NULL COMMENT '充值单次最大金额' ,
`charge_time`  int(10) NOT NULL COMMENT '充值间隔时间' ,
`charge_times`  int(10) NOT NULL COMMENT '充值超过次数' ,
`charge_moneys`  int(10) NOT NULL COMMENT '充值金钱超过数量' ,
`agent_rate_other`  int(10) NOT NULL COMMENT 'charge_times与charge_moneys 达标后 代理显示机率' ,
`agent_rate_add`  int(10) NOT NULL COMMENT '每次增加机率' ,
`agent_close_times`  int(10) NOT NULL COMMENT '关闭次数' ,
`agent_rate_decr`  int(10) NOT NULL COMMENT '每次减少机率' ,
`status`  tinyint(2) NULL DEFAULT NULL COMMENT '1 激活 其它未激活' ,
PRIMARY KEY (`channel_id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_recharge_config
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_order`;
CREATE TABLE `t_recharge_order` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`serial_order_no`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '支付流水订单号' ,
`guid`  int(11) NOT NULL COMMENT '账号ID,与account.t_account关联' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`account_ip`  varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT 'IP地址' ,
`area`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '根据IP获得地区' ,
`device`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '设备号' ,
`platform_id`  int(11) NOT NULL DEFAULT 0 COMMENT '充值平台号' ,
`seller_id`  varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT '商家id' ,
`trade_no`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '交易订单号' ,
`channel_id`  int(11) NULL DEFAULT NULL COMMENT '渠道ID' ,
`recharge_type`  tinyint(2) NOT NULL DEFAULT 2 COMMENT '充值类型' ,
`point_card_id`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '点卡ID' ,
`payment_amt`  double(11,2) NULL DEFAULT 0.00 COMMENT '支付金额' ,
`actual_amt`  double(11,2) NULL DEFAULT 0.00 COMMENT '实付进金额' ,
`currency`  varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'RMB' COMMENT '支持货币' ,
`exchange_gold`  int(50) NOT NULL DEFAULT 0 COMMENT '实际游戏币' ,
`channel`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付渠道编码:alipay aliwap tenpay weixi applepay' ,
`callback`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '回调服务端口地址' ,
`order_status`  tinyint(2) NOT NULL DEFAULT 1 COMMENT '订单状态：1 生成订单 2 支付订单 3 订单失败 4 订单补发' ,
`pay_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '支付返回状态: 0默认 1充值成功 2充值失败 ' ,
`pay_succ_time`  timestamp NULL DEFAULT NULL COMMENT '支付成功的时间' ,
`pay_returns`  varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付回调数据' ,
`server_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '服务端返回状态:0默认 1充值成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家' ,
`server_returns`  varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '服务端回调数据' ,
`before_bank`  bigint(20) NULL DEFAULT NULL COMMENT '充值前银行金钱' ,
`after_bank`  bigint(20) NULL DEFAULT NULL COMMENT '充值后银行金钱' ,
`sign`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '签名' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
`seniorpromoter`  int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid' ,
PRIMARY KEY (`id`, `created_at`),
UNIQUE INDEX `idx_order` (`serial_order_no`, `created_at`) USING BTREE ,
INDEX `idx_group` (`created_at`, `bag_id`) USING BTREE ,
INDEX `guid_index_p_s` (`guid`, `pay_status`, `server_status`) USING BTREE ,
INDEX `idx_succ` (`pay_succ_time`, `bag_id`) USING BTREE ,
INDEX `succ_time_and_seniorpromoter` (`pay_succ_time`, `seniorpromoter`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值订单'
AUTO_INCREMENT=63

;

-- ----------------------------
-- Records of t_recharge_order
-- ----------------------------
BEGIN;
INSERT INTO `t_recharge_order` VALUES ('3', '', '1', null, '127.0.0.1', null, null, '0', '95677', '201908191566224340626', null, '2', null, '200.00', '0.00', 'RMB', '0', null, '', '1', '1', null, null, '0', null, '0', null, null, '2019-08-19 22:19:00', '2019-08-20 21:54:36', '0'), ('4', '20190132213123', '1', null, '127.0.0.1', null, null, '0', '95677', '201908191566224375157', null, '2', null, '10.00', '100.00', 'RMB', '0', null, '', '2', '1', null, '{\"status\":\"1\",\"orderid\":\"201908191566224375157\",\"porder\":\"20190132213123\",\"money\":\"100\"}', '0', '', '0', null, null, '2019-08-19 22:19:35', '2019-08-19 22:48:45', '0'), ('5', '', '1', null, '127.0.0.1', null, null, '0', '95677', '201908191566226777859', null, '2', null, '10.00', '0.00', 'RMB', '1000', 'ZFB', '', '1', '1', null, null, '0', null, '0', null, null, '2019-08-19 22:59:37', '2019-08-20 21:54:36', '0'), ('6', '', '1', null, '127.0.0.1', null, null, '0', '95677', '201908191566226785129', null, '2', null, '100.00', '0.00', 'RMB', '10000', 'ZFB', '', '1', '1', null, null, '0', null, '0', null, null, '2019-08-19 22:59:45', '2019-08-20 21:54:37', '0'), ('7', '', '1', null, '127.0.0.1', null, null, '0', '95677', '201908191566226960609', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'ZFB', '', '1', '1', null, null, '0', null, '0', null, null, '2019-08-19 23:02:40', '2019-08-20 21:54:37', '0'), ('8', '', '1', null, '127.0.0.1', null, null, '0', '95677', '201908201566230445053', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'ZFB', '', '1', '1', null, null, '0', null, '0', null, null, '2019-08-20 00:00:45', '2019-08-20 21:54:39', '0'), ('9', '', '50', null, '222.209.10.50', null, null, '0', '95677', '201908221566457343306', null, '2', null, '100.00', '0.00', 'RMB', '10000', 'WX', '', '1', '0', null, null, '0', null, '1728737', null, null, '2019-08-22 15:02:23', '2019-08-22 15:02:23', '0'), ('10', '', '50', null, '222.209.10.50', null, null, '0', '95677', '201908221566457382464', null, '2', null, '100.00', '0.00', 'RMB', '10000', 'ZFB', '', '1', '0', null, null, '0', null, '1728737', null, null, '2019-08-22 15:03:02', '2019-08-22 15:03:02', '0'), ('11', '', '50', null, '222.209.10.50', null, null, '0', '95677', '201908221566457416971', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '1728737', null, null, '2019-08-22 15:03:36', '2019-08-22 15:03:36', '0'), ('12', '', '51', null, '222.209.10.50', null, null, '0', '95677', '201908221566457500141', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '2507389', null, null, '2019-08-22 15:05:00', '2019-08-22 15:05:00', '0'), ('13', '', '51', null, '222.209.10.50', null, null, '0', '95677', '201908221566457593315', null, '2', null, '600.00', '0.00', 'RMB', '60000', 'ZFB', '', '1', '0', null, null, '0', null, '2507389', null, null, '2019-08-22 15:06:33', '2019-08-22 15:06:33', '0'), ('14', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566460165455', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 15:49:25', '2019-08-22 15:49:25', '0'), ('15', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566460225034', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 15:50:25', '2019-08-22 15:50:25', '0'), ('16', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566460381583', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 15:53:01', '2019-08-22 15:53:01', '0'), ('17', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566460486681', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 15:54:46', '2019-08-22 15:54:46', '0'), ('18', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566460808638', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:00:08', '2019-08-22 16:00:08', '0'), ('19', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566461015191', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:03:35', '2019-08-22 16:03:35', '0'), ('20', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566461716940', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:15:16', '2019-08-22 16:15:16', '0'), ('21', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566462091121', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:21:31', '2019-08-22 16:21:31', '0'), ('22', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566462684154', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:31:24', '2019-08-22 16:31:24', '0'), ('23', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566463464044', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:44:24', '2019-08-22 16:44:24', '0'), ('24', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566463479127', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:44:39', '2019-08-22 16:44:39', '0'), ('25', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566463745799', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:49:05', '2019-08-22 16:49:05', '0'), ('26', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566464106786', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:55:06', '2019-08-22 16:55:06', '0'), ('27', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566464171362', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:56:11', '2019-08-22 16:56:11', '0'), ('28', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566464196315', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:56:36', '2019-08-22 16:56:36', '0'), ('29', '', '59', null, '222.209.10.50', null, null, '0', '95677', '201908221566464199125', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-22 16:56:39', '2019-08-22 16:56:39', '0'), ('30', '', '59', null, '125.69.44.152', null, null, '0', '95677', '201908231566568475363', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-23 21:54:35', '2019-08-23 21:54:35', '0'), ('31', '', '59', null, '125.69.44.152', null, null, '0', '95677', '201908231566568487799', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-23 21:54:47', '2019-08-23 21:54:47', '0'), ('32', '', '63', null, '125.69.44.152', null, null, '0', '95677', '201908231566569095148', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-23 22:04:55', '2019-08-23 22:04:55', '0'), ('33', '', '63', null, '125.69.44.152', null, null, '0', '95677', '201908231566569454988', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-23 22:10:54', '2019-08-23 22:10:54', '0'), ('34', '', '66', null, '125.69.44.152', null, null, '0', '95677', '201908241566614279732', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'WX', '', '1', '0', null, null, '0', null, '2959160', null, null, '2019-08-24 10:37:59', '2019-08-24 10:37:59', '0'), ('35', '', '66', null, '125.69.44.152', null, null, '0', '95677', '201908241566614281499', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'ZFB', '', '1', '0', null, null, '0', null, '2959160', null, null, '2019-08-24 10:38:01', '2019-08-24 10:38:01', '0'), ('36', '', '71', null, '125.69.44.152', null, null, '0', '95677', '201908241566617643479', null, '2', null, '80000.00', '0.00', 'RMB', '8000000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-24 11:34:03', '2019-08-24 11:34:03', '0'), ('37', '', '71', null, '125.69.44.152', null, null, '0', '95677', '201908241566617650350', null, '2', null, '7000.00', '0.00', 'RMB', '700000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-24 11:34:10', '2019-08-24 11:34:10', '0'), ('38', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908241566617699895', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-24 11:34:59', '2019-08-24 11:34:59', '0'), ('39', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908241566617700183', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-24 11:35:00', '2019-08-24 11:35:00', '0'), ('40', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908241566617701002', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-24 11:35:01', '2019-08-24 11:35:01', '0'), ('41', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908241566617720314', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'WX', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-24 11:35:20', '2019-08-24 11:35:20', '0'), ('42', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908241566617723263', null, '2', null, '3000.00', '0.00', 'RMB', '300000', 'WX', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-24 11:35:23', '2019-08-24 11:35:23', '0'), ('43', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908241566617724103', null, '2', null, '3000.00', '0.00', 'RMB', '300000', 'WX', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-24 11:35:24', '2019-08-24 11:35:24', '0'), ('44', '', '74', null, '125.69.44.152', null, null, '0', '95677', '201908241566618988804', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-24 11:56:28', '2019-08-24 11:56:28', '0'), ('45', '', '74', null, '125.69.44.152', null, null, '0', '95677', '201908241566619314192', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-24 12:01:54', '2019-08-24 12:01:54', '0'), ('46', '', '74', null, '125.69.44.152', null, null, '0', '95677', '201908241566619413410', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-24 12:03:33', '2019-08-24 12:03:33', '0'), ('47', '', '74', null, '125.69.44.152', null, null, '0', '95677', '201908241566619497425', null, '2', null, '100.00', '0.00', 'RMB', '10000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-24 12:04:57', '2019-08-24 12:04:57', '0'), ('48', '', '74', null, '125.69.44.152', null, null, '0', '95677', '201908241566632396119', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '9000', null, null, '2019-08-24 15:39:56', '2019-08-24 15:39:56', '0'), ('49', '', '66', null, '125.69.44.152', null, null, '0', '95677', '201908241566648193907', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'WX', '', '1', '0', null, null, '0', null, '25000000', null, null, '2019-08-24 20:03:13', '2019-08-24 20:03:13', '0'), ('50', '', '66', null, '125.69.44.152', null, null, '0', '95677', '201908241566648197817', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'WX', '', '1', '0', null, null, '0', null, '25000000', null, null, '2019-08-24 20:03:17', '2019-08-24 20:03:17', '0'), ('51', '', '66', null, '125.69.44.152', null, null, '0', '95677', '201908241566648200022', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'ZFB', '', '1', '0', null, null, '0', null, '25000000', null, null, '2019-08-24 20:03:20', '2019-08-24 20:03:20', '0'), ('52', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701054412', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:14', '2019-08-25 10:44:14', '0'), ('53', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701057216', null, '2', null, '3000.00', '0.00', 'RMB', '300000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:17', '2019-08-25 10:44:17', '0'), ('54', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701058351', null, '2', null, '3000.00', '0.00', 'RMB', '300000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:18', '2019-08-25 10:44:18', '0'), ('55', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701067836', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:27', '2019-08-25 10:44:27', '0'), ('56', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701070459', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:30', '2019-08-25 10:44:30', '0'), ('57', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701072541', null, '2', null, '500.00', '0.00', 'RMB', '50000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:32', '2019-08-25 10:44:32', '0'), ('58', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701074302', null, '2', null, '800.00', '0.00', 'RMB', '80000', 'WX', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:34', '2019-08-25 10:44:34', '0'), ('59', '', '78', null, '125.69.44.152', null, null, '0', '95677', '201908251566701075827', null, '2', null, '200.00', '0.00', 'RMB', '20000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 10:44:35', '2019-08-25 10:44:35', '0'), ('60', '', '53', null, '125.69.45.79', null, null, '0', '95677', '201908251566712925334', null, '2', null, '300.00', '0.00', 'RMB', '30000', 'ZFB', '', '1', '0', null, null, '0', null, '0', null, null, '2019-08-25 14:02:05', '2019-08-25 14:02:05', '0'), ('61', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908251566717605576', null, '2', null, '5000.00', '0.00', 'RMB', '500000', 'ZFB', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-25 15:20:05', '2019-08-25 15:20:05', '0'), ('62', '', '54', null, '125.69.44.152', null, null, '0', '95677', '201908251566717606066', null, '2', null, '5000.00', '0.00', 'RMB', '500000', 'ZFB', '', '1', '0', null, null, '0', null, '2859000', null, null, '2019-08-25 15:20:06', '2019-08-25 15:20:06', '0');
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_platform
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_platform`;
CREATE TABLE `t_recharge_platform` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '充值平台唯一ID' ,
`name`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '接入充值平台名称' ,
`developer`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '开发者' ,
`client_type`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'all' COMMENT '客户端类型：all 全部, iOS 苹果, android 安卓等 ' ,
`is_online`  tinyint(4) NULL DEFAULT 0 COMMENT '是否上线：0下线 1上线' ,
`desc`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '描述' ,
`object_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '对象名' ,
`pay_select`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式' ,
`created_at`  timestamp NULL DEFAULT NULL COMMENT '开发时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `name` (`name`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值平台表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_recharge_platform
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_test_guids
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_test_guids`;
CREATE TABLE `t_recharge_test_guids` (
`guid`  int(11) NOT NULL COMMENT '(该表是充值测试白名单)' ,
`account`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家账号' ,
`r_channel_id`  int(11) NOT NULL COMMENT '充值渠道ID，表t_recharge_channel中的id' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_recharge_test_guids
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for temprecharge
-- ----------------------------
DROP TABLE IF EXISTS `temprecharge`;
CREATE TABLE `temprecharge` (
`guid`  int(11) NULL DEFAULT NULL ,
`money`  int(64) NULL DEFAULT NULL 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of temprecharge
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Procedure structure for charge_rate
-- ----------------------------
DROP PROCEDURE IF EXISTS `charge_rate`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `charge_rate`(IN `GUID_` int , IN `channel_id_` varchar(256))
    COMMENT 'GUID_ '
BEGIN
    
    DECLARE charge_num_         INTEGER DEFAULT 0; 
    DECLARE charge_money_       INTEGER DEFAULT 0; 
    DECLARE agent_num_          INTEGER DEFAULT 0; 
    DECLARE agent_money_        INTEGER DEFAULT 0; 
    DECLARE charge_success_num_ INTEGER DEFAULT 0;
    DECLARE agent_success_num_  INTEGER DEFAULT 0;
    DECLARE agent_rate_def_     INTEGER DEFAULT 0;
    DECLARE charge_max_         INTEGER DEFAULT 0;
    DECLARE charge_time_        INTEGER DEFAULT 0;
    DECLARE charge_times_       INTEGER DEFAULT 0;
    DECLARE charge_moneys_      INTEGER DEFAULT 0;
    DECLARE agent_rate_other_   INTEGER DEFAULT 0;
    DECLARE agent_rate_add_     INTEGER DEFAULT 0;
    DECLARE agent_close_times_  INTEGER DEFAULT 0;
    DECLARE agent_rate_decr_    INTEGER DEFAULT 0;
    
    select count(1),ifnull(sum(exchange_gold),0) into charge_num_,charge_money_ from t_recharge_order where pay_status = 1 and server_status = 1 and guid = GUID_;
    select count(1),ifnull(sum(transfer_money),0) into agent_num_,agent_money_ from `t_Agent_recharge_order` where proxy_status = 1 and player_status = 1 and player_guid = GUID_ and transfer_type = '1';
    select `charge_success_num` ,`agent_success_num` , `agent_rate_def` , `charge_max` , `charge_time` , `charge_times` , `charge_moneys` , `agent_rate_other` , `agent_rate_add` , `agent_close_times` , `agent_rate_decr` into
        charge_success_num_ , agent_success_num_ , agent_rate_def_ , charge_max_ , charge_time_ , charge_times_ , charge_moneys_ , agent_rate_other_ , agent_rate_add_ , agent_close_times_ , agent_rate_decr_ 
        from t_recharge_config where channel_id = channel_id_ and status = 1;

    select charge_num_ as charge_num ,charge_money_ as charge_money,  agent_num_ as agent_num , agent_money_ as agent_money, 
    charge_success_num_ as charge_success_num , agent_success_num_ as agent_success_num , agent_rate_def_ as agent_rate_def , charge_max_ as charge_max , charge_time_ as charge_time , charge_times_ as charge_times , 
    charge_moneys_ as charge_moneys , agent_rate_other_ as agent_rate_other , agent_rate_add_ as agent_rate_add , agent_close_times_ as agent_close_times , agent_rate_decr_ as agent_rate_decr ;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for check_cash_time
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_cash_time`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `check_cash_time`(IN `guid` int,IN `cash_type_` int)
BEGIN
	DECLARE order_id_one_minute INT DEFAULT 0;
    DECLARE time_ int default 60;
    DECLARE money_max_ int default 3000000;
    DECLARE cash_max_count_ int default 50;
    DECLARE cash_max_count_temp int default 0;
    
    
    select time_value,money_max,cash_max_count into time_,money_max_,cash_max_count_ from t_cash_param where cash_type = cash_type_;
    select count(1) into cash_max_count_temp from t_cash where status = 0 LIMIT  cash_max_count_;
	SELECT order_id FROM t_cash WHERE t_cash.guid = guid AND t_cash.created_at > DATE_SUB(NOW(),INTERVAL time_ SECOND) and type = cash_type_ LIMIT 1 INTO order_id_one_minute;
	select order_id_one_minute as order_id,time_ as time_value,money_max_ as money_max , if(cash_max_count_temp >= cash_max_count_ , '2' , '1') as cash_max_count;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_account`(IN `account_` VARCHAR(64), IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建账号'
BEGIN
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE registerCount int DEFAULT '0';
	SET password_ = MD5(account_);
	SET nickname_ = CONCAT("guest_", get_guest_id());
	select count(*) into registerCount from t_account where ip = ip_ and create_time > date_sub(curdate(),interval 0 day);	
	if registerCount < 3 then
		INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES (account_,password_,0,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_);		
		SELECT account_ AS account, password_ AS password, LAST_INSERT_ID() AS guid, nickname_ AS nickname;
	end if;	
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_guest_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_guest_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_guest_account`(IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256))
    COMMENT '创建游客账号'
BEGIN
	DECLARE guest_id_ BIGINT;
	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE no_bank_password INT DEFAULT 0;
	DECLARE vip_ INT DEFAULT 0;
	DECLARE login_time_ INT;
	DECLARE logout_time_ INT;
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
	DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
	DECLARE change_alipay_num_ INT DEFAULT 0;
	DECLARE disabled_ INT DEFAULT 0;
	DECLARE risk_ INT DEFAULT 0;
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE is_first INT DEFAULT 1;
	DECLARE channel_lock_ INT DEFAULT 0;
	DECLARE registerCount int DEFAULT '0';
	select count(*) into registerCount from t_account where ip = ip_ and create_time > date_sub(curdate(),interval 0 day);	
	if registerCount < 3 then
		SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
		IF guid_ = 0 THEN
			SET guid_ = get_guest_id();
			SET account_ = CONCAT("guest_", guid_);
			SET password_ = MD5(account_);
			SET nickname_ = CONCAT("guest_", guid_);
			SELECT channel_lock INTO channel_lock_ FROM t_channel_invite WHERE channel_id=channel_id_ AND big_lock=1;
			IF channel_lock_ != 1 THEN
				SET is_first = 2;
			END IF;
			INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code) VALUES (account_,password_,1,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,HEX(guid_));
			SELECT guid, account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer INTO guid_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_ FROM t_account WHERE imei = imei_;
		ELSE
			SET is_first = 2;
			IF disabled_ = 1 THEN
				SET ret = 15;
			ELSE
				UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
			END IF;
		END IF;
			
		SELECT is_first,ret, guid_ as guid, account_ as account, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer;
	
	end if;	
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for get_proxy_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_proxy_info`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_proxy_info`(IN `platform_id_` int)
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE ret_ INT DEFAULT 0;
	DECLARE id_ INT DEFAULT 0;
	DECLARE proxy_name_ varchar(256) DEFAULT '';
	DECLARE min_recharge_ INT DEFAULT 0;
	DECLARE proxy_qq_ varchar(256) DEFAULT '';
	DECLARE proxy_weixi_ varchar(256) DEFAULT '';
	DECLARE proxy_alipay_ varchar(256) DEFAULT '';
	DECLARE proxy_phone_ varchar(256) DEFAULT '';
	DECLARE result_ TEXT DEFAULT '';

	DECLARE cur1 CURSOR FOR SELECT id,proxy_name,min_recharge,proxy_qq,proxy_weixi,proxy_alipay,proxy_phone FROM t_proxy_ad WHERE platform_id = platform_id_ AND show_proxy = 1;
	
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

	OPEN cur1;

	SET result_ = CONCAT('\nplatform_id: ', platform_id_,'\n');

	REPEAT
		FETCH cur1 INTO id_, proxy_name_, min_recharge_,proxy_qq_,proxy_weixi_,proxy_alipay_,proxy_phone_;
		IF NOT done THEN
				SET result_ = CONCAT(result_, 'pb_proxy_list{\nproxy_id:', id_, '\nname:"', proxy_name_, '"\nmin_recharge:', min_recharge_, '\nqq:"', proxy_qq_, '"\nweixin:"', proxy_weixi_, '"\nzfb:"', proxy_alipay_, '"\nphone:"', proxy_phone_, '"\n}\n');
		END IF;
	UNTIL done END REPEAT;

	SELECT ret_, result_;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for insert_AgentTransfer_Order
-- ----------------------------
DROP PROCEDURE IF EXISTS `insert_AgentTransfer_Order`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_AgentTransfer_Order`(IN `transfer_id_` varchar(64),  IN `proxy_guid` int,IN `player_guid` int, IN `transfer_type` int, IN `transfer_money` bigint,IN `platform_id_` varchar(256),IN `channel_id_` varchar(255), IN `seniorpromoter_` int)
    COMMENT '代理上转账订单金币流水'
BEGIN
	DECLARE ret_code INT DEFAULT 0;
	DECLARE order_count INT DEFAULT 0;

	SELECT count(1) INTO order_count FROM t_Agent_recharge_order WHERE transfer_id = transfer_id_;

	IF order_count = 0 THEN
		INSERT INTO t_Agent_recharge_order (`transfer_id`,`proxy_guid`,`player_guid`,`transfer_type`,`transfer_money`,`platform_id`,`channel_id`,`seniorpromoter`) VALUES (transfer_id_,proxy_guid,player_guid,transfer_type,transfer_money,platform_id_,channel_id_,seniorpromoter_);

		IF ROW_COUNT() > 0 THEN
			SELECT 1 INTO ret_code;
		ELSE
			SELECT 0 INTO ret_code;
		END IF;
		
	ELSE
		SELECT 2 INTO ret_code;
	END IF;
	
	select ret_code as ret;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for insert_cash_money
-- ----------------------------
DROP PROCEDURE IF EXISTS `insert_cash_money`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_cash_money`(IN `guid` int(11),IN `money` bigint(20),IN `coins` bigint(20),IN `pay_money` bigint(20),IN `ip` varchar(255),IN `phone` varchar(255),IN `phone_type` varchar(255),IN `bag_id` varchar(255), IN `before_money` bigint(20),IN  `before_bank` bigint(20),IN  `after_money` bigint(20),IN  `after_bank` bigint(20),IN  `type_` tinyint(4),IN `agent_guid_` int(11),IN `platform_id_` varchar(255) , IN seniorpromoter_ int(11))
BEGIN
	DECLARE max_order_id INT DEFAULT 0;

	INSERT INTO t_cash (`guid`,`money`,`coins`,`pay_money`,`ip`,`phone`,`phone_type`,`bag_id`, `before_money`, `before_bank`, `after_money`, `after_bank`, `type`, `agent_guid`, `platform_id`,`seniorpromoter`)
  VALUES (guid,money,coins,pay_money,ip,phone,phone_type,bag_id, before_money, before_bank, after_money,after_bank,type_,agent_guid_,platform_id_,seniorpromoter_);

	SELECT LAST_INSERT_ID() INTO max_order_id;
	
	select max_order_id as order_id;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for order_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `order_select`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `order_select`(IN `orderid_` int(11), IN `guid_` int(11))
BEGIN
	DECLARE order_status_ int default 0;
	select count(1) into order_status_ from t_recharge_order where pay_status = 1 and server_status = 0 and id = orderid_ and guid = guid_;
	IF order_status_ = 0 THEN
		select 999 into order_status_ from t_recharge_order where pay_status = 1 and server_status = 1 and id = orderid_ and guid = guid_;
	END IF;
	select order_status_ as retCode;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for proc_recharge_order
-- ----------------------------
DROP PROCEDURE IF EXISTS `proc_recharge_order`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_recharge_order`(IN `guid_` int)
    COMMENT '得到充值数据'
BEGIN
	DECLARE done INT DEFAULT 0;
	DECLARE result_ TEXT DEFAULT '';
	DECLARE result_bank_save_back TEXT DEFAULT '';
	DECLARE id_ int(11);
    DECLARE exchange_gold_ int(50);
    DECLARE actual_amt_ double(11,2);
    DECLARE payment_amt_ double(11,2);
    DECLARE serial_order_no_ varchar(50);
    DECLARE ret int;
    DECLARE oldbank bigint(50);
    DECLARE newbank bigint(50);
    DECLARE bank_moeny_temp bigint(50);
    DECLARE bank_moeny bigint(50) default 0;
    DECLARE type_ int;
    DECLARE order_id_ int(11);
    
	DECLARE cur1 CURSOR FOR select id,exchange_gold,actual_amt,payment_amt,serial_order_no from t_recharge_order where pay_status = 1 and server_status = 0 and guid = guid_;
    DECLARE cur2 CURSOR FOR select id,money,type,order_id from t_re_recharge where  guid = guid_ and status = 0;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

    set result_ = '{ ';
    
    
	OPEN cur1;
    set result_ = concat( result_ , '"recharge" :  [  ');
    REPEAT
    FETCH cur1 INTO id_, exchange_gold_, actual_amt_, payment_amt_, serial_order_no_;
    if not done then
        set ret = 0,oldbank = 0 , newbank = 0;
        update t_recharge_order set server_status = 1 where id = id_ and pay_status = 1 and server_status = 0;
        IF ROW_COUNT() > 0 THEN
            call `game`.`recharge_use_change_player_bank_money`(guid_,exchange_gold_,ret , oldbank , newbank );
            if ret = 1 then
                set bank_moeny = newbank;
                set result_ = concat( result_ ,'{ "id": ', id_ , ' , "exchange_gold" : ' , exchange_gold_ , ' , "actual_amt" : ' , actual_amt_ , ' , "payment_amt" : ', payment_amt_ , ' , "serial_order_no" : "' , serial_order_no_ , '" , "oldbank" : ', oldbank , ' , "newbank" : ' , newbank , ' } ,\n' );
                update t_recharge_order set server_status = 1 ,before_bank = oldbank , after_bank = newbank  where id = id_ and pay_status = 1 and server_status = 1;
            else
                update t_recharge_order set server_status = 0 where id = id_ and pay_status = 1 and server_status = 1;
            end if;
        END IF;
    end if;
    UNTIL done END REPEAT;
    set result_ = left(result_ , char_length(result_) - 2);
    set result_ = concat( result_ , '\n]');
    
    set done = 0;
    open cur2;
    set result_ = concat( result_ , ',\n ');
    set result_ = concat( result_ , '"recash" :  [  ');
    REPEAT
    FETCH cur2 INTO id_, exchange_gold_, type_, order_id_;
    if not done then
        set ret = 0,oldbank = 0 , newbank = 0;
        update t_re_recharge set status = 1 where id = id_ and status = 0;
        if ROW_COUNT() > 0 then
            call `game`.`recharge_use_change_player_bank_money`(guid_, exchange_gold_, ret , oldbank , newbank );
            if ret = 1 then
                set bank_moeny = newbank;
                set result_ = concat( result_ ,'{ "id": ', id_ , ' , "exchange_gold" : ' , exchange_gold_ , ' , "opttype" : ' , type_ , ' , "order_id" : ', order_id_ , ' , "oldbank" : ', oldbank , ' , "newbank" : ',  newbank, ' } ,\n' );
                -- update t_recharge_order set server_status = 1, before_bank = oldbank , after_bank = newbank  where id = id_;
                update t_re_recharge set status = 1, updated_at = current_timestamp where  id = id_;
                update t_cash set status_c = 1 where  order_id = order_id_;
            else
                update t_re_recharge set status = 0 where id = id_ and status = 1;
            end if;
        end if;
    end if;
    UNTIL done END REPEAT;
    set result_ = left(result_ , char_length(result_) - 2);
    set result_ = concat( result_ , '\n]');
    -- 存取钱失败后 玩家不在线 回存处理
    -- call `game`.`proc_bank_save_back`(guid_ , result_bank_save_back , bank_moeny_temp);
    -- if bank_moeny_temp is not null then
    --     set bank_moeny = bank_moeny_temp;
    --     set result_ = concat( result_ , result_bank_save_back);
    -- end if;
    
    set result_ = concat( result_ , ',\n "bank" : ', bank_moeny ,'}');
	SELECT result_ as retdata;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for update_AgentTransfer_Order
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_AgentTransfer_Order`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_AgentTransfer_Order`(IN `transfer_id_` varchar(64),  IN `opt_type` int, IN `status_` tinyint, IN `before_money` bigint, IN `after_money` bigint)
BEGIN
	DECLARE ret_code INT DEFAULT 0;
	DECLARE order_count INT DEFAULT 0;

	SELECT count(1) INTO order_count FROM t_Agent_recharge_order WHERE transfer_id = transfer_id_;

	IF order_count = 0 THEN
		SELECT 0 INTO ret_code;
	ELSE
		IF opt_type = 1 THEN
			UPDATE t_Agent_recharge_order SET proxy_status = status_,proxy_before_money = before_money,proxy_after_money = after_money,updated_at=current_timestamp WHERE transfer_id = transfer_id_;
		ELSEIF opt_type = 2 THEN
			UPDATE t_Agent_recharge_order SET player_status= status_,player_before_money= before_money,player_after_money= after_money,updated_at=current_timestamp WHERE transfer_id = transfer_id_;
		END IF;
		
		IF ROW_COUNT() > 0 THEN
			SELECT 1 INTO ret_code;
		ELSE
			SELECT 0 INTO ret_code;
		END IF;

	END IF;
	
	select ret_code as ret;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for update_recharge_order
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_recharge_order`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_recharge_order`(IN `orderid` int(11),
								 IN `beforbank_` bigint(20),
								 IN `afterbank_` bigint(20))
    COMMENT '更新订单表数据，参数orderid：订单id，beforbank_：充值前银行金钱 , afterbank_: 充值后银行金钱'
BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE after_bank_N bigint(20);
	DECLARE befor_bank_N bigint(20);
	DECLARE server_status_N  tinyint(2);
	
	update t_recharge_order set server_status = 1, before_bank = beforbank_, after_bank = afterbank_ where  id = orderid;
	
	select server_status , before_bank , after_bank into server_status_N , befor_bank_N , after_bank_N from t_recharge_order where  id = orderid;
	
	if server_status_N != 1 or befor_bank_N !=  beforbank_ or after_bank_N != afterbank_ then
		set ret = 1;
	else
		set ret = 0;
	end if;
	select ret as retCode;
END
;;
DELIMITER ;

-- ----------------------------
-- Auto increment value for t_cash
-- ----------------------------
ALTER TABLE `t_cash` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_cash_copy
-- ----------------------------
ALTER TABLE `t_cash_copy` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_instructor_weixin
-- ----------------------------
ALTER TABLE `t_instructor_weixin` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_proxy_ad
-- ----------------------------
ALTER TABLE `t_proxy_ad` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_proxy_ad_copy
-- ----------------------------
ALTER TABLE `t_proxy_ad_copy` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_re_recharge
-- ----------------------------
ALTER TABLE `t_re_recharge` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_recharge
-- ----------------------------
ALTER TABLE `t_recharge` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_recharge_channel.bak0826
-- ----------------------------
ALTER TABLE `t_recharge_channel.bak0826` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_recharge_channel_bak
-- ----------------------------
ALTER TABLE `t_recharge_channel_bak` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_recharge_order
-- ----------------------------
ALTER TABLE `t_recharge_order` AUTO_INCREMENT=63;

-- ----------------------------
-- Auto increment value for t_recharge_platform
-- ----------------------------
ALTER TABLE `t_recharge_platform` AUTO_INCREMENT=1;
