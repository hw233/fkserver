/*
 Navicat MySQL Data Transfer

 Source Server         : localhost
 Source Server Type    : MySQL
 Source Server Version : 50728
 Source Host           : localhost:3306
 Source Schema         : recharge

 Target Server Type    : MySQL
 Target Server Version : 50728
 File Encoding         : 65001

 Date: 03/03/2020 18:54:23
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for guid_first_recharge
-- ----------------------------
DROP TABLE IF EXISTS `guid_first_recharge`;
CREATE TABLE `guid_first_recharge`  (
  `guid` int(11) NOT NULL,
  `bag_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道包ID',
  `payment_amt` double(11, 2) NULL DEFAULT NULL COMMENT '玩家首次充值金额',
  `pay_succ_time` timestamp(0) NULL DEFAULT NULL COMMENT '玩家首次充值时间',
  `id` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家首次充值记录的ID',
  `day_payment_amt` double(11, 2) NULL DEFAULT NULL COMMENT '玩家首天充值金额',
  `seniorpromoter` int(11) NULL DEFAULT NULL COMMENT '所属推广员ID',
  PRIMARY KEY (`guid`) USING BTREE,
  INDEX `idx_time_bag`(`pay_succ_time`, `bag_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for guid_last_order_time
-- ----------------------------
DROP TABLE IF EXISTS `guid_last_order_time`;
CREATE TABLE `guid_last_order_time`  (
  `guid` int(11) NOT NULL COMMENT '(该表防止玩家使用工具连续提交订单)',
  `time` timestamp(0) NULL DEFAULT NULL COMMENT '用户最近一次下单的时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for t_agent_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_agent_recharge_order`;
CREATE TABLE `t_agent_recharge_order`  (
  `transfer_id` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `proxy_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `player_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `transfer_type` int(8) NOT NULL COMMENT '0 代理商间转账 1 代理商给玩家转账 2 玩家回退代理商金币 3 代理商手机银行直接转账',
  `transfer_money` bigint(50) NULL DEFAULT 0 COMMENT '实际游戏币',
  `proxy_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:                       1 proxy_guid扣钱成功',
  `player_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:0 player_guid 待加钱  1 充值成功 ',
  `proxy_before_money` bigint(50) NULL DEFAULT 0 COMMENT 'proxy交易前游戏币',
  `proxy_after_money` bigint(50) NULL DEFAULT 0 COMMENT 'proxy交易后游戏币',
  `player_before_money` bigint(50) NULL DEFAULT 0 COMMENT 'player交易前游戏币',
  `player_after_money` bigint(50) NULL DEFAULT 0 COMMENT 'player交易后游戏币',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `channel_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号',
  `seniorpromoter` int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid',
  PRIMARY KEY (`transfer_id`, `created_at`) USING BTREE,
  INDEX `guid_index_cp_s`(`created_at`, `proxy_status`, `player_status`) USING BTREE,
  INDEX `guid_index_pl_s`(`player_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE,
  INDEX `guid_index_pr_s`(`proxy_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE,
  INDEX `index_success_s`(`updated_at`, `proxy_status`, `player_status`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值订单';

-- ----------------------------
-- Table structure for t_agent_recharge_order_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_agent_recharge_order_copy`;
CREATE TABLE `t_agent_recharge_order_copy`  (
  `transfer_id` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `proxy_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `player_guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `transfer_type` int(8) NOT NULL COMMENT '0 代理商间转账 1 代理商给玩家转账 2 玩家回退代理商金币 3 代理商手机银行直接转账',
  `transfer_money` int(50) NOT NULL DEFAULT 0 COMMENT '实际游戏币',
  `proxy_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:                       1 proxy_guid扣钱成功',
  `player_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态:0 player_guid 待加钱  1 充值成功 ',
  `proxy_before_money` int(50) NOT NULL DEFAULT 0 COMMENT 'proxy交易前游戏币',
  `proxy_after_money` int(50) NOT NULL DEFAULT 0 COMMENT 'proxy交易后游戏币',
  `player_before_money` int(50) NOT NULL DEFAULT 0 COMMENT 'player交易前游戏币',
  `player_after_money` int(50) NOT NULL DEFAULT 0 COMMENT 'player交易后游戏币',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `channel_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号',
  PRIMARY KEY (`transfer_id`, `created_at`) USING BTREE,
  INDEX `guid_index_cp_s`(`created_at`, `proxy_status`, `player_status`) USING BTREE,
  INDEX `guid_index_pl_s`(`player_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE,
  INDEX `guid_index_pr_s`(`proxy_guid`, `created_at`, `proxy_status`, `player_status`) USING BTREE,
  INDEX `index_success_s`(`updated_at`, `proxy_status`, `player_status`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值订单';

-- ----------------------------
-- Table structure for t_cash
-- ----------------------------
DROP TABLE IF EXISTS `t_cash`;
CREATE TABLE `t_cash`  (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `bag_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号',
  `ip` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP',
  `phone_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机类型ios，android',
  `phone` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机具体类型',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `coins` bigint(20) NOT NULL DEFAULT 0 COMMENT '提款金币',
  `pay_money` bigint(20) NOT NULL COMMENT '实际获得金额',
  `status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功 5挂起',
  `status_c` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家',
  `reason` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由',
  `return_c` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'C++返回扣币是否成功数据',
  `return` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '打款端返回是否打款成功数据',
  `unusual_status` tinyint(2) NULL DEFAULT 0 COMMENT '异常状态：0 默认 1 黑名单支付宝 2 黑名单Guid 3 风控异常 4 风控洗钱 5 风控羊毛党',
  `is_unusual` tinyint(2) NULL DEFAULT 0 COMMENT '异常订单处理：0 默认 1 不处理 2 可处理',
  `check_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核人',
  `check_time` timestamp(0) NULL DEFAULT NULL COMMENT '审核时间',
  `before_money` bigint(20) NULL DEFAULT NULL COMMENT '提现前金钱',
  `before_bank` bigint(20) NULL DEFAULT NULL COMMENT '提现前银行金钱',
  `after_money` bigint(20) NULL DEFAULT NULL COMMENT '提现后金钱',
  `after_bank` bigint(20) NULL DEFAULT NULL COMMENT '提现后银行金钱',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL COMMENT '修改时间',
  `type` tinyint(4) NULL DEFAULT 1 COMMENT '提现类型 1用户提现 2用户给代理商转账 3获取兑换码',
  `agent_guid` int(11) NULL DEFAULT 0 COMMENT '代理商的guid',
  `exchange_code` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '兑换码',
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `cash_channel` smallint(6) NULL DEFAULT 0 COMMENT '兑换渠道：0=默认，与t_cash_channel关联',
  `seniorpromoter` int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid',
  PRIMARY KEY (`order_id`, `created_at`) USING BTREE,
  INDEX `idx_created_at`(`created_at`, `bag_id`) USING BTREE,
  INDEX `idx_updated_at`(`updated_at`, `bag_id`) USING BTREE,
  INDEX `index_guid_created`(`guid`, `created_at`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '提现表';

-- ----------------------------
-- Table structure for t_cash_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_channel`;
CREATE TABLE `t_cash_channel`  (
  `serial` int(11) NOT NULL COMMENT '序号',
  `plat_id` int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID',
  `id` int(11) NOT NULL COMMENT '第三方兑换具体兑换方式ID',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方兑换具体兑换方式名称',
  `ratio` decimal(5, 3) UNSIGNED NOT NULL DEFAULT 0.000 COMMENT '第三方兑换的百分费率',
  `pay_business` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方兑换商家',
  `pay_select` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的兑换方式',
  `percentage` smallint(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT '百分比(越大权重越高)',
  `min_money` int(11) UNSIGNED NOT NULL DEFAULT 10 COMMENT '单次最小兑换金额(单位元)',
  `max_money` int(11) UNSIGNED NOT NULL DEFAULT 3000 COMMENT '单次最大兑换金额(单位元)',
  `day_limit` int(11) UNSIGNED NOT NULL DEFAULT 900000000 COMMENT '该兑换方式每天的限额(单位元)',
  `day_sum` int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该兑换方式今天的已兑换额度(单位元,每笔订单兑换完成都要在此处进行累加)',
  `day_sum_time` timestamp(0) NULL DEFAULT NULL COMMENT '该兑换方式今日累加金额的时间',
  `is_test` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:正在测试, 1:完成测试',
  `is_online` tinyint(1) NOT NULL DEFAULT 0 COMMENT '上线开关，1:开，0关',
  `is_show` tinyint(1) NULL DEFAULT 1 COMMENT '是否可在配置页面配置',
  `alarm_line` decimal(3, 3) NOT NULL DEFAULT 0.000 COMMENT '兑换警报百分比',
  `object_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该兑换渠道的PHP对象名',
  `callback_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '传递给第三方的回调地址',
  `risk_config` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '风控配置',
  `more_config` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '可能需要配置的更多参数',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`serial`) USING BTREE,
  UNIQUE INDEX `unq_pay_id`(`plat_id`, `id`) USING BTREE,
  UNIQUE INDEX `unq_pay_name`(`plat_id`, `name`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '兑换渠道商对应平台表配置表';

-- ----------------------------
-- Table structure for t_cash_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_copy`;
CREATE TABLE `t_cash_copy`  (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `bag_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号',
  `ip` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP',
  `phone_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机类型ios，android',
  `phone` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '手机具体类型',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `coins` bigint(20) NOT NULL DEFAULT 0 COMMENT '提款金币',
  `pay_money` bigint(20) NOT NULL COMMENT '实际获得金额',
  `status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未审核 1已通知打款 2PHP已拒绝并通知退币 3打款失败 4打款成功 5挂起',
  `status_c` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 1退币成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家',
  `reason` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '拒绝理由以及打款失败的理由',
  `return_c` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'C++返回扣币是否成功数据',
  `return` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '打款端返回是否打款成功数据',
  `unusual_status` tinyint(2) NULL DEFAULT 0 COMMENT '异常状态：0 默认 1 黑名单支付宝 2 黑名单Guid 3 风控异常 4 风控洗钱 5 风控羊毛党',
  `is_unusual` tinyint(2) NULL DEFAULT 0 COMMENT '异常订单处理：0 默认 1 不处理 2 可处理',
  `check_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核人',
  `check_time` timestamp(0) NULL DEFAULT NULL COMMENT '审核时间',
  `before_money` bigint(20) NULL DEFAULT NULL COMMENT '提现前金钱',
  `before_bank` bigint(20) NULL DEFAULT NULL COMMENT '提现前银行金钱',
  `after_money` bigint(20) NULL DEFAULT NULL COMMENT '提现后金钱',
  `after_bank` bigint(20) NULL DEFAULT NULL COMMENT '提现后银行金钱',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL COMMENT '修改时间',
  `type` tinyint(4) NULL DEFAULT 1 COMMENT '提现类型 1用户提现 2用户给代理商转账 3获取兑换码',
  `agent_guid` int(11) NULL DEFAULT 0 COMMENT '代理商的guid',
  `exchange_code` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '兑换码',
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `cash_channel` smallint(6) NULL DEFAULT 0 COMMENT '兑换渠道：0=默认，与t_cash_channel关联',
  `seniorpromoter` int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid',
  PRIMARY KEY (`order_id`, `created_at`) USING BTREE,
  INDEX `index_guid_created`(`guid`, `created_at`) USING BTREE,
  INDEX `idx_created_at`(`created_at`, `bag_id`) USING BTREE,
  INDEX `idx_updated_at`(`updated_at`, `bag_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '提现表';

-- ----------------------------
-- Table structure for t_cash_param
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_param`;
CREATE TABLE `t_cash_param`  (
  `description` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '提现类型描述',
  `cash_type` int(11) NOT NULL COMMENT '提现类型',
  `time_value` int(11) NOT NULL COMMENT '提现间隔时间',
  `money_max` bigint(2) NOT NULL DEFAULT 3000000 COMMENT '单笔提现上限 单位分',
  `cash_max_count` int(11) NOT NULL DEFAULT 50 COMMENT '提现处理条数上限',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '修改时间',
  PRIMARY KEY (`cash_type`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '提现校验参数表';

-- ----------------------------
-- Records of t_cash_param
-- ----------------------------
BEGIN;
INSERT INTO `t_cash_param` VALUES ('银行卡兑换', 6, 300, 3000000, 50, '2019-07-15 14:57:00', '2019-07-15 14:57:00');
COMMIT;

-- ----------------------------
-- Table structure for t_cash_white
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_white`;
CREATE TABLE `t_cash_white`  (
  `guid` int(11) NOT NULL COMMENT '(该表是提现测试白名单)',
  `account` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家账号',
  `cash_switch` int(11) NOT NULL COMMENT '兑换渠道号',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for t_instructor_weixin
-- ----------------------------
DROP TABLE IF EXISTS `t_instructor_weixin`;
CREATE TABLE `t_instructor_weixin`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `weixin` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '微信号',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for t_proxy_ad
-- ----------------------------
DROP TABLE IF EXISTS `t_proxy_ad`;
CREATE TABLE `t_proxy_ad`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` smallint(6) NULL DEFAULT 0 COMMENT '平台id',
  `proxy_uid` int(11) NULL DEFAULT 0 COMMENT '代理ID',
  `proxy_name` char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理名称',
  `min_recharge` bigint(20) NULL DEFAULT 0 COMMENT '最小充值额度(单位：分)',
  `proxy_alipay` char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理支付宝',
  `proxy_weixi` char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理微信',
  `proxy_qq` char(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理QQ',
  `proxy_phone` char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理电话',
  `ad_sort` tinyint(2) NULL DEFAULT 0 COMMENT '广告顺序',
  `show_proxy` tinyint(1) NULL DEFAULT 1 COMMENT '是否显示代理商(0不显示1显示)',
  `created_at` timestamp(0) NULL DEFAULT NULL COMMENT '创建时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for t_proxy_ad_copy
-- ----------------------------
DROP TABLE IF EXISTS `t_proxy_ad_copy`;
CREATE TABLE `t_proxy_ad_copy`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` smallint(6) NULL DEFAULT 0 COMMENT '平台id',
  `proxy_uid` int(11) NULL DEFAULT 0 COMMENT '代理ID',
  `proxy_name` char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理名称',
  `min_recharge` bigint(20) NULL DEFAULT 0 COMMENT '最小充值额度(单位：分)',
  `proxy_alipay` char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理支付宝',
  `proxy_weixi` char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理微信',
  `proxy_qq` char(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理QQ',
  `proxy_phone` char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理电话',
  `ad_sort` tinyint(2) NULL DEFAULT 0 COMMENT '广告顺序',
  `created_at` timestamp(0) NULL DEFAULT NULL COMMENT '创建时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for t_re_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_re_recharge`;
CREATE TABLE `t_re_recharge`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `money` bigint(20) NOT NULL COMMENT '提现金额',
  `status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '0默认 成功',
  `type` int(11) NOT NULL DEFAULT 0 COMMENT '增加类型',
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '对应id',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `index_guid_status`(`guid`, `status`) USING BTREE,
  INDEX `index_order_id_type`(`order_id`, `type`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '补充表';

-- ----------------------------
-- Table structure for t_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge`;
CREATE TABLE `t_recharge`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `platform_id` tinyint(4) NOT NULL DEFAULT 1 COMMENT '充值平台ID,与recharge.r_platform表关联',
  `guid` int(11) NULL DEFAULT NULL COMMENT '账号ID,与account.t_account关联',
  `interactive` tinyint(1) NOT NULL DEFAULT 1 COMMENT '交互：1 服务端 2支付端 3客户端',
  `param` varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '发送参数',
  `returns` varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '返回参数',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值日志表';

-- ----------------------------
-- Table structure for t_recharge_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel`;
CREATE TABLE `t_recharge_channel`  (
  `serial` int(11) NOT NULL COMMENT '序号',
  `plat_id` int(11) NULL DEFAULT 0 COMMENT '分发平台ID',
  `id` int(11) NULL DEFAULT NULL COMMENT '第三方支付具体支付方式ID',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付具体支付方式名称',
  `ratio` decimal(5, 3) UNSIGNED NULL DEFAULT 0.000 COMMENT '第三方支付的百分费率',
  `pay_business` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付商家',
  `yunwei_key` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '运维支付所用的渠道标识key,如com1pay',
  `pay_select` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式',
  `yunwei_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '运维支付所用的渠道具体类型,如CS_ALI_QRCODE',
  `percentage` smallint(6) UNSIGNED NULL DEFAULT 0 COMMENT '百分比(越大权重越高)',
  `min_money` int(11) UNSIGNED NULL DEFAULT 10 COMMENT '单次最小金额(单位元)',
  `max_money` int(11) UNSIGNED NULL DEFAULT 3000 COMMENT '单次最多金额(单位元)',
  `day_limit` int(11) UNSIGNED NULL DEFAULT 90000000 COMMENT '该支付方式每天的限额(单位元)',
  `day_sum` int(11) UNSIGNED NULL DEFAULT 0 COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  `day_sum_time` timestamp(0) NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间',
  `test_statu` tinyint(1) NULL DEFAULT 0 COMMENT '0:正在测试, 1:完成测试',
  `is_online` tinyint(1) NULL DEFAULT 0 COMMENT '上线开关，1:开，0关',
  `is_show` tinyint(1) NULL DEFAULT 1 COMMENT '是否可在配置页面配置',
  `alarm_line` decimal(3, 3) NULL DEFAULT 0.000 COMMENT '充值成功率报警线，如0.300指低于30.0%报警',
  `object_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  `callback_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '传递给第三方的回调地址',
  `more_config` text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '可能需要配置的更多参数',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`serial`) USING BTREE,
  UNIQUE INDEX `unq_pay_id`(`plat_id`, `id`) USING BTREE,
  UNIQUE INDEX `unq_pay_name`(`plat_id`, `name`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_channel.bak0826
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel.bak0826`;
CREATE TABLE `t_recharge_channel.bak0826`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '(权重分配:如果该支付渠道,已经‘上线使用’,并且未超单天额度,并且金额区间囊括此次充值金额，就可以进入权重分配)',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '分配的渠道名字',
  `ratio` decimal(5, 3) UNSIGNED NOT NULL DEFAULT 0.000 COMMENT '支付渠道的百分费率',
  `p_id` int(11) NOT NULL COMMENT '平台iD(与t_recharge_platform的id对应)',
  `pay_select` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '支持的支付方式',
  `percentage` smallint(6) NOT NULL DEFAULT 0 COMMENT '百分比(越大权重越高)',
  `min_money` double(11, 0) NULL DEFAULT NULL COMMENT '单次最小金额(单位元)',
  `max_money` double(11, 0) NULL DEFAULT NULL COMMENT '单次最多金额(单位元)',
  `day_limit` double(11, 0) NULL DEFAULT NULL COMMENT '该支付方式每天的限额(单位元)',
  `day_sum` double(11, 0) NULL DEFAULT NULL COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  `day_sum_time` timestamp(0) NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间',
  `test_statu` tinyint(1) NULL DEFAULT 0 COMMENT 'ä0:尚未测试, 1:正在测试, 2:完成测试',
  `is_online` tinyint(1) NULL DEFAULT 0 COMMENT '上线开关，1:开，0关',
  `alarm_line` decimal(3, 3) NULL DEFAULT 0.000 COMMENT '充值成功率报警线，如0.300指低于30.0%报警',
  `object_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unq_name`(`name`) USING BTREE,
  UNIQUE INDEX `unq_way`(`p_id`, `pay_select`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_channel_bak
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel_bak`;
CREATE TABLE `t_recharge_channel_bak`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `p_id` int(11) NULL DEFAULT NULL COMMENT '平台iD',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '分配的渠道名字',
  `pay_select` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式',
  `percentage` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '百分比(越大权重越高)',
  `max_money` double(11, 0) NULL DEFAULT NULL COMMENT '最多金额',
  `min_money` double(11, 0) NULL DEFAULT NULL COMMENT '最小金额',
  `is_online` int(255) NULL DEFAULT 0 COMMENT '0下线1上线 是否启用',
  `merchantKey` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '商户密钥',
  `merchantId` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '商户id',
  `request_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '请求地址',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_channel_copy0827
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_channel_copy0827`;
CREATE TABLE `t_recharge_channel_copy0827`  (
  `serial` int(11) NOT NULL COMMENT '序号',
  `plat_id` int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID',
  `id` int(11) NOT NULL COMMENT '第三方支付具体支付方式ID',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付具体支付方式名称',
  `ratio` decimal(5, 3) UNSIGNED NOT NULL DEFAULT 0.000 COMMENT '第三方支付的百分费率',
  `pay_business` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '第三方支付商家',
  `pay_select` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式',
  `percentage` smallint(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT '百分比(越大权重越高)',
  `min_money` int(11) UNSIGNED NOT NULL DEFAULT 10 COMMENT '单次最小金额(单位元)',
  `max_money` int(11) UNSIGNED NOT NULL DEFAULT 3000 COMMENT '单次最多金额(单位元)',
  `day_limit` int(11) UNSIGNED NOT NULL DEFAULT 90000000 COMMENT '该支付方式每天的限额(单位元)',
  `day_sum` int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该支付方式今天的已支付额度(单位元,每笔订单支付完成都要在此处进行累加)',
  `day_sum_time` timestamp(0) NULL DEFAULT NULL COMMENT '该支付方式今日累加金额的时间',
  `test_statu` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:正在测试, 1:完成测试',
  `is_online` tinyint(1) NOT NULL DEFAULT 0 COMMENT '上线开关，1:开，0关',
  `is_show` tinyint(1) NULL DEFAULT 1 COMMENT '是否可在配置页面配置',
  `alarm_line` decimal(3, 3) NOT NULL DEFAULT 0.000 COMMENT '充值成功率报警线，如0.300指低于30.0%报警',
  `object_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '实现该充值渠道的PHP对象名',
  `callback_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '传递给第三方的回调地址',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`serial`) USING BTREE,
  UNIQUE INDEX `unq_pay_id`(`plat_id`, `id`) USING BTREE,
  UNIQUE INDEX `unq_pay_name`(`plat_id`, `name`) USING BTREE,
  UNIQUE INDEX `unq_pay_select`(`plat_id`, `pay_business`, `pay_select`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '渠道商与充值平台中间表';

-- ----------------------------
-- Table structure for t_recharge_config
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_config`;
CREATE TABLE `t_recharge_config`  (
  `channel_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道',
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
  `status` tinyint(2) NULL DEFAULT NULL COMMENT '1 激活 其它未激活',
  PRIMARY KEY (`channel_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- ----------------------------
-- Table structure for t_recharge_order
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_order`;
CREATE TABLE `t_recharge_order`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_order_no` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '支付流水订单号',
  `guid` int(11) NOT NULL COMMENT '账号ID,与account.t_account关联',
  `bag_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `account_ip` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT 'IP地址',
  `area` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '根据IP获得地区',
  `device` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '设备号',
  `platform_id` int(11) NOT NULL DEFAULT 0 COMMENT '充值平台号',
  `seller_id` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0.0.0.0' COMMENT '商家id',
  `trade_no` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '交易订单号',
  `channel_id` int(11) NULL DEFAULT NULL COMMENT '渠道ID',
  `recharge_type` tinyint(2) NOT NULL DEFAULT 2 COMMENT '充值类型',
  `point_card_id` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '点卡ID',
  `payment_amt` double(11, 2) NULL DEFAULT 0.00 COMMENT '支付金额',
  `actual_amt` double(11, 2) NULL DEFAULT 0.00 COMMENT '实付进金额',
  `currency` varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'RMB' COMMENT '支持货币',
  `exchange_gold` int(50) NOT NULL DEFAULT 0 COMMENT '实际游戏币',
  `channel` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付渠道编码:alipay aliwap tenpay weixi applepay',
  `callback` varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '回调服务端口地址',
  `order_status` tinyint(2) NOT NULL DEFAULT 1 COMMENT '订单状态：1 生成订单 2 支付订单 3 订单失败 4 订单补发',
  `pay_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '支付返回状态: 0默认 1充值成功 2充值失败 ',
  `pay_succ_time` timestamp(0) NULL DEFAULT NULL COMMENT '支付成功的时间',
  `pay_returns` varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付回调数据',
  `server_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT '服务端返回状态:0默认 1充值成功 2无法查到此订单 3无法找到玩家所在服务器 4修改数据库bank失败 5无法找到玩家',
  `server_returns` varchar(5000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '服务端回调数据',
  `before_bank` bigint(20) NULL DEFAULT NULL COMMENT '充值前银行金钱',
  `after_bank` bigint(20) NULL DEFAULT NULL COMMENT '充值后银行金钱',
  `sign` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '签名',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0),
  `seniorpromoter` int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid',
  PRIMARY KEY (`id`, `created_at`) USING BTREE,
  UNIQUE INDEX `idx_order`(`serial_order_no`, `created_at`) USING BTREE,
  INDEX `idx_group`(`created_at`, `bag_id`) USING BTREE,
  INDEX `guid_index_p_s`(`guid`, `pay_status`, `server_status`) USING BTREE,
  INDEX `idx_succ`(`pay_succ_time`, `bag_id`) USING BTREE,
  INDEX `succ_time_and_seniorpromoter`(`pay_succ_time`, `seniorpromoter`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 63 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值订单';

-- ----------------------------
-- Records of t_recharge_order
-- ----------------------------
BEGIN;
INSERT INTO `t_recharge_order` VALUES (3, '', 1, NULL, '127.0.0.1', NULL, NULL, 0, '95677', '201908191566224340626', NULL, 2, NULL, 200.00, 0.00, 'RMB', 0, NULL, '', 1, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-19 22:19:00', '2019-08-20 21:54:36', 0), (4, '20190132213123', 1, NULL, '127.0.0.1', NULL, NULL, 0, '95677', '201908191566224375157', NULL, 2, NULL, 10.00, 100.00, 'RMB', 0, NULL, '', 2, 1, NULL, '{\"status\":\"1\",\"orderid\":\"201908191566224375157\",\"porder\":\"20190132213123\",\"money\":\"100\"}', 0, '', 0, NULL, NULL, '2019-08-19 22:19:35', '2019-08-19 22:48:45', 0), (5, '', 1, NULL, '127.0.0.1', NULL, NULL, 0, '95677', '201908191566226777859', NULL, 2, NULL, 10.00, 0.00, 'RMB', 1000, 'ZFB', '', 1, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-19 22:59:37', '2019-08-20 21:54:36', 0), (6, '', 1, NULL, '127.0.0.1', NULL, NULL, 0, '95677', '201908191566226785129', NULL, 2, NULL, 100.00, 0.00, 'RMB', 10000, 'ZFB', '', 1, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-19 22:59:45', '2019-08-20 21:54:37', 0), (7, '', 1, NULL, '127.0.0.1', NULL, NULL, 0, '95677', '201908191566226960609', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'ZFB', '', 1, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-19 23:02:40', '2019-08-20 21:54:37', 0), (8, '', 1, NULL, '127.0.0.1', NULL, NULL, 0, '95677', '201908201566230445053', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'ZFB', '', 1, 1, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-20 00:00:45', '2019-08-20 21:54:39', 0), (9, '', 50, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566457343306', NULL, 2, NULL, 100.00, 0.00, 'RMB', 10000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 1728737, NULL, NULL, '2019-08-22 15:02:23', '2019-08-22 15:02:23', 0), (10, '', 50, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566457382464', NULL, 2, NULL, 100.00, 0.00, 'RMB', 10000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 1728737, NULL, NULL, '2019-08-22 15:03:02', '2019-08-22 15:03:02', 0), (11, '', 50, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566457416971', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 1728737, NULL, NULL, '2019-08-22 15:03:36', '2019-08-22 15:03:36', 0), (12, '', 51, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566457500141', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2507389, NULL, NULL, '2019-08-22 15:05:00', '2019-08-22 15:05:00', 0), (13, '', 51, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566457593315', NULL, 2, NULL, 600.00, 0.00, 'RMB', 60000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2507389, NULL, NULL, '2019-08-22 15:06:33', '2019-08-22 15:06:33', 0), (14, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566460165455', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 15:49:25', '2019-08-22 15:49:25', 0), (15, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566460225034', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 15:50:25', '2019-08-22 15:50:25', 0), (16, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566460381583', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 15:53:01', '2019-08-22 15:53:01', 0), (17, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566460486681', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 15:54:46', '2019-08-22 15:54:46', 0), (18, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566460808638', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:00:08', '2019-08-22 16:00:08', 0), (19, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566461015191', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:03:35', '2019-08-22 16:03:35', 0), (20, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566461716940', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:15:16', '2019-08-22 16:15:16', 0), (21, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566462091121', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:21:31', '2019-08-22 16:21:31', 0), (22, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566462684154', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:31:24', '2019-08-22 16:31:24', 0), (23, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566463464044', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:44:24', '2019-08-22 16:44:24', 0), (24, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566463479127', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:44:39', '2019-08-22 16:44:39', 0), (25, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566463745799', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:49:05', '2019-08-22 16:49:05', 0), (26, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566464106786', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:55:06', '2019-08-22 16:55:06', 0), (27, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566464171362', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:56:11', '2019-08-22 16:56:11', 0), (28, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566464196315', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:56:36', '2019-08-22 16:56:36', 0), (29, '', 59, NULL, '222.209.10.50', NULL, NULL, 0, '95677', '201908221566464199125', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-22 16:56:39', '2019-08-22 16:56:39', 0), (30, '', 59, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908231566568475363', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-23 21:54:35', '2019-08-23 21:54:35', 0), (31, '', 59, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908231566568487799', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-23 21:54:47', '2019-08-23 21:54:47', 0), (32, '', 63, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908231566569095148', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-23 22:04:55', '2019-08-23 22:04:55', 0), (33, '', 63, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908231566569454988', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-23 22:10:54', '2019-08-23 22:10:54', 0), (34, '', 66, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566614279732', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 2959160, NULL, NULL, '2019-08-24 10:37:59', '2019-08-24 10:37:59', 0), (35, '', 66, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566614281499', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2959160, NULL, NULL, '2019-08-24 10:38:01', '2019-08-24 10:38:01', 0), (36, '', 71, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617643479', NULL, 2, NULL, 80000.00, 0.00, 'RMB', 8000000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-24 11:34:03', '2019-08-24 11:34:03', 0), (37, '', 71, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617650350', NULL, 2, NULL, 7000.00, 0.00, 'RMB', 700000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-24 11:34:10', '2019-08-24 11:34:10', 0), (38, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617699895', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-24 11:34:59', '2019-08-24 11:34:59', 0), (39, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617700183', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-24 11:35:00', '2019-08-24 11:35:00', 0), (40, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617701002', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-24 11:35:01', '2019-08-24 11:35:01', 0), (41, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617720314', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-24 11:35:20', '2019-08-24 11:35:20', 0), (42, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617723263', NULL, 2, NULL, 3000.00, 0.00, 'RMB', 300000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-24 11:35:23', '2019-08-24 11:35:23', 0), (43, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566617724103', NULL, 2, NULL, 3000.00, 0.00, 'RMB', 300000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-24 11:35:24', '2019-08-24 11:35:24', 0), (44, '', 74, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566618988804', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-24 11:56:28', '2019-08-24 11:56:28', 0), (45, '', 74, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566619314192', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-24 12:01:54', '2019-08-24 12:01:54', 0), (46, '', 74, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566619413410', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-24 12:03:33', '2019-08-24 12:03:33', 0), (47, '', 74, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566619497425', NULL, 2, NULL, 100.00, 0.00, 'RMB', 10000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-24 12:04:57', '2019-08-24 12:04:57', 0), (48, '', 74, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566632396119', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 9000, NULL, NULL, '2019-08-24 15:39:56', '2019-08-24 15:39:56', 0), (49, '', 66, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566648193907', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 25000000, NULL, NULL, '2019-08-24 20:03:13', '2019-08-24 20:03:13', 0), (50, '', 66, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566648197817', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 25000000, NULL, NULL, '2019-08-24 20:03:17', '2019-08-24 20:03:17', 0), (51, '', 66, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908241566648200022', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 25000000, NULL, NULL, '2019-08-24 20:03:20', '2019-08-24 20:03:20', 0), (52, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701054412', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:14', '2019-08-25 10:44:14', 0), (53, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701057216', NULL, 2, NULL, 3000.00, 0.00, 'RMB', 300000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:17', '2019-08-25 10:44:17', 0), (54, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701058351', NULL, 2, NULL, 3000.00, 0.00, 'RMB', 300000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:18', '2019-08-25 10:44:18', 0), (55, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701067836', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:27', '2019-08-25 10:44:27', 0), (56, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701070459', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:30', '2019-08-25 10:44:30', 0), (57, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701072541', NULL, 2, NULL, 500.00, 0.00, 'RMB', 50000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:32', '2019-08-25 10:44:32', 0), (58, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701074302', NULL, 2, NULL, 800.00, 0.00, 'RMB', 80000, 'WX', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:34', '2019-08-25 10:44:34', 0), (59, '', 78, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566701075827', NULL, 2, NULL, 200.00, 0.00, 'RMB', 20000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 10:44:35', '2019-08-25 10:44:35', 0), (60, '', 53, NULL, '125.69.45.79', NULL, NULL, 0, '95677', '201908251566712925334', NULL, 2, NULL, 300.00, 0.00, 'RMB', 30000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 0, NULL, NULL, '2019-08-25 14:02:05', '2019-08-25 14:02:05', 0), (61, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566717605576', NULL, 2, NULL, 5000.00, 0.00, 'RMB', 500000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-25 15:20:05', '2019-08-25 15:20:05', 0), (62, '', 54, NULL, '125.69.44.152', NULL, NULL, 0, '95677', '201908251566717606066', NULL, 2, NULL, 5000.00, 0.00, 'RMB', 500000, 'ZFB', '', 1, 0, NULL, NULL, 0, NULL, 2859000, NULL, NULL, '2019-08-25 15:20:06', '2019-08-25 15:20:06', 0);
COMMIT;

-- ----------------------------
-- Table structure for t_recharge_platform
-- ----------------------------
DROP TABLE IF EXISTS `t_recharge_platform`;
CREATE TABLE `t_recharge_platform`  (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '充值平台唯一ID',
  `name` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '接入充值平台名称',
  `developer` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '开发者',
  `client_type` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'all' COMMENT '客户端类型：all 全部, iOS 苹果, android 安卓等 ',
  `is_online` tinyint(4) NULL DEFAULT 0 COMMENT '是否上线：0下线 1上线',
  `desc` varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '描述',
  `object_name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '对象名',
  `pay_select` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支持的支付方式',
  `created_at` timestamp(0) NULL DEFAULT NULL COMMENT '开发时间',
  `updated_at` timestamp(0) NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `name`(`name`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '充值平台表';

-- ----------------------------
-- Table structure for temprecharge
-- ----------------------------
DROP TABLE IF EXISTS `temprecharge`;
CREATE TABLE `temprecharge`  (
  `guid` int(11) NULL DEFAULT NULL,
  `money` int(64) NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

SET FOREIGN_KEY_CHECKS = 1;
