/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : frame_proxy

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:32:14
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS frame_proxy;
CREATE DATABASE frame_proxy;
USE frame_proxy;

-- ----------------------------
-- Table structure for cron_task
-- ----------------------------
DROP TABLE IF EXISTS `cron_task`;
CREATE TABLE `cron_task` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '自增ID' ,
`task_id`  int(11) NOT NULL COMMENT 'cron任务id' ,
`order_id`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '订单号规则：task_id-对应订单id' ,
`last_proxy_guid`  bigint(20) NULL DEFAULT 0 COMMENT '最后的代理商' ,
`action_num`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '操作次数，默认：0' ,
`status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '状态：-1=代理商拒绝，0=默认，1=已分配，2=接单处理中，3=失败，4=成功' ,
`is_stop`  tinyint(2) NULL DEFAULT 0 COMMENT '是否停止脚本调用：0=否，1=是' ,
`is_notice`  tinyint(2) NULL DEFAULT 0 COMMENT '给服务端发送通知，0=默认 1=失败 2=成功' ,
`is_money`  tinyint(2) NULL DEFAULT 0 COMMENT '兑换成功，给代理商打钱。0=默认，1=失败，2=成功' ,
`created_at`  int(11) NOT NULL COMMENT '创建时间(时间戳)，任务创建时间（首次）' ,
`action_last_at`  int(11) NULL DEFAULT NULL COMMENT '操作时间' ,
`success_at`  int(11) NULL DEFAULT NULL COMMENT '成功时间(时间戳)，订单兑换成功更新' ,
`distribute_more`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '分配更多信息' ,
PRIMARY KEY (`id`, `created_at`),
INDEX `idx_status` (`status`) USING BTREE ,
INDEX `idx_order_id` (`order_id`) USING BTREE ,
INDEX `id_action_last_at` (`action_last_at`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='代理cron任务表类'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of cron_task
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`pid`  int(11) NOT NULL DEFAULT 0 COMMENT '菜单关系' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单名称' ,
`icon`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '图标' ,
`slug`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单对应的权限' ,
`url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单链接地址' ,
`active`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单高亮地址' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`sort`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '排序' ,
`is_plat`  tinyint(4) NULL DEFAULT 99 COMMENT '是否展示平台' ,
`is_show`  tinyint(4) NULL DEFAULT 1 COMMENT '是否显示：1显示 0不显示' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of menus
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for password_resets
-- ----------------------------
DROP TABLE IF EXISTS `password_resets`;
CREATE TABLE `password_resets` (
`email`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`token`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
INDEX `password_resets_email_index` (`email`) USING BTREE ,
INDEX `password_resets_token_index` (`token`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of password_resets
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for permission_proxy
-- ----------------------------
DROP TABLE IF EXISTS `permission_proxy`;
CREATE TABLE `permission_proxy` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`permission_id`  int(10) UNSIGNED NOT NULL ,
`proxy_id`  int(10) UNSIGNED NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
FOREIGN KEY (`proxy_id`) REFERENCES `proxy_user` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
INDEX `permission_proxy_permission_id_index` (`permission_id`) USING BTREE ,
INDEX `permission_proxy_proxy_id_index` (`proxy_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of permission_proxy
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`permission_id`  int(10) UNSIGNED NOT NULL ,
`role_id`  int(10) UNSIGNED NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
INDEX `permission_role_permission_id_index` (`permission_id`) USING BTREE ,
INDEX `permission_role_role_id_index` (`role_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`slug`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`model`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `permissions_slug_unique` (`slug`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of permissions
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_role
-- ----------------------------
DROP TABLE IF EXISTS `proxy_role`;
CREATE TABLE `proxy_role` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`role_id`  int(10) UNSIGNED NOT NULL ,
`proxy_id`  int(10) UNSIGNED NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
INDEX `proxy_role_role_id_index` (`role_id`) USING BTREE ,
INDEX `proxy_role_proxy_id_index` (`proxy_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of proxy_role
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_setting
-- ----------------------------
DROP TABLE IF EXISTS `proxy_setting`;
CREATE TABLE `proxy_setting` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '代理商玩家ID' ,
`proxy_uid`  int(11) NOT NULL COMMENT '代理商后台账号uid' ,
`deposit`  int(11) NOT NULL COMMENT '代理押金(单位：分)' ,
`purchase_ratio`  tinyint(4) NULL DEFAULT 0 COMMENT '进货比例(单位：%)，默认：0表系统进货比例' ,
`tax_ratio`  tinyint(4) NULL DEFAULT 0 COMMENT '玩家赢税，代理抽成比例(单位：%)。默认：0表系统抽成比例' ,
`min_recharge`  int(11) NULL DEFAULT 0 COMMENT '最低代充(单位：分)。默认：0表系统最低代充' ,
`max_recharge`  int(11) NULL DEFAULT 0 COMMENT '最高代充(单位：分)。默认：0表系统最高代充' ,
`min_recycling`  int(11) NULL DEFAULT 0 COMMENT '最低回收(单位：分)。默认：0表系统最低回收' ,
`max_recycing`  int(11) NULL DEFAULT 0 COMMENT '最高回收(单位：分)。默认：0表系统最高回收' ,
`created_at`  timestamp NULL DEFAULT NULL COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `index_guid` (`guid`) USING BTREE ,
UNIQUE INDEX `index_proxy_uid` (`proxy_uid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of proxy_setting
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_user
-- ----------------------------
DROP TABLE IF EXISTS `proxy_user`;
CREATE TABLE `proxy_user` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '昵称' ,
`username`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '账号' ,
`password`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '密码' ,
`google_code`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'google验证码' ,
`guid`  int(11) NOT NULL DEFAULT 0 COMMENT '父id' ,
`parent_id`  int(11) NOT NULL DEFAULT 0 COMMENT '游戏guid' ,
`account`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '账号' ,
`platform_id`  int(11) NOT NULL DEFAULT 0 COMMENT '平台ID' ,
`email`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '邮箱' ,
`remember_token`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`grade`  tinyint(4) NOT NULL DEFAULT 10 COMMENT '等级，默认：10代理商，5总代理，1系统总代理' ,
`level`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '深度' ,
`status`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0禁用' ,
`login_ip`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '登录ip' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `users_username_unique` (`username`) USING BTREE ,
INDEX `users_guid_idx` (`guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of proxy_user
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_user_info
-- ----------------------------
DROP TABLE IF EXISTS `proxy_user_info`;
CREATE TABLE `proxy_user_info` (
`guid`  int(11) NOT NULL COMMENT '代理商游戏账户id' ,
`platform_id`  smallint(6) NULL DEFAULT NULL COMMENT '平台id' ,
`bag_id`  smallint(6) NULL DEFAULT NULL ,
`proxy_bank_pwd`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '代理商银行密码(转账要判断已经设置了密码)' ,
`connect_person`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '联系人(代理商名称)' ,
`connect_qq`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '联系QQ' ,
`connect_wx`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '联系微信' ,
`connect_alipay`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '联系支付宝' ,
`connect_phone`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '联系电话' ,
`proxy_ad_type`  tinyint(4) NULL DEFAULT 0 COMMENT '广告类型(0：无广告，1：打卡广告，2：永久广告)' ,
`sell_count`  bigint(20) NULL DEFAULT 0 COMMENT '代充值累计总额(单位：分)' ,
`purchase_count`  bigint(20) NULL DEFAULT 0 COMMENT '进货累计总额(单位：分）' ,
`recycling_count`  bigint(20) NULL DEFAULT 0 COMMENT '回购累计总额(单位：分)' ,
`recycling_number`  int(11) NULL DEFAULT 0 COMMENT '兑换(回购)总次数' ,
`day_recycling_number`  int(11) NULL DEFAULT 0 COMMENT '当日兑换次数' ,
`weights`  smallint(6) NULL DEFAULT 100 COMMENT '随机权重(最高：100)' ,
`ad_count`  bigint(20) NULL DEFAULT 0 COMMENT '广告展示次数' ,
`ad_status`  tinyint(4) NULL DEFAULT 0 COMMENT '显示状态： 0 未显示，1已显示' ,
`created_at`  timestamp NULL DEFAULT NULL COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' ,
PRIMARY KEY (`guid`),
UNIQUE INDEX `idx_guid_unique` (`guid`) USING BTREE ,
UNIQUE INDEX `idx_guid_update` (`guid`, `updated_at`) USING BTREE ,
UNIQUE INDEX `idx_guid_create` (`guid`, `created_at`) USING BTREE ,
INDEX `idx_connect_person` (`connect_person`) USING BTREE ,
INDEX `idx_connect_wx` (`connect_wx`) USING BTREE ,
INDEX `idx_platform_id` (`platform_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of proxy_user_info
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`slug`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`level`  int(11) NOT NULL DEFAULT 1 ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `roles_slug_unique` (`slug`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of roles
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for transfer_order_purchase
-- ----------------------------
DROP TABLE IF EXISTS `transfer_order_purchase`;
CREATE TABLE `transfer_order_purchase` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '自增(代理进货订单记录)' ,
`platform_id`  smallint(6) NULL DEFAULT 0 COMMENT '平台id' ,
`leader_guid`  int(11) NOT NULL COMMENT '代理组长的游戏账号' ,
`proxy_guid`  int(11) NOT NULL COMMENT '代理游戏账号' ,
`transfer_pay_money`  bigint(20) NULL DEFAULT 0 COMMENT '发起支付的金额(单位：分)' ,
`transfer_money`  bigint(20) NOT NULL DEFAULT 0 COMMENT '订单金额(单位：分)' ,
`leader_before_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '代理组长游戏账号--银行转前金额(单位：分)' ,
`leader_after_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '代理组长游戏账号--银行转后金额(单位：分)' ,
`proxy_before_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '代理游戏账号---银行转前的金额(单位：分)' ,
`proxy_after_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '代理游戏账号---银行后的金额(单位：分)' ,
`status`  tinyint(2) NULL DEFAULT 0 COMMENT '进货订单状态：-1拒绝补单，0默认，1转账中，2转账成功，3转账失败，4补转账' ,
`desc`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '补单描述' ,
`server_status`  tinyint(2) NULL DEFAULT 0 COMMENT '服务端返回状态：0默认，1发送请求，2返回成功，3返回失败，4补单' ,
`server_desc`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '服务端返回信息' ,
`proxy_ip`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理操作ip' ,
`remark`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '备注' ,
`source`  tinyint(2) NULL DEFAULT 1 COMMENT '转账来源：1web 2app' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`, `created_at`),
UNIQUE INDEX `index_create_guid_p` (`created_at`, `proxy_guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='代理进货订单记录表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of transfer_order_purchase
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for transfer_order_recycling
-- ----------------------------
DROP TABLE IF EXISTS `transfer_order_recycling`;
CREATE TABLE `transfer_order_recycling` (
`cash_order_id`  int(11) NOT NULL COMMENT '提现表订单id' ,
`platform_id`  smallint(6) NULL DEFAULT 0 COMMENT '平台ID' ,
`type`  tinyint(2) NULL DEFAULT 3 COMMENT '类型：3普通兑换(兑换码)； 4银行卡兑换' ,
`proxy_guid`  int(11) NOT NULL ,
`player_guid`  int(11) NOT NULL ,
`status`  tinyint(2) NULL DEFAULT 0 COMMENT '状态：-1=拒绝，0=默认，1=分配中，2=接单处理中，3=失败，4=成功，5=兑换码打款' ,
`cash_money`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换金额(单位：分)' ,
`redeem_code`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '兑换码' ,
`server_status`  tinyint(2) NULL DEFAULT 0 COMMENT '调用C++状态(兑换码)：0=默认，1=发送请求，2=成功， 3=失败， 99=不处理' ,
`server_desc`  varchar(512) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'C++返回信息（兑换码）' ,
`proxy_before_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '转入--代理银行前金额(单位：分)' ,
`proxy_after_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '转入--代理银行后金额(单位：分)' ,
`player_before_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '转入--玩家银行前的金额(单位：分)' ,
`player_after_bank`  bigint(20) NOT NULL DEFAULT 0 COMMENT '转入--玩家银行后的金额(单位：分)' ,
`desc`  varchar(512) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '描述' ,
`remark`  varchar(512) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '备注' ,
`source`  tinyint(2) NULL DEFAULT 1 COMMENT '转账来源：1web 2app' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`cash_order_id`, `created_at`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='代理回收订单纪录表'

;

-- ----------------------------
-- Records of transfer_order_recycling
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for transfer_order_sell
-- ----------------------------
DROP TABLE IF EXISTS `transfer_order_sell`;
CREATE TABLE `transfer_order_sell` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '自增(代理代充订单记录)' ,
`platform_id`  smallint(6) NULL DEFAULT 0 COMMENT '平台id' ,
`proxy_guid`  int(11) NOT NULL COMMENT '代理游戏账号guid' ,
`player_guid`  int(11) NOT NULL COMMENT '玩家游戏帐号guid' ,
`transfer_money`  int(11) NOT NULL DEFAULT 0 COMMENT '订单金额(单位：分)' ,
`proxy_before_bank`  int(11) NOT NULL DEFAULT 0 COMMENT '代理游戏帐号--银行转前金额(单位：分)' ,
`proxy_after_bank`  int(11) NOT NULL DEFAULT 0 COMMENT '代理游戏帐号--银行转后金额(单位：分)' ,
`player_before_bank`  int(11) NOT NULL DEFAULT 0 COMMENT '玩家游戏帐号---银行转前的金额(单位：分)' ,
`player_after_bank`  int(11) NOT NULL DEFAULT 0 COMMENT '玩家游戏帐号---银行转后的金额(单位：分)' ,
`proxy_action_status`  tinyint(2) NULL DEFAULT 0 COMMENT '代充状态：0默认，1转账中，2转账成功，3转账失败，4补转账' ,
`leader_action_status`  tinyint(2) NULL DEFAULT 0 COMMENT '代理组长补代充单：0默认，-1拒绝补单，1补单中，2补单成功，3补单失败' ,
`leader_desc`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理组长补单描述' ,
`server_status`  tinyint(2) NULL DEFAULT 0 COMMENT '服务端返回状态：0默认，1发送请求，2返回成功，3返回失败，4补单' ,
`server_desc`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '服务端返回信息' ,
`proxy_ip`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '代理操作ip' ,
`remark`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '备注' ,
`source`  tinyint(2) NULL DEFAULT 1 COMMENT '转账来源：1web 2app' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`, `created_at`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='代理代充订单纪录表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of transfer_order_sell
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for transfer_order_unusual
-- ----------------------------
DROP TABLE IF EXISTS `transfer_order_unusual`;
CREATE TABLE `transfer_order_unusual` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`type`  tinyint(4) NULL DEFAULT 1 COMMENT '异常订单类型：1=代充异常 2=进货异常' ,
`unusual_created`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '异常订单创建时' ,
`order_id`  int(11) NULL DEFAULT NULL COMMENT '订单ID(PHP订单号)' ,
`server_order_id`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '订单ID(C++订单号)' ,
`action_account`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作账号(对proxy_user.username)' ,
`action_guid`  int(11) NULL DEFAULT NULL COMMENT '操作guid(对proxy_user.guid)' ,
`unusual_type`  tinyint(4) NULL DEFAULT 1 COMMENT '异常类型：1=充错误, 2=玩家提供错单号' ,
`money`  bigint(20) NULL DEFAULT 0 COMMENT '订单金额(单位：元)' ,
`acturl_money`  bigint(20) NULL DEFAULT NULL COMMENT '实际金额（单位：元）' ,
`error_guid`  int(11) NULL DEFAULT NULL COMMENT '充错guid(对应accout.t_account.guid)' ,
`is_recover`  tinyint(4) NULL DEFAULT 0 COMMENT '是否追回 1=追回' ,
`is_repay`  tinyint(4) NULL DEFAULT 0 COMMENT '是否返还 1=返还' ,
`repay_money`  bigint(20) NULL DEFAULT 0 COMMENT '返还金额(单位：元)' ,
`repay_guid`  int(11) NULL DEFAULT NULL COMMENT '返还代理ID' ,
`repay_account`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '返还代理商账号' ,
`handle_guid`  int(11) NULL DEFAULT NULL COMMENT '处理guid(对应accout.t_account)' ,
`handle_account`  char(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '处理账号(对proxy_user.username)' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of transfer_order_unusual
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Auto increment value for cron_task
-- ----------------------------
ALTER TABLE `cron_task` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for menus
-- ----------------------------
ALTER TABLE `menus` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permission_proxy
-- ----------------------------
ALTER TABLE `permission_proxy` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permission_role
-- ----------------------------
ALTER TABLE `permission_role` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permissions
-- ----------------------------
ALTER TABLE `permissions` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for proxy_role
-- ----------------------------
ALTER TABLE `proxy_role` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for proxy_setting
-- ----------------------------
ALTER TABLE `proxy_setting` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for proxy_user
-- ----------------------------
ALTER TABLE `proxy_user` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for roles
-- ----------------------------
ALTER TABLE `roles` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for transfer_order_purchase
-- ----------------------------
ALTER TABLE `transfer_order_purchase` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for transfer_order_sell
-- ----------------------------
ALTER TABLE `transfer_order_sell` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for transfer_order_unusual
-- ----------------------------
ALTER TABLE `transfer_order_unusual` AUTO_INCREMENT=1;
