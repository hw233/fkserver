/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : account

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:29:38
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS account;
CREATE DATABASE account;
USE account;

-- ----------------------------
-- Table structure for black_alipay
-- ----------------------------
DROP TABLE IF EXISTS `black_alipay`;
CREATE TABLE `black_alipay` (
`alipay`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '支付宝账号(加黑将导致提现被挂起)' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加黑的原因' ,
`handler`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`alipay`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of black_alipay
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for black_guid
-- ----------------------------
DROP TABLE IF EXISTS `black_guid`;
CREATE TABLE `black_guid` (
`guid`  int(11) NOT NULL COMMENT 'guid(加黑将导致提现被挂起)' ,
`phone`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联加黑的手机号，即account' ,
`mac`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联加黑的imei' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加黑的原因' ,
`handler`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of black_guid
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for cash_ali_account
-- ----------------------------
DROP TABLE IF EXISTS `cash_ali_account`;
CREATE TABLE `cash_ali_account` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`ali_account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`admin_account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=2

;

-- ----------------------------
-- Records of cash_ali_account
-- ----------------------------
BEGIN;
INSERT INTO `cash_ali_account` VALUES ('1', 'rojmloj', '2019-08-15 00:14:26', '2019-08-15 00:14:26', 'admin@163.com');
COMMIT;

-- ----------------------------
-- Table structure for feedback
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`processing_status`  int(11) NULL DEFAULT NULL ,
`guid`  int(11) NULL DEFAULT NULL ,
`reply_id`  int(11) NULL DEFAULT NULL ,
`account`  int(11) NULL DEFAULT NULL ,
`content`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`is_readme`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`author`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`processing_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feng_guid
-- ----------------------------
DROP TABLE IF EXISTS `feng_guid`;
CREATE TABLE `feng_guid` (
`guid`  int(11) NOT NULL COMMENT '要封掉的guid' ,
`phone`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的手机号，即account' ,
`mac`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的imei' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封号的原因' ,
`handler`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of feng_guid
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feng_guid_copy
-- ----------------------------
DROP TABLE IF EXISTS `feng_guid_copy`;
CREATE TABLE `feng_guid_copy` (
`guid`  int(11) NOT NULL COMMENT '要封掉的guid' ,
`phone`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的手机号，即account' ,
`mac`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的imei' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封号的原因' ,
`handler`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of feng_guid_copy
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feng_ip
-- ----------------------------
DROP TABLE IF EXISTS `feng_ip`;
CREATE TABLE `feng_ip` (
`ip`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '封掉的IP' ,
`area`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '该IP所在的区域' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封IP的原因' ,
`handler`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`ip`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of feng_ip
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for imei_update_fail_list
-- ----------------------------
DROP TABLE IF EXISTS `imei_update_fail_list`;
CREATE TABLE `imei_update_fail_list` (
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`platform_id`  smallint(6) NULL DEFAULT 0 COMMENT '平台id' ,
`ip`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '客户端ip' ,
`imei`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '准备更新的imei' ,
`deprecated_imei`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '原imei 即guid 现在所对应的imei' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`guid`, `created_at`),
INDEX `index_imei` (`imei`) USING BTREE ,
INDEX `index_deprecated_imei` (`deprecated_imei`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of imei_update_fail_list
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for kill_guid
-- ----------------------------
DROP TABLE IF EXISTS `kill_guid`;
CREATE TABLE `kill_guid` (
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`user`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '操作人' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`guid`),
INDEX `idx_created_at` (`created_at`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of kill_guid
-- ----------------------------
BEGIN;
INSERT INTO `kill_guid` VALUES ('21', 'admin@163.com', '2019-08-15 22:21:41'), ('24', 'admin@163.com', '2019-08-15 11:16:58');
COMMIT;

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`active`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`url`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`name`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`child`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
`sort`  int(10) NULL DEFAULT NULL ,
`slug`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`pid`  int(11) NULL DEFAULT NULL ,
`icon`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=45

;

-- ----------------------------
-- Records of menus
-- ----------------------------
BEGIN;
INSERT INTO `menus` VALUES ('1', '0', '/account/index', '玩家管理', '1', '2019-08-17 13:08:16', '2019-08-17 13:08:16', null, 'account.index', null, null), ('2', '0', '/index/index', '系统管理', null, '2019-08-17 00:18:13', '2019-08-17 00:18:15', null, 'index.index', null, null), ('3', '0', '/users/index', '用户列表', null, '2019-08-17 00:18:13', '2019-08-17 00:18:15', null, 'users.index', null, null), ('4', '0', '/roles/index', '角色管理', null, '2019-08-17 00:18:13', '2019-08-17 00:18:15', null, 'roles.index', null, null), ('5', '0', '/permissions/index', '权限管理', null, '2019-08-17 00:18:13', '2019-08-17 00:18:16', null, 'permissions.index', null, null), ('6', '0', '/version/view', '版本管理', '1', '2019-08-17 13:08:15', '2019-08-17 13:08:15', null, 'version.view', null, null), ('7', '0', '/client/gameTax', '房间管理', null, '2019-08-17 13:21:03', '2019-08-17 13:21:03', null, 'client.gametax', null, null), ('8', '0', '/cash/index', '提现管理', '1', '2019-08-17 13:07:32', '2019-08-17 13:07:32', null, 'cash.index', null, null), ('12', '0', '/cash/index', '提现列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', null, 'cash.index', '8', null), ('13', '0', '/cash/risk', '风控列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', null, 'cash.risk', '8', null), ('14', '0', '/cash/riskSystem', '风控比例', '1', '2019-08-17 13:20:57', '2019-08-17 13:20:57', null, 'cash.risksystem', '8', null), ('15', '0', '/cash/servers', '服务器列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', null, 'cash.servers', '8', null), ('16', '0', '/cash/aliAccount', '支付宝黑名单', '1', '2019-08-17 13:20:51', '2019-08-17 13:20:51', null, 'cash.aliaccount', '8', null), ('17', '0', '/notice/index', '通知管理', '1', '2019-08-17 13:08:14', '2019-08-17 13:08:14', null, 'notice.index', null, null), ('18', '0', '/notice/system', '通知列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', null, 'notice.system', '17', null), ('19', '0', '/notice/specify', '私信列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:17', null, 'notice.specify', '17', null), ('20', '0', '/notice/sms', '短信列表', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', null, 'notice.sms', '17', null), ('21', '0', '/feedback/index', '反馈管理', '1', '2019-08-17 13:08:15', '2019-08-17 13:08:15', null, 'feedback.index', null, null), ('22', '0', '/feedback/index', '反馈列表', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', null, 'feedback.index', '21', null), ('23', '0', '/feedback/quickReplyType', '快捷回复', '1', '2019-08-17 13:21:08', '2019-08-17 13:21:08', null, 'feedback.quickreplytype', '21', null), ('24', '0', '/feedback/banSay', '玩家禁言', '1', '2019-08-17 13:20:44', '2019-08-17 13:20:44', null, 'feedback.bansay', '21', null), ('25', '0', '/version/view', '添加版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', null, 'version.view', '6', null), ('26', '0', '/version/frame', '框架版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', null, 'version.frame', '6', null), ('27', '0', '/version/hall', '大厅版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', null, 'version.hall', '6', null), ('28', '0', '/version/game', '游戏版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', null, 'version.game', '6', null), ('29', '0', '/client/index', '客户端配置', '1', '2019-08-17 13:08:19', '2019-08-17 13:08:19', null, 'client.index', null, null), ('30', '0', '/client/viewConfig', '创建配置', null, '2019-08-17 13:20:30', '2019-08-17 13:20:30', null, 'client.viewconfig', '29', null), ('31', '0', '/client/listConfig', '配置列表', null, '2019-08-17 13:20:34', '2019-08-17 13:20:34', null, 'client.listconfig', '29', null), ('32', '0', '/client/template', '模版列表', null, '2019-08-17 00:18:16', '2019-08-17 00:18:18', null, 'client.template', '29', null), ('33', '0', '/client/templateCreate', '创建模板', null, '2019-08-17 13:20:27', '2019-08-17 13:20:27', null, 'client.templatecreate', '29', null), ('34', '0', '/client/templateConfigCreate', '导入模板', null, '2019-08-17 13:20:22', '2019-08-17 13:20:22', null, 'client.templateconfigcreate', '29', null), ('35', '0', '/client/gameTax', '税收配置', null, '2019-08-17 13:20:40', '2019-08-17 13:20:40', null, 'client.gametax', '29', null), ('36', '0', '/cash/customer', '客服提现管理', null, '2019-08-17 00:18:16', '2019-08-17 00:18:18', null, 'cash.customer', '8', null), ('37', '0', '/rechargeorder/index', '充值列表', null, '2019-08-17 00:18:16', '2019-08-17 00:18:19', null, 'rechargeorder.index', null, null), ('38', '0', '/distribution/index', '渠道商管理', null, '2019-08-17 00:18:17', '2019-08-17 00:18:19', null, 'distribution.index', null, null), ('39', '0', '/account/index', '玩家列表', null, '2019-08-17 00:18:17', '2019-08-17 00:18:19', null, 'account.index', '1', null), ('40', '0', '/account/riskStar', '星级关注', null, '2019-08-17 13:19:57', '2019-08-17 13:19:57', null, 'account.riskstar', '1', null), ('41', '0', '/account/logLogin', '登陆日志', null, '2019-08-17 13:19:51', '2019-08-17 13:19:51', null, 'account.loglogin', '1', null), ('42', '0', '/gameConfig/index', '游戏配置', '1', '2019-08-17 13:19:33', '2019-08-17 13:19:33', null, 'gameconfig.index', null, null), ('43', '0', '/gameConfig/index', '配置首页', null, '2019-08-17 13:20:08', '2019-08-17 13:20:08', null, 'gameconfig.index', '42', null), ('44', '0', '/fengBlack/fengIp', 'IP封禁列表', null, '2019-08-17 13:19:46', '2019-08-17 13:19:46', null, 'fengblack.fengIp', '1', null);
COMMIT;

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`permission_id`  int(11) NULL DEFAULT NULL ,
`role_id`  int(11) NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=45

;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
BEGIN;
INSERT INTO `permission_role` VALUES ('8', '2019-08-16 23:44:35', '2019-08-16 23:44:35', '409', '5'), ('9', '2019-08-17 13:02:48', '2019-08-17 13:02:48', '409', '4'), ('10', '2019-08-17 13:02:48', '2019-08-17 13:02:48', '410', '4'), ('11', '2019-08-17 13:02:48', '2019-08-17 13:02:48', '411', '4'), ('12', '2019-08-17 13:02:48', '2019-08-17 13:02:48', '375', '4'), ('13', '2019-08-17 13:02:48', '2019-08-17 13:02:48', '376', '4'), ('14', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '377', '4'), ('15', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '378', '4'), ('16', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '395', '4'), ('17', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '396', '4'), ('18', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '397', '4'), ('19', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '398', '4'), ('20', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '405', '4'), ('21', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '399', '4'), ('22', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '400', '4'), ('23', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '401', '4'), ('24', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '402', '4'), ('25', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '403', '4'), ('26', '2019-08-17 13:02:49', '2019-08-17 13:02:49', '404', '4'), ('27', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '382', '4'), ('28', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '383', '4'), ('29', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '384', '4'), ('30', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '385', '4'), ('31', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '386', '4'), ('32', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '406', '4'), ('33', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '387', '4'), ('34', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '388', '4'), ('35', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '389', '4'), ('36', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '390', '4'), ('37', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '392', '4'), ('38', '2019-08-17 13:02:50', '2019-08-17 13:02:50', '393', '4'), ('39', '2019-08-17 13:02:51', '2019-08-17 13:02:51', '394', '4'), ('40', '2019-08-17 13:02:51', '2019-08-17 13:02:51', '407', '4'), ('41', '2019-08-17 13:02:51', '2019-08-17 13:02:51', '408', '4'), ('42', '2019-08-17 13:02:51', '2019-08-17 13:02:51', '413', '4'), ('43', '2019-08-17 13:02:51', '2019-08-17 13:02:51', '414', '4'), ('44', '2019-08-21 23:23:03', '2019-08-21 23:23:03', '415', '4');
COMMIT;

-- ----------------------------
-- Table structure for permission_user
-- ----------------------------
DROP TABLE IF EXISTS `permission_user`;
CREATE TABLE `permission_user` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`user_id`  int(11) NULL DEFAULT NULL ,
`permission_id`  int(11) NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=2

;

-- ----------------------------
-- Records of permission_user
-- ----------------------------
BEGIN;
INSERT INTO `permission_user` VALUES ('1', '3', '409', '2019-08-16 23:58:51', null);
COMMIT;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`slug`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`description`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`model`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`level`  int(10) NULL DEFAULT 0 ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=416

;

-- ----------------------------
-- Records of permissions
-- ----------------------------
BEGIN;
INSERT INTO `permissions` VALUES ('210', '玩家管理', 'account.index', '', 'account', '0', '2019-08-16 21:12:10', '2019-08-23 10:05:29'), ('211', '系统管理', 'index.index', null, 'index', '0', '2019-08-16 21:12:19', '2019-08-16 21:12:19'), ('212', '用户列表', 'users.index', null, 'users', '0', '2019-08-16 21:12:19', '2019-08-16 21:12:19'), ('213', '角色管理', 'roles.index', null, 'roles', '0', '2019-08-16 21:12:19', '2019-08-16 21:12:19'), ('214', '权限管理', 'permissions.index', null, 'permissions', '0', '2019-08-16 21:12:19', '2019-08-16 21:12:19'), ('215', '版本管理', 'version.view', null, 'version', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('216', '房间管理', 'client.gametax', null, 'client', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('217', '提现管理', 'cash.index', null, 'cash', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('218', '提现列表', 'cash.index', null, 'cash', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('219', '风控列表', 'cash.risk', null, 'cash', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('220', '风控比例', 'cash.risksystem', null, 'cash', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('221', '服务器列表', 'cash.servers', null, 'cash', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('222', '支付宝黑名单', 'cash.aliaccount', null, 'cash', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('223', '通知管理', 'notice.index', null, 'notice', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('224', '通知列表', 'notice.system', null, 'notice', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('225', '私信列表', 'notice.specify', null, 'notice', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('226', '短信列表', 'notice.sms', null, 'notice', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('227', '反馈管理', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:12:20', '2019-08-16 21:12:20'), ('228', '反馈列表', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('229', '快捷回复', 'feedback.quickreplytype', null, 'feedback', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('230', '玩家禁言', 'feedback.bansay', null, 'feedback', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('231', '添加版本', 'version.view', null, 'version', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('232', '框架版本', 'version.frame', null, 'version', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('233', '大厅版本', 'version.hall', null, 'version', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('234', '游戏版本', 'version.game', null, 'version', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('235', '客户端配置', 'client.index', null, 'client', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('236', '创建配置', 'client.viewconfig', null, 'client', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('237', '配置列表', 'client.listconfig', null, 'client', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('238', '模版列表', 'client.template', null, 'client', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('239', '创建模板', 'client.templatecreate', null, 'client', '0', '2019-08-16 21:12:21', '2019-08-16 21:12:21'), ('240', '导入模板', 'client.templateconfigcreate', null, 'client', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('241', '税收配置', 'client.gametax', null, 'client', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('242', '客服提现管理', 'cash.customer', null, 'cash', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('243', '充值列表', 'rechargeorder.index', null, 'rechargeorder', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('244', '渠道商管理', 'distribution.index', null, 'distribution', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('245', '玩家列表', 'account.index', null, 'account', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('246', '星级关注', 'account.riskstar', null, 'account', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('247', '登陆日志', 'account.loglogin', null, 'account', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('248', '游戏配置', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('249', '配置首页', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('250', 'IP封禁列表', 'fengblack.fengip', null, 'fengBlack', '0', '2019-08-16 21:12:22', '2019-08-16 21:12:22'), ('251', '玩家管理', 'account.index', null, 'account', '0', '2019-08-16 21:12:36', '2019-08-16 21:12:36'), ('252', '系统管理', 'index.index', null, 'index', '0', '2019-08-16 21:12:36', '2019-08-16 21:12:36'), ('253', '用户列表', 'users.index', null, 'users', '0', '2019-08-16 21:12:36', '2019-08-16 21:12:36'), ('254', '角色管理', 'roles.index', null, 'roles', '0', '2019-08-16 21:12:36', '2019-08-16 21:12:36'), ('255', '权限管理', 'permissions.index', null, 'permissions', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('256', '版本管理', 'version.view', null, 'version', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('257', '房间管理', 'client.gametax', null, 'client', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('258', '提现管理', 'cash.index', null, 'cash', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('259', '提现列表', 'cash.index', null, 'cash', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('260', '风控列表', 'cash.risk', null, 'cash', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('261', '风控比例', 'cash.risksystem', null, 'cash', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('262', '服务器列表', 'cash.servers', null, 'cash', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('263', '支付宝黑名单', 'cash.aliaccount', null, 'cash', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('264', '通知管理', 'notice.index', null, 'notice', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('265', '通知列表', 'notice.system', null, 'notice', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('266', '私信列表', 'notice.specify', null, 'notice', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('267', '短信列表', 'notice.sms', null, 'notice', '0', '2019-08-16 21:12:37', '2019-08-16 21:12:37'), ('268', '反馈管理', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('269', '反馈列表', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('270', '快捷回复', 'feedback.quickreplytype', null, 'feedback', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('271', '玩家禁言', 'feedback.bansay', null, 'feedback', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('272', '添加版本', 'version.view', null, 'version', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('273', '框架版本', 'version.frame', null, 'version', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('274', '大厅版本', 'version.hall', null, 'version', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('275', '游戏版本', 'version.game', null, 'version', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('276', '客户端配置', 'client.index', null, 'client', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('277', '创建配置', 'client.viewconfig', null, 'client', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('278', '配置列表', 'client.listconfig', null, 'client', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('279', '模版列表', 'client.template', null, 'client', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('280', '创建模板', 'client.templatecreate', null, 'client', '0', '2019-08-16 21:12:38', '2019-08-16 21:12:38'), ('281', '导入模板', 'client.templateconfigcreate', null, 'client', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('282', '税收配置', 'client.gametax', null, 'client', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('283', '客服提现管理', 'cash.customer', null, 'cash', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('284', '充值列表', 'rechargeorder.index', null, 'rechargeorder', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('285', '渠道商管理', 'distribution.index', null, 'distribution', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('286', '玩家列表', 'account.index', null, 'account', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('287', '星级关注', 'account.riskstar', null, 'account', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('288', '登陆日志', 'account.loglogin', null, 'account', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('289', '游戏配置', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('290', '配置首页', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('291', 'IP封禁列表', 'fengblack.fengip', null, 'fengBlack', '0', '2019-08-16 21:12:39', '2019-08-16 21:12:39'), ('292', '玩家管理', 'account.index', null, 'account', '0', '2019-08-16 21:13:16', '2019-08-16 21:13:16'), ('293', '系统管理', 'index.index', null, 'index', '0', '2019-08-16 21:13:16', '2019-08-16 21:13:16'), ('294', '用户列表', 'users.index', null, 'users', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('295', '角色管理', 'roles.index', null, 'roles', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('296', '权限管理', 'permissions.index', null, 'permissions', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('297', '版本管理', 'version.view', null, 'version', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('298', '房间管理', 'client.gametax', null, 'client', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('299', '提现管理', 'cash.index', null, 'cash', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('300', '提现列表', 'cash.index', null, 'cash', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('301', '风控列表', 'cash.risk', null, 'cash', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('302', '风控比例', 'cash.risksystem', null, 'cash', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('303', '服务器列表', 'cash.servers', null, 'cash', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('304', '支付宝黑名单', 'cash.aliaccount', null, 'cash', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('305', '通知管理', 'notice.index', null, 'notice', '0', '2019-08-16 21:13:17', '2019-08-16 21:13:17'), ('306', '通知列表', 'notice.system', null, 'notice', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('307', '私信列表', 'notice.specify', null, 'notice', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('308', '短信列表', 'notice.sms', null, 'notice', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('309', '反馈管理', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES ('310', '反馈列表', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('311', '快捷回复', 'feedback.quickreplytype', null, 'feedback', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('312', '玩家禁言', 'feedback.bansay', null, 'feedback', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('313', '添加版本', 'version.view', null, 'version', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('314', '框架版本', 'version.frame', null, 'version', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('315', '大厅版本', 'version.hall', null, 'version', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('316', '游戏版本', 'version.game', null, 'version', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('317', '客户端配置', 'client.index', null, 'client', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('318', '创建配置', 'client.viewconfig', null, 'client', '0', '2019-08-16 21:13:18', '2019-08-16 21:13:18'), ('319', '配置列表', 'client.listconfig', null, 'client', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('320', '模版列表', 'client.template', null, 'client', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('321', '创建模板', 'client.templatecreate', null, 'client', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('322', '导入模板', 'client.templateconfigcreate', null, 'client', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('323', '税收配置', 'client.gametax', null, 'client', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('324', '客服提现管理', 'cash.customer', null, 'cash', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('325', '充值列表', 'rechargeorder.index', null, 'rechargeorder', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('326', '渠道商管理', 'distribution.index', null, 'distribution', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('327', '玩家列表', 'account.index', null, 'account', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('328', '星级关注', 'account.riskstar', null, 'account', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('329', '登陆日志', 'account.loglogin', null, 'account', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('330', '游戏配置', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:13:19', '2019-08-16 21:13:19'), ('331', '配置首页', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:13:20', '2019-08-16 21:13:20'), ('332', 'IP封禁列表', 'fengblack.fengip', null, 'fengBlack', '0', '2019-08-16 21:13:20', '2019-08-16 21:13:20'), ('333', '玩家管理', 'account.index', null, 'account', '0', '2019-08-16 21:13:26', '2019-08-16 21:13:26'), ('334', '系统管理', 'index.index', null, 'index', '0', '2019-08-16 21:13:26', '2019-08-16 21:13:26'), ('335', '用户列表', 'users.index', null, 'users', '0', '2019-08-16 21:13:26', '2019-08-16 21:13:26'), ('336', '角色管理', 'roles.index', null, 'roles', '0', '2019-08-16 21:13:26', '2019-08-16 21:13:26'), ('337', '权限管理', 'permissions.index', null, 'permissions', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('338', '版本管理', 'version.view', null, 'version', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('339', '房间管理', 'client.gametax', null, 'client', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('340', '提现管理', 'cash.index', null, 'cash', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('341', '提现列表', 'cash.index', null, 'cash', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('342', '风控列表', 'cash.risk', null, 'cash', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('343', '风控比例', 'cash.risksystem', null, 'cash', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('344', '服务器列表', 'cash.servers', null, 'cash', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('345', '支付宝黑名单', 'cash.aliaccount', null, 'cash', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('346', '通知管理', 'notice.index', null, 'notice', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('347', '通知列表', 'notice.system', null, 'notice', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('348', '私信列表', 'notice.specify', null, 'notice', '0', '2019-08-16 21:13:27', '2019-08-16 21:13:27'), ('349', '短信列表', 'notice.sms', null, 'notice', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('350', '反馈管理', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('351', '反馈列表', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('352', '快捷回复', 'feedback.quickreplytype', null, 'feedback', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('353', '玩家禁言', 'feedback.bansay', null, 'feedback', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('354', '添加版本', 'version.view', null, 'version', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('355', '框架版本', 'version.frame', null, 'version', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('356', '大厅版本', 'version.hall', null, 'version', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('357', '游戏版本', 'version.game', null, 'version', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('358', '客户端配置', 'client.index', null, 'client', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('359', '创建配置', 'client.viewconfig', null, 'client', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('360', '配置列表', 'client.listconfig', null, 'client', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('361', '模版列表', 'client.template', null, 'client', '0', '2019-08-16 21:13:28', '2019-08-16 21:13:28'), ('362', '创建模板', 'client.templatecreate', null, 'client', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('363', '导入模板', 'client.templateconfigcreate', null, 'client', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('364', '税收配置', 'client.gametax', null, 'client', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('365', '客服提现管理', 'cash.customer', null, 'cash', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('366', '充值列表', 'rechargeorder.index', null, 'rechargeorder', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('367', '渠道商管理', 'distribution.index', null, 'distribution', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('368', '玩家列表', 'account.index', null, 'account', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('369', '星级关注', 'account.riskstar', null, 'account', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('370', '登陆日志', 'account.loglogin', null, 'account', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('371', '游戏配置', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('372', '配置首页', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('373', 'IP封禁列表', 'fengblack.fengip', null, 'fengBlack', '0', '2019-08-16 21:13:29', '2019-08-16 21:13:29'), ('374', '玩家管理', 'account.index', null, 'account', '0', '2019-08-16 21:14:15', '2019-08-16 21:14:15'), ('375', '系统管理', 'index.index', null, 'index', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('376', '用户列表', 'users.index', null, 'users', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('377', '角色管理', 'roles.index', null, 'roles', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('378', '权限管理', 'permissions.index', null, 'permissions', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('379', '版本管理', 'version.view', null, 'version', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('380', '房间管理', 'client.gametax', null, 'client', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('381', '提现管理', 'cash.index', null, 'cash', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('382', '提现列表', 'cash.index', null, 'cash', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('383', '风控列表', 'cash.risk', null, 'cash', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('384', '风控比例', 'cash.risksystem', null, 'cash', '0', '2019-08-16 21:14:16', '2019-08-16 21:14:16'), ('385', '服务器列表', 'cash.servers', null, 'cash', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('386', '支付宝黑名单', 'cash.aliaccount', null, 'cash', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('387', '通知管理', 'notice.index', null, 'notice', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('388', '通知列表', 'notice.system', null, 'notice', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('389', '私信列表', 'notice.specify', null, 'notice', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('390', '短信列表', 'notice.sms', null, 'notice', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('391', '反馈管理', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('392', '反馈列表', 'feedback.index', null, 'feedback', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('393', '快捷回复', 'feedback.quickreplytype', null, 'feedback', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('394', '玩家禁言', 'feedback.bansay', null, 'feedback', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('395', '添加版本', 'version.view', null, 'version', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('396', '框架版本', 'version.frame', null, 'version', '0', '2019-08-16 21:14:17', '2019-08-16 21:14:17'), ('397', '大厅版本', 'version.hall', null, 'version', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('398', '游戏版本', 'version.game', null, 'version', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('399', '客户端配置', 'client.index', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('400', '创建配置', 'client.viewconfig', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('401', '配置列表', 'client.listconfig', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('402', '模版列表', 'client.template', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('403', '创建模板', 'client.templatecreate', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('404', '导入模板', 'client.templateconfigcreate', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('405', '税收配置', 'client.gametax', null, 'client', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('406', '客服提现管理', 'cash.customer', null, 'cash', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('407', '充值列表', 'rechargeorder.index', null, 'rechargeorder', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('408', '渠道商管理', 'distribution.index', null, 'distribution', '0', '2019-08-16 21:14:18', '2019-08-16 21:14:18'), ('409', '玩家列表', 'account.index', null, 'account', '0', '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES ('410', '星级关注', 'account.riskstar', null, 'account', '0', '2019-08-16 21:14:19', '2019-08-16 21:14:19'), ('411', '登陆日志', 'account.loglogin', null, 'account', '0', '2019-08-16 21:14:19', '2019-08-16 21:14:19'), ('412', '游戏配置', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:14:19', '2019-08-16 21:14:19'), ('413', '配置首页', 'gameconfig.index', null, 'gameConfig', '0', '2019-08-16 21:14:19', '2019-08-16 21:14:19'), ('414', 'IP封禁列表', 'fengblack.fengip', null, 'fengBlack', '0', '2019-08-16 21:14:19', '2019-08-16 21:14:19'), ('415', '牌局记录', 'record.board', '查看牌局记录', 'record', '0', '2019-08-21 23:21:51', '2019-08-22 00:16:10');
COMMIT;

-- ----------------------------
-- Table structure for plant_statistics
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics`;
CREATE TABLE `plant_statistics` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`order_sum`  int(11) NULL DEFAULT NULL ,
`order_count`  int(11) NULL DEFAULT NULL ,
`order_fail_sum`  int(11) NULL DEFAULT NULL ,
`order_fail_count`  int(11) NULL DEFAULT NULL ,
`order_success_sum`  int(11) NULL DEFAULT NULL ,
`order_success_user`  int(11) NULL DEFAULT NULL ,
`order_success_count`  int(11) NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of plant_statistics
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for plant_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics_detail`;
CREATE TABLE `plant_statistics_detail` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`order_sum`  int(11) NULL DEFAULT NULL ,
`order_count`  int(11) NULL DEFAULT NULL ,
`order_fail_sum`  int(11) NULL DEFAULT NULL ,
`order_fail_count`  int(11) NULL DEFAULT NULL ,
`order_success_sum`  int(11) NULL DEFAULT NULL ,
`order_success_user`  int(11) NULL DEFAULT NULL ,
`order_success_count`  int(11) NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of plant_statistics_detail
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for promoter_own_ips
-- ----------------------------
DROP TABLE IF EXISTS `promoter_own_ips`;
CREATE TABLE `promoter_own_ips` (
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID' ,
`ip`  char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'ip(如果在该表有查不到的IP，那么推广员ID为0，即默认推广员)' ,
`promoter_id`  int(11) NOT NULL COMMENT '推广员ID(也是guid)' ,
`uptime`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' ,
PRIMARY KEY (`bag_id`, `ip`),
INDEX `idx_ip_bag_id` (`ip`, `bag_id`) USING BTREE ,
INDEX `idx_promoter_id` (`promoter_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of promoter_own_ips
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for quick_reply_type
-- ----------------------------
DROP TABLE IF EXISTS `quick_reply_type`;
CREATE TABLE `quick_reply_type` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`status`  int(11) NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
`name`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=6

;

-- ----------------------------
-- Records of quick_reply_type
-- ----------------------------
BEGIN;
INSERT INTO `quick_reply_type` VALUES ('5', '1', null, null, '测试');
COMMIT;

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`user_id`  int(11) NULL DEFAULT NULL ,
`role_id`  int(11) NULL DEFAULT NULL ,
`created_at`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`updated_at`  datetime NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=5

;

-- ----------------------------
-- Records of role_user
-- ----------------------------
BEGIN;
INSERT INTO `role_user` VALUES ('2', '1', '4', '2019-08-16 21:17:16', null), ('3', '2', '5', '2019-08-16 22:02:43', '2019-08-17 16:15:26'), ('4', '3', '5', '2019-08-16 23:58:51', null);
COMMIT;

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
`id`  int(11) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`slug`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`description`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`level`  int(255) NULL DEFAULT NULL COMMENT '0' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=6

;

-- ----------------------------
-- Records of roles
-- ----------------------------
BEGIN;
INSERT INTO `roles` VALUES ('00000000004', 'admin', 'admin', '测试', '0', '2019-08-16 21:14:13', '2019-08-21 23:23:03'), ('00000000005', 'admin1', 'admin1', 'admin1', '0', '2019-08-16 23:44:34', '2019-08-17 00:00:38');
COMMIT;

-- ----------------------------
-- Table structure for sms
-- ----------------------------
DROP TABLE IF EXISTS `sms`;
CREATE TABLE `sms` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`phone`  varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '发送手机号' ,
`content`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '发送内容' ,
`status`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '状态' ,
`return`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '返回值' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=26

;

-- ----------------------------
-- Records of sms
-- ----------------------------
BEGIN;
INSERT INTO `sms` VALUES ('10', '18728483303', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:88.2/sid:0824222328639185', '2019-08-24 22:23:28', '2019-08-24 22:23:28'), ('11', '15328200638', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:88.1/sid:0824223035782227', '2019-08-24 22:30:35', '2019-08-24 22:30:35'), ('12', '18808165675', '您正在将账户绑定此手机，验证码500334。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:88/sid:0824223214325105', '2019-08-24 22:32:14', '2019-08-24 22:32:14'), ('13', '18808165675', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.9/sid:0824223647905783', '2019-08-24 22:36:48', '2019-08-24 22:36:48'), ('14', '15328200638', '您正在将账户绑定此手机，验证码358478。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.8/sid:0824223653376493', '2019-08-24 22:36:53', '2019-08-24 22:36:53'), ('15', '13733414639', '您正在将账户绑定此手机，验证码464962。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.7/sid:0824223844264544', '2019-08-24 22:38:44', '2019-08-24 22:38:44'), ('16', '16606911141', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.6/sid:0825095742682193', '2019-08-25 09:57:42', '2019-08-25 09:57:42'), ('17', '18583968687', '您正在将账户绑定此手机，验证码500334。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.5/sid:0825104325984363', '2019-08-25 10:43:26', '2019-08-25 10:43:26'), ('18', '18808165675', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.3/sid:0825141841964238', '2019-08-25 14:18:42', '2019-08-25 14:18:42'), ('19', '16606911142', '您正在将账户绑定此手机，验证码358478。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.2/sid:0825144143519146', '2019-08-25 14:41:43', '2019-08-25 14:41:43'), ('20', '15328200638', '您正在将账户绑定此手机，验证码464962。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.1/sid:0825144711449757', '2019-08-25 14:47:11', '2019-08-25 14:47:11'), ('21', '18728483303', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87/sid:0825145031584582', '2019-08-25 14:50:31', '2019-08-25 14:50:31'), ('22', '15608008806', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.9/sid:0825155649355426', '2019-08-25 15:56:49', '2019-08-25 15:56:49'), ('23', '18728483303', '您正在将账户绑定此手机，验证码500334。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.8/sid:0825155851855526', '2019-08-25 15:58:51', '2019-08-25 15:58:51'), ('24', '16606911142', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.7/sid:0825172318142773', '2019-08-25 17:23:18', '2019-08-25 17:23:18'), ('25', '16606911142', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.6/sid:0825174306293789', '2019-08-25 17:43:06', '2019-08-25 17:43:06');
COMMIT;

-- ----------------------------
-- Table structure for t_account
-- ----------------------------
DROP TABLE IF EXISTS `t_account`;
CREATE TABLE `t_account` (
`guid`  int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符' ,
`account`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '账号' ,
`password`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '密码' ,
`is_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '是否是游客 1是游客' ,
`nickname`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '昵称' ,
`enable_transfer`  int(11) NOT NULL DEFAULT 0 COMMENT '1能够转账，0不能给其他玩家转账' ,
`bank_password`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '银行密码' ,
`vip`  int(11) NOT NULL DEFAULT 0 COMMENT 'vip等级' ,
`alipay_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加了星号的支付宝姓名' ,
`alipay_name_y`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付宝姓名' ,
`alipay_account`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加了星号的支付宝账号' ,
`alipay_account_y`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付宝账号' ,
`bang_alipay_time`  timestamp NULL DEFAULT NULL COMMENT '支付宝绑时间' ,
`create_time`  timestamp NULL DEFAULT NULL COMMENT '创建时间' ,
`register_time`  timestamp NULL DEFAULT NULL COMMENT '注册时间' ,
`login_time`  timestamp NULL DEFAULT NULL COMMENT '登陆时间' ,
`logout_time`  timestamp NULL DEFAULT NULL COMMENT '退出时间' ,
`online_time`  int(11) NULL DEFAULT 0 COMMENT '累计在线时间' ,
`login_count`  int(11) NULL DEFAULT 1 COMMENT '登录次数' ,
`phone`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '手机名字：ios，android' ,
`phone_type`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '手机具体型号' ,
`version`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '版本号' ,
`channel_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号' ,
`package_name`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '安装包名字' ,
`imei`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '设备唯一码' ,
`ip`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '客户端ip' ,
`last_login_phone`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录手机名字：ios，android' ,
`last_login_phone_type`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录手机具体型号' ,
`last_login_version`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录版本号' ,
`last_login_channel_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录渠道号' ,
`last_login_package_name`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录安装包名字' ,
`last_login_imei`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录设备唯一码' ,
`last_login_ip`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录IP' ,
`change_alipay_num`  int(11) NULL DEFAULT 6 COMMENT '允许修改支付宝账号次数' ,
`disabled`  tinyint(4) NULL DEFAULT 0 COMMENT '0启用  1禁用' ,
`risk`  tinyint(4) NULL DEFAULT 0 COMMENT '危险等级0-9  9最危险' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '总充值金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '总提现金额' ,
`inviter_guid`  int(11) NULL DEFAULT 0 COMMENT '邀请人的id' ,
`invite_code`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '邀请码' ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id' ,
`proxy_money`  bigint(20) NULL DEFAULT 0 COMMENT '代理充值累计金额' ,
`bank_card_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '**' COMMENT '银行卡姓名' ,
`bank_card_num`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '**' COMMENT '银行卡号' ,
`change_bankcard_num`  int(11) NULL DEFAULT 6 COMMENT '允许修改银行卡号次数' ,
`which_bank`  int(11) NULL DEFAULT 0 COMMENT '所属银行' ,
`band_bankcard_time`  timestamp NULL DEFAULT NULL COMMENT '银行卡绑定时间' ,
`seniorpromoter`  int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid' ,
`type`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '默认值：0,1:线上推广员,2:线下推广员' ,
`level`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '默认值:0,待激活:99,1-5一到五级推广员' ,
`promoter_time`  timestamp NULL DEFAULT NULL COMMENT '成为推广员时间' ,
`shared_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '共享设备码' ,
PRIMARY KEY (`guid`),
UNIQUE INDEX `index_nickname` (`nickname`) USING BTREE ,
UNIQUE INDEX `index_imei` (`imei`, `platform_id`) USING BTREE ,
UNIQUE INDEX `index_account` (`account`, `platform_id`) USING BTREE ,
INDEX `index_invite_code` (`invite_code`) USING BTREE ,
INDEX `index_bang_alipay_time` (`bang_alipay_time`) USING BTREE ,
INDEX `index_create_time` (`create_time`) USING BTREE ,
INDEX `index_login_time` (`login_time`) USING BTREE ,
INDEX `index_register_time` (`register_time`) USING BTREE ,
INDEX `index_alipay_account_y` (`alipay_account_y`) USING BTREE ,
INDEX `index_ip_register_time` (`ip`, `register_time`) USING BTREE ,
INDEX `index_login_ip_time` (`last_login_ip`, `login_time`) USING BTREE ,
INDEX `index_bank_card_num` (`bank_card_num`) USING BTREE ,
INDEX `index_type_level` (`type`, `level`) USING BTREE ,
INDEX `index_seniorpromoter` (`seniorpromoter`, `guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='账号表'
AUTO_INCREMENT=83

;

-- ----------------------------
-- Records of t_account
-- ----------------------------
BEGIN;
INSERT INTO `t_account` VALUES ('44', 'guest_44', '68a01f9e9093b777788fb66159e66ef2', '1', 'guest_44', '0', null, '0', null, null, '', null, null, '2019-08-20 13:48:16', null, '2019-08-24 15:48:54', '2019-08-24 16:36:26', '7580', '29', 'android', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', 'IMEI Test', '222.209.11.89', 'android', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', 'IMEI Test', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2724', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('45', 'guest_45', '3b07df0ad139ee1168a6246a25592d0d', '1', 'guest_45', '0', null, '0', null, null, '', null, null, '2019-08-20 13:49:08', null, '2019-08-20 13:49:08', null, '0', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01813234553', '222.209.11.89', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01813234553', '222.209.11.89', '6', '0', '0', '0', '0', '0', '2725', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('46', 'guest_46', '54a8316c41b00b55d307cfe5aa65ea93', '1', 'guest_46', '0', null, '0', null, null, '', null, null, '2019-08-20 15:41:32', null, '2019-08-20 15:56:15', '2019-08-20 15:56:18', '115', '4', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01763515589', '222.209.11.89', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011255020687', '222.209.10.50', '6', '0', '0', '0', '0', '0', '2731', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('47', 'guest_47', '2bdf35a9e792e96c0a75ee70def78d4e', '1', 'guest_47', '0', null, '0', null, null, '', null, null, '2019-08-20 15:56:34', null, '2019-08-20 15:56:34', '2019-08-20 15:57:06', '32', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01867617863', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01867617863', '222.209.10.50', '6', '0', '0', '0', '0', '0', '2732', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('48', 'guest_48', 'ac559451343fbf224460637c8494e46c', '1', 'guest_48', '0', null, '0', null, null, '', null, null, '2019-08-20 16:02:20', null, '2019-08-20 16:08:54', '2019-08-20 16:09:18', '161', '5', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:0154112980', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01538634853', '222.209.10.50', '6', '0', '0', '0', '0', '0', '2733', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('49', 'guest_49', '5e8591f284f88f45175171b89923daa5', '1', 'guest_49', '0', 'e3ceb5881a0a1fdaad01296d7554868d', '0', null, null, '', null, null, '2019-08-21 12:03:48', null, '2019-08-21 20:16:24', '2019-08-21 19:47:38', '8644', '21', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01768043093', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01694758618', '222.209.10.50', '6', '0', '0', '0', '0', '0', '2734', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('50', 'guest_50', 'ed3e6c33b4a59b90d3311c147058eb5f', '1', 'guest_50', '0', '96e79218965eb72c92a549dd5a330112', '0', null, null, '', null, null, '2019-08-21 14:09:18', null, '2019-08-24 17:14:01', '2019-08-24 17:15:57', '36180', '43', 'android', 'OPPO R9t', '1.0.0', 'test', 'org.cocos2dx.new_client', 'e5a5dc9c-e8b6-42a8-9dee-8c4aff13d1801566367757235', '125.69.45.197', 'android', 'OPPO R9t', '1.0.0', 'test', 'org.cocos2dx.new_client', 'e5a5dc9c-e8b6-42a8-9dee-8c4aff13d1801566367757235', '125.69.45.79', '6', '0', '0', '0', '0', '0', '2735', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '2879a1aee0ac17a3050976c3c236022f'), ('51', 'guest_51', '45dad9d6ef7debff94b4eae2d05d99b8', '1', 'guest_51', '0', 'e3ceb5881a0a1fdaad01296d7554868d', '0', null, null, '', null, null, '2019-08-21 14:42:23', null, '2019-08-22 17:46:03', '2019-08-22 16:53:37', '9136', '35', 'android', 'PAFM00', '1.0.0', 'test', 'org.cocos2dx.new_client', '7d553dc3-3a8b-4be9-822e-9823621019e41566369741639', '119.4.252.226', 'android', 'PAFM00', '1.0.0', 'test', 'org.cocos2dx.new_client', '7d553dc3-3a8b-4be9-822e-9823621019e41566369741639', '222.209.10.50', '6', '1', '5', '0', '0', '0', '2739', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '1ea2ac0b18d574665904a1e0725f6b7f'), ('52', 'guest_52', 'e33a24118271af35d60659fdcd27ea8e', '1', 'guest_52', '0', null, '0', null, null, '', null, null, '2019-08-21 14:47:53', null, '2019-08-24 10:26:13', '2019-08-24 10:26:23', '8440', '35', 'android', 'a1601', '1.0.0', 'test', 'org.cocos2dx.new_client', '4f336f50-ba8d-4b01-a0d3-e9cb952bd7981566370072602', '125.69.45.197', 'android', 'a1601', '1.0.0', 'test', 'org.cocos2dx.new_client', '4f336f50-ba8d-4b01-a0d3-e9cb952bd7981566370072602', '125.69.45.79', '6', '0', '0', '0', '0', '0', '273A', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '6d3928759f9e56594817223c41ffadd4'), ('53', '15328200638', 'e10adc3949ba59abbe56e057f20f883e', '0', 'guest_53', '0', null, '0', '李**', '李经理', '153****8639', '15328288639', '2019-08-24 22:40:17', '2019-08-21 14:47:58', '2019-08-24 22:31:08', '2019-08-25 14:00:24', '2019-08-25 14:02:29', '6870', '44', 'android', 'PAR-AL00', '1.0.0', 'test', 'org.cocos2dx.new_client', '9dd79f46-cb4c-4a93-9289-fdde9cdf35ae1566370077358', '125.69.45.197', 'android', 'PAR-AL00', '1.0.0', 'test', 'org.cocos2dx.new_client', '9dd79f46-cb4c-4a93-9289-fdde9cdf35ae1566370077358', '125.69.45.79', '4', '0', '0', '0', '0', '0', '273B', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '2af019cb84c317db2fa2ba80a4dcc977'), ('54', '16606911142', 'e10adc3949ba59abbe56e057f20f883e', '0', 'guest_54', '0', 'e10adc3949ba59abbe56e057f20f883e', '0', '', '', '', '', '2019-08-22 14:00:13', '2019-08-21 15:28:45', '2019-08-25 14:42:14', '2019-08-25 17:03:29', '2019-08-25 16:31:25', '169828', '33', 'android', 'oppo r9tm', '1.0.0', 'test', 'org.cocos2dx.new_client', '54a9c3bb-b3ae-4414-ae9d-15bad08c310d1566372524674', '222.209.10.50', 'android', 'oppo r9tm', '1.0.0', 'test', 'org.cocos2dx.new_client', '54a9c3bb-b3ae-4414-ae9d-15bad08c310d1566372524674', '125.69.44.152', '5', '0', '0', '0', '0', '0', '273C', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, 'f10a61bf57b1cf3ec27e5745226987a3'), ('55', 'guest_55', 'b28e384a1eb6deab1da2c57538c645b6', '1', 'guest_55', '0', null, '0', null, null, '', null, null, '2019-08-21 18:08:10', null, '2019-08-22 10:40:27', '2019-08-22 10:39:13', '50245', '5', 'android', 'a37f', '1.0.0', 'test', 'org.cocos2dx.new_client', 'a0138116-f206-4b67-9c94-8357de548b451566382089371', '222.209.10.50', 'android', 'a37f', '1.0.0', 'test', 'org.cocos2dx.new_client', 'a0138116-f206-4b67-9c94-8357de548b451566382089371', '222.209.10.50', '6', '0', '0', '0', '0', '0', '273D', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '4e7f80b2f9ef2be2b147f0e6873e17ec'), ('56', 'guest_56', '18f4ed443c667b8630d2fa7d6116079b', '1', 'guest_56', '0', null, '0', null, null, '', null, null, '2019-08-21 19:47:07', null, '2019-08-21 19:47:11', '2019-08-21 19:47:22', '11', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01799648823', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01799648823', '222.209.10.50', '6', '0', '0', '0', '0', '0', '273E', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('57', 'guest_57', '63e910a3f6c9ab36a3a60aae670c419d', '1', 'guest_57', '0', null, '0', null, null, '', null, null, '2019-08-21 20:17:03', null, '2019-08-21 21:26:14', '2019-08-21 21:26:20', '511', '3', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01577237979', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01791368964', '222.209.10.50', '6', '0', '0', '0', '0', '0', '273F', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('58', 'guest_58', 'fcf7f3ff3cb4f2db81f4eb7dba93ba6a', '1', 'guest_58', '0', null, '0', null, null, '', null, null, '2019-08-21 21:28:47', null, '2019-08-21 21:28:51', '2019-08-21 21:31:15', '144', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011076846879', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011076846879', '222.209.10.50', '6', '0', '0', '0', '0', '0', '2740', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('59', 'guest_59', '8009ac309b5cecb6e6e15761be159f81', '1', 'guest_59', '0', null, '0', '', '', '', '13733414639', '2019-08-23 21:59:44', '2019-08-21 21:33:06', null, '2019-08-23 21:58:43', '2019-08-23 21:59:52', '3773', '46', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:0187929339', '222.209.10.50', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01322460986', '125.69.44.152', '5', '0', '0', '0', '0', '0', '2741', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('60', 'guest_60', '0958ff030e70fdae13480a068bdb2405', '1', 'guest_60', '0', null, '0', null, null, '', null, null, '2019-08-22 10:01:07', null, '2019-08-22 10:03:37', '2019-08-22 10:03:42', '11', '2', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:15:5D:6B:27:1F1030686953', '182.149.167.79', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:15:5D:6B:27:1F1215090347', '182.149.167.79', '6', '0', '0', '0', '0', '0', '2742', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('61', 'guest_61', '625617e7cd585b0205850c9c89fdf43b', '1', 'guest_61', '0', null, '0', null, null, '', null, null, '2019-08-22 15:43:38', null, '2019-08-24 10:18:01', '2019-08-22 15:46:06', '148', '5', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:15:5D:6B:27:1F907022412', '182.149.167.79', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '08:1F:71:1C:2C:84753667896', '182.149.167.79', '6', '0', '0', '0', '0', '0', '2743', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('62', 'guest_62', 'df2b2fbbcda0e8dc17e39ba7d7c6c0f3', '1', 'guest_62', '0', null, '0', null, null, '', null, null, '2019-08-23 21:46:00', null, '2019-08-23 21:58:56', '2019-08-23 22:04:58', '490', '3', 'android', 'COR-AL10', '1.0.0', 'test', 'org.cocos2dx.new_client', '6e9be27b-2216-4fb4-a03d-f2e94bdef0fc1566565472437', '125.69.44.152', 'android', 'COR-AL10', '1.0.0', 'test', 'org.cocos2dx.new_client', '6e9be27b-2216-4fb4-a03d-f2e94bdef0fc1566565472437', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2744', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, 'eb280da0dbfb3a46386c5876ec9f79c5'), ('63', 'guest_63', '9ae3daa6597a52bb19ce1a97cc1c4ea1', '1', 'guest_63', '0', null, '0', null, null, '', null, null, '2019-08-23 22:03:37', null, '2019-08-24 10:07:32', '2019-08-23 22:17:23', '550', '9', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01831582050', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011552818698', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2745', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('64', 'guest_64', 'eba0bd36d9c363953e952dabc67513ca', '1', 'lkdsajoifdjsa', '0', null, '0', null, null, '', null, null, '2019-08-23 23:23:03', null, '2019-08-23 23:32:36', '2019-08-23 23:39:57', '1005', '2', 'android', 'LDN-AL00', '1.0.0', 'test', 'org.cocos2dx.new_client', '5194c9f4-bbeb-4be1-834a-940be35ee29f1566573781777', '120.29.100.210', 'android', 'LDN-AL00', '1.0.0', 'test', 'org.cocos2dx.new_client', '5194c9f4-bbeb-4be1-834a-940be35ee29f1566573781777', '120.29.100.210', '6', '0', '0', '0', '0', '0', '2746', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, 'eac9e67992df36140b788891c6cc8ab8'), ('65', 'guest_65', '235f24787238c35287e5ebf6474a52ef', '1', 'guest_65', '0', 'e10adc3949ba59abbe56e057f20f883e', '0', '', '', '', '13183898767', '2019-08-25 09:59:36', '2019-08-24 09:23:43', null, '2019-08-25 17:04:05', '2019-08-25 16:58:47', '20887', '23', 'android', 'm1 metal', '1.0.0', 'test', 'org.cocos2dx.new_client', 'f64520f7-b59c-4c59-8c7a-04f576b0af161566442037782', '125.69.44.152', 'android', 'm1 metal', '1.0.0', 'test', 'org.cocos2dx.new_client', 'f64520f7-b59c-4c59-8c7a-04f576b0af161566442037782', '125.69.44.152', '5', '0', '0', '0', '0', '0', '2747', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '466d7718b9bb7b3936a4edcd6dc0a819'), ('66', '18808165675', 'e10adc3949ba59abbe56e057f20f883e', '0', 'guest_66', '0', 'e10adc3949ba59abbe56e057f20f883e', '0', null, null, '', null, null, '2019-08-24 09:32:25', '2019-08-24 22:32:56', '2019-08-25 14:59:48', '2019-08-25 14:28:45', '18289', '38', 'android', 'xiaomi 6', '1.0.0', 'test', 'org.cocos2dx.new_client', '9930ca72-1966-4ea7-85b5-7830095cb4851566610344381', '125.69.44.152', 'android', 'xiaomi 6', '1.0.0', 'test', 'org.cocos2dx.new_client', '9930ca72-1966-4ea7-85b5-7830095cb4851566610344381', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2748', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '5d05fcd15ed09f1a476aa9de4510fb66'), ('67', 'guest_67', '3bd6e7ad317667cd0ecff48529099309', '1', 'guest_67', '0', null, '0', null, null, '', null, null, '2019-08-24 10:20:46', null, '2019-08-24 11:01:08', '2019-08-24 11:17:56', '1632', '10', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01724509373', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011431247774', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2749', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('68', 'guest_68', 'd117f9f615e1da27eabdde36094d4afd', '1', 'guest_68', '0', null, '0', null, null, '', null, null, '2019-08-24 11:17:48', null, '2019-08-24 11:30:51', '2019-08-24 11:30:54', '70', '4', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01796672321', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011539748305', '125.69.44.152', '6', '0', '0', '0', '0', '0', '274A', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('69', 'guest_69', '5634f95f96e461fd727cafae8b2dbd26', '1', 'guest_69', '0', null, '0', null, null, '', null, null, '2019-08-24 11:31:15', null, '2019-08-24 11:31:17', '2019-08-24 11:31:35', '18', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011511361746', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:011511361746', '125.69.44.152', '6', '0', '0', '0', '0', '0', '274B', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('70', 'guest_70', '2d0731cbb08d343138f36cf5b7f5d173', '1', 'guest_70', '0', null, '0', null, null, '', null, null, '2019-08-24 11:32:32', null, '2019-08-24 11:32:32', '2019-08-24 11:32:36', '4', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01440286055', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01440286055', '125.69.44.152', '6', '0', '0', '0', '0', '0', '274C', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('71', 'guest_71', 'db18a3112045a555f839af6b2866a87e', '1', 'guest_71', '0', 'e10adc3949ba59abbe56e057f20f883e', '0', null, null, '', null, null, '2019-08-24 11:32:43', null, '2019-08-24 11:35:52', '2019-08-24 11:37:19', '244', '2', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:0161624228', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01287879714', '125.69.44.152', '6', '0', '0', '0', '0', '0', '274D', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('72', 'guest_72', '128d4a67e3b46cdab3e5416f25cef74e', '1', 'guest_72', '0', null, '0', null, null, '', null, null, '2019-08-24 11:36:08', null, '2019-08-24 16:32:30', '2019-08-24 16:37:32', '7797', '15', 'android', 'SM-G8870', '1.0.0', 'test', 'org.cocos2dx.new_client', '1644e7f6-9309-44a2-b6b0-81590a49c3fc1566617767037', '125.69.44.152', 'android', 'SM-G8870', '1.0.0', 'test', 'org.cocos2dx.new_client', '1644e7f6-9309-44a2-b6b0-81590a49c3fc1566617767037', '101.206.167.118', '6', '0', '0', '0', '0', '0', '274E', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '967f13b124ec19cb0c6b88794c6675ca'), ('73', 'guest_73', '49c2bfe8eab3de324a81bd7d03e48526', '1', '吃了个鸡', '0', null, '0', null, null, '', null, null, '2019-08-24 11:37:22', null, '2019-08-24 11:37:24', '2019-08-24 11:38:49', '85', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:0188364782', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:0188364782', '125.69.44.152', '6', '0', '0', '0', '0', '0', '274F', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('74', '13733414639', 'e10adc3949ba59abbe56e057f20f883e', '0', 'guest_74', '0', '21218cca77804d2ba1922c33e0151105', '0', null, null, '', null, null, '2019-08-24 11:43:48', '2019-08-24 22:39:07', '2019-08-25 17:35:44', '2019-08-25 17:35:42', '43893', '51', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:01936327214', '125.69.44.152', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:50:56:C0:00:0115136688', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2750', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('75', 'guest_75', '296734510f39ba53c406f3c53a050fb1', '1', 'guest_75', '0', null, '0', null, null, '', null, null, '2019-08-24 22:35:58', null, '2019-08-24 22:36:02', '2019-08-24 22:40:32', '270', '1', 'ios', 'iPhone6,2', '1.0.0', 'test', 'new_client-mobile', 'CB96F00D-2735-4FF5-8AF3-34C973C2D57D', '125.69.44.152', 'ios', 'iPhone6,2', '1.0.0', 'test', 'new_client-mobile', 'CB96F00D-2735-4FF5-8AF3-34C973C2D57D', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2751', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('76', 'guest_76', '38b53cc5b1b34081bac4bf2f9a2b8feb', '1', 'guest_76', '0', null, '0', null, null, '', null, null, '2019-08-25 02:31:34', null, '2019-08-25 02:43:19', '2019-08-25 02:43:35', '19', '2', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:15:5D:6B:27:1F44232914', '182.149.167.79', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '00:15:5D:6B:27:1F77254612', '182.149.167.79', '6', '0', '0', '0', '0', '0', '2752', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('77', 'guest_77', '20f33c0cda8c9f13a1f15feb2e26b70a', '1', 'guest_77', '0', null, '0', null, null, '', null, null, '2019-08-25 10:11:17', null, '2019-08-25 16:37:10', '2019-08-25 16:36:58', '2487', '8', 'android', 'oppo r7', '1.0.0', 'test', 'org.cocos2dx.new_client', 'd3287aa4-d039-45bd-8f57-1fb6b8d7faa91566699076147', '125.69.44.152', 'android', 'oppo r7', '1.0.0', 'test', 'org.cocos2dx.new_client', 'd3287aa4-d039-45bd-8f57-1fb6b8d7faa91566699076147', '125.69.44.152', '6', '0', '0', '0', '0', '0', '2753', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '8e7c6df5986f5f228b21d646b4987598'), ('78', '18583968687', '981114e908e13059a541a506698f70de', '0', '18583968687', '0', null, '0', null, null, null, null, null, '2019-08-25 10:43:47', '2019-08-25 10:43:47', '2019-08-25 15:04:51', '2019-08-25 15:30:37', '2469', '6', 'android', 'V1824A', '1.0.0', 'test', 'org.cocos2dx.new_client', '3b442ec5-4952-4934-860a-44e2944363a31566701025283', '125.69.44.152', 'android', 'V1824A', '1.0.0', 'test', 'org.cocos2dx.new_client', '3b442ec5-4952-4934-860a-44e2944363a31566701025283', '125.69.44.152', '6', '0', '0', '0', '0', '0', '0', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '0d89607c94a26462208577f928a2f561'), ('79', 'guest_79', '910155aa1b7e76cdf028f147c6cd3040', '1', 'guest_79', '0', null, '0', null, null, null, null, null, '2019-08-25 14:37:18', null, '2019-08-25 14:37:26', '2019-08-25 14:38:06', '40', '1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '08:1F:71:1C:2C:84581620323', '182.149.167.79', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '08:1F:71:1C:2C:84581620323', '182.149.167.79', '6', '0', '0', '0', '0', '0', '2754', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('80', 'guest_80', '4cb1c3bdd190985ab63a1e50fa03fa0d', '1', 'guest_80', '0', null, '0', null, null, null, null, null, '2019-08-25 15:09:33', null, '2019-08-25 15:39:00', '2019-08-25 15:21:41', '383', '3', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', 'B4:6B:FC:61:51:93297213550', '110.185.57.246', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', 'B4:6B:FC:61:51:93399853360', '110.185.57.246', '6', '0', '0', '0', '0', '0', '2755', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null), ('81', '15608008806', '106585a247a16a9a7cf2260cb551e342', '0', '15608008806', '0', null, '0', null, null, null, null, null, '2019-08-25 15:57:08', '2019-08-25 15:57:08', '2019-08-25 15:57:08', '2019-08-25 15:58:55', '107', '1', 'android', 'MuMu', '1.0.0', 'test', 'org.cocos2dx.new_client', 'new_71a9f046-ce2b-4279-87da-482a84dd13eb1566719857700', '110.185.57.246', 'android', 'MuMu', '1.0.0', 'test', 'org.cocos2dx.new_client', 'new_71a9f046-ce2b-4279-87da-482a84dd13eb1566719857700', '110.185.57.246', '6', '0', '0', '0', '0', '0', '0', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, '02915a0638d09a311aae7298d6445a99'), ('82', '18728483303', 'e10adc3949ba59abbe56e057f20f883e', '0', 'guest_82', '0', null, '0', '廖**', '廖海龙', 'liaohailong****@126.com', 'liaohailong1228@126.com', '2019-08-25 18:06:00', '2019-08-25 18:05:05', '2019-08-25 18:05:40', '2019-08-25 18:06:13', '2019-08-25 18:06:49', '100', '2', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '08:1F:71:1C:2C:84586729195', '127.0.0.1', 'windows', 'Win32 Mobile Test', '1.0.0', 'test', 'Bundle Test', '08:1F:71:1C:2C:84485549172', '127.0.0.1', '5', '0', '0', '0', '0', '0', '2756', '2', '0', '**', '**', '6', '0', null, '0', '0', '0', null, null);
COMMIT;

-- ----------------------------
-- Table structure for t_account_append_info
-- ----------------------------
DROP TABLE IF EXISTS `t_account_append_info`;
CREATE TABLE `t_account_append_info` (
`guid`  int(11) NOT NULL COMMENT '全局唯一标识符' ,
`key`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键' ,
`value`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '值' ,
`created_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`guid`, `key`),
INDEX `idx_key` (`key`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_account_append_info
-- ----------------------------
BEGIN;
INSERT INTO `t_account_append_info` VALUES ('5', 'promotion_info', '-5', '2019-08-10 17:31:08', '2019-08-10 17:31:08'), ('7', 'promotion_info', '-5', '2019-08-10 18:16:49', '2019-08-10 18:16:49'), ('8', 'promotion_info', '-5', '2019-08-10 18:20:22', '2019-08-10 18:20:22'), ('10', 'promotion_info', '-5', '2019-08-10 20:11:27', '2019-08-10 20:11:27'), ('14', 'promotion_info', '-5', '2019-08-12 13:49:02', '2019-08-12 13:49:02'), ('17', 'promotion_info', '-5', '2019-08-12 23:03:35', '2019-08-12 23:03:35'), ('18', 'promotion_info', '-5', '2019-08-12 23:10:10', '2019-08-12 23:10:10'), ('20', 'promotion_info', '-5', '2019-08-13 11:07:45', '2019-08-13 11:07:45'), ('21', 'promotion_info', '-5', '2019-08-14 10:20:51', '2019-08-14 10:20:51'), ('24', 'promotion_info', '-5', '2019-08-14 14:37:49', '2019-08-14 14:37:49'), ('52', 'promotion_info', '2498848730', '2019-08-21 14:47:53', '2019-08-21 14:47:53'), ('53', 'promotion_info', 'https://aiff.me/link/A559FqJ6jsYboMMn?mu=0', '2019-08-21 14:47:58', '2019-08-21 14:47:58'), ('54', 'promotion_info', 'https://aiff.me/link/A559FqJ6jsYboMMn?mu=0', '2019-08-21 15:28:45', '2019-08-21 15:28:45'), ('62', 'promotion_info', 'https://www.db223.com/enter/pc.html', '2019-08-23 21:46:00', '2019-08-23 21:46:00'), ('72', 'promotion_info', '15300602206', '2019-08-24 11:36:08', '2019-08-24 11:36:08'), ('75', 'promotion_info', '-5', '2019-08-24 22:35:58', '2019-08-24 22:35:58');
COMMIT;

-- ----------------------------
-- Table structure for t_channel_invite
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite`;
CREATE TABLE `t_channel_invite` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键' ,
`channel_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号' ,
`channel_lock`  tinyint(3) NULL DEFAULT 0 COMMENT '1开启 0关闭' ,
`big_lock`  tinyint(3) NULL DEFAULT 1 COMMENT '1开启 0关闭' ,
`tax_rate`  int(11) UNSIGNED NOT NULL DEFAULT 1 COMMENT '税率 百分比' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_channel_invite
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_channel_validatebox
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_validatebox`;
CREATE TABLE `t_channel_validatebox` (
`id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道id' ,
`login_validatebox`  tinyint(1) NOT NULL COMMENT '是否开启登陆验证框' ,
`create_validatebox`  tinyint(1) NOT NULL COMMENT '是否开启创建账号验证框' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '添加验证码原因' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_channel_validatebox
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_globle_append_info
-- ----------------------------
DROP TABLE IF EXISTS `t_globle_append_info`;
CREATE TABLE `t_globle_append_info` (
`globle_key`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'key' ,
`info`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '内容' ,
`status`  tinyint(2) NULL DEFAULT 0 COMMENT '1 激活 其它未激活' ,
`channel_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号' ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '平台id' ,
`created_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`globle_key`, `created_time`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_globle_append_info
-- ----------------------------
BEGIN;
INSERT INTO `t_globle_append_info` VALUES ('risk', '{\"1\":0,\"2\":0,\"3\":0,\"4\":0,\"5\":0}', '1', null, '', '2019-08-22 15:28:26');
COMMIT;

-- ----------------------------
-- Table structure for t_guest_id
-- ----------------------------
DROP TABLE IF EXISTS `t_guest_id`;
CREATE TABLE `t_guest_id` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`id_key`  int(11) NOT NULL DEFAULT 0 COMMENT '用于更新' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `index_id_key` (`id_key`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=10071

;

-- ----------------------------
-- Records of t_guest_id
-- ----------------------------
BEGIN;
INSERT INTO `t_guest_id` VALUES ('10070', '0');
COMMIT;

-- ----------------------------
-- Table structure for t_online_account
-- ----------------------------
DROP TABLE IF EXISTS `t_online_account`;
CREATE TABLE `t_online_account` (
`guid`  int(11) NOT NULL DEFAULT 0 COMMENT '全局唯一标识符' ,
`first_game_type`  int(11) NULL DEFAULT NULL COMMENT '5斗地主 6炸金花 8百人牛牛' ,
`second_game_type`  int(11) NULL DEFAULT NULL COMMENT '1新手场 2初级场 3 高级场 4富豪场' ,
`game_id`  int(11) NULL DEFAULT NULL COMMENT '游戏ID' ,
`in_game`  int(11) NOT NULL DEFAULT 0 COMMENT '1在玩游戏，0在大厅' ,
PRIMARY KEY (`guid`),
INDEX `index_guid_game_id` (`guid`, `game_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='在线账号表'

;

-- ----------------------------
-- Records of t_online_account
-- ----------------------------
BEGIN;
INSERT INTO `t_online_account` VALUES ('54', '27', '1', '27001', '1'), ('65', '25', '1', '15001', '1'), ('66', '25', '1', '15001', '1'), ('77', '25', '1', '15001', '0');
COMMIT;

-- ----------------------------
-- Table structure for t_player_bankcard
-- ----------------------------
DROP TABLE IF EXISTS `t_player_bankcard`;
CREATE TABLE `t_player_bankcard` (
`guid`  int(11) NOT NULL DEFAULT 0 COMMENT '账号guid' ,
`bank_card_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '银行卡姓名' ,
`bank_card_num`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '银行卡号' ,
`change_bankcard_num`  int(11) NULL DEFAULT 6 COMMENT '允许修改银行卡号次数' ,
`bank_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '所属银行' ,
`bank_province`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '开户省' ,
`bank_city`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '开户市' ,
`bank_branch`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '开户支行' ,
`platform_id`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id' ,
`created_time`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_player_bankcard
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_player_proxy
-- ----------------------------
DROP TABLE IF EXISTS `t_player_proxy`;
CREATE TABLE `t_player_proxy` (
`guid`  int(11) NOT NULL DEFAULT 0 COMMENT '申请成为代理商的账号guid' ,
`proxy_id`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商id' ,
`proxy_guid`  int(11) NULL DEFAULT NULL COMMENT '创建的代理商账号guid' ,
`status`  tinyint(4) NULL DEFAULT 0 COMMENT ' 创建代理商账号状态：0未创建 ，1 account创建成功等待创建t_player 2创建完毕' ,
PRIMARY KEY (`proxy_id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_player_proxy
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_validatebox_feng_ip
-- ----------------------------
DROP TABLE IF EXISTS `t_validatebox_feng_ip`;
CREATE TABLE `t_validatebox_feng_ip` (
`ip`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '封掉的IP,当天禁止注册账号' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
`enabled`  int(11) NOT NULL DEFAULT 1 COMMENT '是否开启此功能(1开启 0不开启)' ,
PRIMARY KEY (`ip`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_validatebox_feng_ip
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for tj_update_password_log
-- ----------------------------
DROP TABLE IF EXISTS `tj_update_password_log`;
CREATE TABLE `tj_update_password_log` (
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`oldpassword`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '旧密码' ,
`newpassword`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '新密码' ,
`uptime`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间' ,
PRIMARY KEY (`uptime`, `guid`),
INDEX `guid` (`guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of tj_update_password_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`password`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`remember_token`  varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
`email`  varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_general_ci
AUTO_INCREMENT=4

;

-- ----------------------------
-- Records of users
-- ----------------------------
BEGIN;
INSERT INTO `users` VALUES ('1', 'admin@163.com', '$2y$10$fF68LHYl.d5YjMH.qhcyROSKruKT.7opZF0jK8rBuGV4L./bZPkQ2', '3KV0pTT1uNMXEzGbDPfRk1tOSsIUJEr8d7HxAyN6QP63BIhEFzVKmQviXYDh', null, '2019-08-19 15:54:45', null, 'admin@163.com'), ('2', 'test', '$2y$10$WD8Rntg9Zh6YXPoWc6ZQ0ulfX8eySvxIO6yAa93FmeHUIU5Pkfhvq', 'VACIKPdpwPIaRdNfLdSxjJ1L7WxWajW4vXNHv2QfhRVE6x8bxv3WGf7omRi9', '2019-08-16 22:02:42', '2019-08-17 23:37:35', null, 'test@163.com'), ('3', 'test1', '$2y$10$Zftw380CEpeZTI.YFl0nY.VNYiX4ODsKdIZ6jIY4sBlzMdkYz2/bK', '6e8q6hp3ddqK3UkeoheRz3pRLwlLrvxDVWU8Yxw1Ct4pQVD9MAkciqAlmdrm', '2019-08-16 23:58:50', '2019-08-17 00:23:14', null, 'test1@163.com');
COMMIT;

-- ----------------------------
-- Procedure structure for charge_rate
-- ----------------------------
DROP PROCEDURE IF EXISTS `charge_rate`;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `charge_rate`(IN `GUID_` int)
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
        charge_success_num_ , agent_success_num_ , agent_rate_def_ , charge_max_ , charge_time_ , charge_times_ , charge_moneys_ , agent_rate_other_ , agent_rate_add_ , agent_close_times_ , agent_rate_decr_ from t_recharge_config;

    select charge_num_ as charge_num ,charge_money_ as charge_money,  agent_num_ as agent_num , agent_money_ as agent_money, 
    charge_success_num_ as charge_success_num , agent_success_num_ as agent_success_num , agent_rate_def_ as agent_rate_def , charge_max_ as charge_max , charge_time_ as charge_time , charge_times_ as charge_times , 
    charge_moneys_ as charge_moneys , agent_rate_other_ as agent_rate_other , agent_rate_add_ as agent_rate_add , agent_close_times_ as agent_close_times , agent_rate_decr_ as agent_rate_decr;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for check_is_agent
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_is_agent`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `check_is_agent`(IN `guid_1` int,IN `guid_2` int,IN `ignore_platform` int)
    COMMENT '查询guid1，guid2 是否为代理商却是否支持转账功能'
label_pro:BEGIN
	DECLARE guidAflg int;
	DECLARE guidBflg int;
	DECLARE platform VARCHAR(256) DEFAULT '';

	select enable_transfer,platform_id into guidAflg,platform from t_account where guid = guid_1;
	IF ignore_platform = 1 THEN
		select enable_transfer into guidBflg from t_account where guid = guid_2;
	ELSE
		select enable_transfer into guidBflg from t_account where guid = guid_2 and platform_id = platform;
	END IF;
	

	if guidAflg is null then
		set guidAflg = 9;
	end if;
	if guidBflg is null then
		set guidBflg = 9;
	end if;
	
	select guidAflg * 10 + guidBflg as retCode,platform as platform_id;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for check_platform
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_platform`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `check_platform`(IN `guid1_` int,IN `guid2_` int)
BEGIN
	DECLARE platform1 VARCHAR(256);
	DECLARE platform2 VARCHAR(256);
	DECLARE ret INT DEFAULT 0;
	DECLARE platform VARCHAR(256) DEFAULT '';

	SELECT platform_id INTO platform1 FROM t_account WHERE guid = guid1_;
	SELECT platform_id INTO platform2 FROM t_account WHERE guid = guid2_;
	IF platform1 IS NULL OR platform2 IS NULL THEN
		SET ret = 0;
	ELSEIF platform1 = platform2 THEN
		SET ret = 1;
		SET platform = platform1;
	ELSE
		SET ret = 0;
	END IF;

	SELECT ret AS retCode,platform AS platform_id;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_account`(IN `account_` VARCHAR(64), IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256) ,IN `platform_id_` varchar(256),IN `validatebox_feng_ip_` int , IN `shared_id_` varchar(256))
    COMMENT '创建账号'
label_pro:BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE registerCount int DEFAULT '0';
	DECLARE ip_contorl varchar(64);
	DECLARE register_time_ INT;
	DECLARE feng_ip_ INT DEFAULT 0;
	DECLARE using_login_validatebox_ INT DEFAULT 0;
    DECLARE seniorpromoter_ int DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;

	IF validatebox_feng_ip_ > 0 THEN
		select count(*) into feng_ip_ from t_validatebox_feng_ip where ip = ip_ and enabled = 1 and time > date_sub(curdate(),interval 0 day);
		IF feng_ip_ > 0 THEN
			SELECT '-100' AS account, '-99' AS password, -99 AS guid, '-99' AS nickname, using_login_validatebox_ as using_login_validatebox;
			LEAVE label_pro;
		END IF;
	END IF;

	select count(*) into registerCount from t_account where ip = ip_ and create_time > date_sub(curdate(),interval 0 day);	
	if registerCount < 20 then
			SELECT create_validatebox INTO using_login_validatebox_ FROM t_channel_validatebox WHERE id = channel_id_;
                if registerCount >= 3 and using_login_validatebox_ = 0 then
                    set using_login_validatebox_ = 1;
                end if;
			select ip into ip_contorl from feng_ip where ip = ip_;
			if ip_contorl is null then
				SET password_ = MD5(account_);
				-- SET nickname_ = CONCAT("guest_", get_guest_id());
                select UNIX_TIMESTAMP(now()) into register_time_;
				if shared_id_ = "" then
					set shared_id_ = null;
				end if;
				INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,`platform_id`,register_time,shared_id)
                VALUES (account_,password_,0,account_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,platform_id_,FROM_UNIXTIME(register_time_),ifnull(shared_id_,NULL));
                
                set guid_ = LAST_INSERT_ID();
                
                select promoter_id into seniorpromoter_ from promoter_own_ips where ip = ip_ and bag_id = channel_id_ and uptime>=DATE_SUB(NOW(),INTERVAL 2 HOUR);
                if seniorpromoter_ <> null or seniorpromoter_ <> 0 then
                    update t_account set seniorpromoter = seniorpromoter_ where guid = guid_;
                end if;
                
				SELECT account_ AS account, password_ AS password, guid_ AS guid, account_ AS nickname , register_time_ as register_time, using_login_validatebox_ as using_login_validatebox ,seniorpromoter_ as seniorpromoter;
                
                
			ELSE
				SET ret = 15;
				SELECT '-99' AS account, '-99' AS password, -99 AS guid, '-99' AS nickname, using_login_validatebox_ as using_login_validatebox;
			end if;
		
	else
		SELECT '-99' AS account, '-99' AS password, -99 AS guid, '-99' AS nickname, using_login_validatebox_ as using_login_validatebox;
	end if;	
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_guest_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_guest_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_guest_account`(IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256),IN `deprecated_imei_` varchar(256), IN `platform_id_` varchar(256),IN `validatebox_feng_ip_` int,IN `shared_id_` varchar(256),IN `promotion_info_` varchar(1024))
    COMMENT '创建游客账号'
label_pro:BEGIN
	DECLARE guest_id_ BIGINT;
	DECLARE feng_ip_ INT DEFAULT 0;
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
	DECLARE ip_contorl varchar(64);
	DECLARE create_time_ INT;
	DECLARE register_time_ INT;
  	DECLARE bank_password_ varchar(32);
  	DECLARE imeitemp VARCHAR(256) DEFAULT '';
	DECLARE using_login_validatebox_ INT DEFAULT 0;
	DECLARE bank_card_name_ VARCHAR(64) DEFAULT '**';
	DECLARE bank_card_num_ VARCHAR(64) DEFAULT '**';
  	DECLARE change_bankcard_num_ INT DEFAULT 1;
  	DECLARE bank_name_ varchar(64) DEFAULT '';
  	DECLARE bank_province_ varchar(64) DEFAULT '';
  	DECLARE bank_city_ varchar(64) DEFAULT '';
	DECLARE bank_branch_ varchar(64) DEFAULT '';
	DECLARE seniorpromoter_ int DEFAULT 0;
	DECLARE promotion_info_temp varchar(1024) DEFAULT '';

	IF validatebox_feng_ip_ > 0 THEN
		select count(*) into feng_ip_ from t_validatebox_feng_ip where ip = ip_ and enabled = 1 and time > date_sub(curdate(),interval 0 day);
		IF feng_ip_ > 0 THEN
			SELECT is_first,998 AS ret, guid_ as guid, account_ as account, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, 
			change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer,IFNULL(create_time_,0) as create_time , IFNULL(register_time_,0) as register_time , ifnull(bank_password_ , "") as bank_password, imeitemp as imei, using_login_validatebox_ as using_login_validatebox,
			bank_card_name_ as bank_card_name, bank_card_num_ as bank_card_num,change_bankcard_num_ as change_bankcard_num , bank_name_ as bank_name , bank_province_ as bank_province , bank_city_ as bank_city , bank_branch_ as bank_branch ,seniorpromoter_ as seniorpromoter;
			LEAVE label_pro;
		END IF;
	END IF;
	

	select count(*) into registerCount from t_account where ip = ip_ and create_time > date_sub(curdate(),interval 0 day);
	
	SELECT create_validatebox INTO using_login_validatebox_ FROM t_channel_validatebox WHERE id = channel_id_;
	if registerCount >= 3 and using_login_validatebox_ = 0 then
		set using_login_validatebox_ = 1;
	end if;
	select ip into ip_contorl from feng_ip where ip = ip_;
	if ip_contorl is null then
		SELECT guid,ifnull(bank_password,""), account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,IFNULL(UNIX_TIMESTAMP(create_time),0),IFNULL(UNIX_TIMESTAMP(register_time),0)
		INTO guid_,bank_password_ , account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,create_time_,register_time_
		FROM t_account WHERE imei = imei_ and platform_id = platform_id_;
		
		
		IF guid_ = 0 THEN
		
			SELECT guid,ifnull(bank_password,""), account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,IFNULL(UNIX_TIMESTAMP(create_time),0),IFNULL(UNIX_TIMESTAMP(register_time),0)
			INTO guid_,bank_password_ , account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_,change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,create_time_,register_time_
			FROM t_account WHERE imei = deprecated_imei_ and platform_id = platform_id_;
			
			
			IF guid_ = 0 THEN

				if registerCount < 20 and char_length(imei_) > 0 then

					SET guid_ = get_guest_id();
					SET account_ = CONCAT(CONCAT("guest_temp_", guid_),UNIX_TIMESTAMP(now()));
					SET password_ = MD5(account_);
					SET nickname_ = CONCAT(CONCAT("guest_temp_", guid_),UNIX_TIMESTAMP(now()));

					SELECT channel_lock INTO channel_lock_ FROM t_channel_invite WHERE channel_id=channel_id_ AND big_lock=1;
					IF channel_lock_ != 1 THEN
						SET is_first = 2;
					END IF;
					
					if shared_id_ = "" then
						set shared_id_ = null;
					end if;

					INSERT INTO t_account (account,password,is_guest,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code,login_count,login_time,
					`last_login_phone`,`last_login_phone_type`,`last_login_version`,`last_login_channel_id`,`last_login_package_name`,`last_login_imei`,`last_login_ip`,`platform_id`,`shared_id`) 
					VALUES (account_,password_,1,nickname_,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,HEX(guid_),1,now(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,platform_id_,ifnull(shared_id_,NULL));
					
					
					SET guid_ = LAST_INSERT_ID();
					SET account_ = CONCAT("guest_", guid_);
					SET password_ = MD5(account_);
					SET nickname_ = CONCAT("guest_", guid_);
					
					if char_length(promotion_info_) > 0 then
						INSERT INTO t_account_append_info(guid , `key`, `value`) 
						values(guid_ , 'promotion_info' , promotion_info_);
					end if;
					
					update t_account set account = account_ , password = password_, nickname = nickname_ where guid = guid_;
					
					SELECT guid,ifnull(bank_password,""), account, ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,UNIX_TIMESTAMP(NOW()),0
					INTO guid_,bank_password_, account_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,create_time_,register_time_ FROM t_account WHERE imei = imei_;
					
					select promoter_id into seniorpromoter_ from promoter_own_ips where ip = ip_ and bag_id = channel_id_ and uptime>=DATE_SUB(NOW(),INTERVAL 2 HOUR);
					if seniorpromoter_ <> null or seniorpromoter_ <> 0 then
						update t_account set seniorpromoter = seniorpromoter_ where guid = guid_;
					end if;
					
					select bank_card_name,bank_card_num,change_bankcard_num,bank_name,bank_province,bank_city,bank_branch into bank_card_name_,bank_card_num_,change_bankcard_num_,bank_name_,bank_province_,bank_city_,bank_branch_ from t_player_bankcard where guid = guid_;
					
				else
					set ret = 999;
				end if;
			ELSE
				SET is_first = 2;
				IF disabled_ = 1 THEN
					SET ret = 15;
				ELSE
					set imeitemp = deprecated_imei_;
					UPDATE t_account SET login_count = login_count+1,last_login_phone = phone_ , last_login_phone_type = phone_type_,last_login_version = version_,last_login_channel_id = channel_id_,last_login_imei = deprecated_imei_,last_login_ip = ip_,login_time = now() WHERE guid=guid_;
				END IF;
			END IF;
		ELSE
			SET is_first = 2;
			IF disabled_ = 1 THEN
				SET ret = 15;
			ELSE
				set imeitemp = imei_;
				UPDATE t_account SET login_count = login_count+1,last_login_phone = phone_ , last_login_phone_type = phone_type_,last_login_version = version_,last_login_channel_id = channel_id_,last_login_imei = imei_,last_login_ip = ip_,login_time = now() WHERE guid=guid_;
				select bank_card_name,bank_card_num,change_bankcard_num,bank_name,bank_province,bank_city,bank_branch into bank_card_name_,bank_card_num_,change_bankcard_num_,bank_name_,bank_province_,bank_city_,bank_branch_ from t_player_bankcard where guid = guid_;
			END IF;
		END IF;
	ELSE 
		set ret = 15;
	end if;
	SELECT is_first,ret, guid_ as guid, account_ as account, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, 
	change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer,IFNULL(create_time_,0) as create_time , IFNULL(register_time_,0) as register_time , ifnull(bank_password_ , "") as bank_password, imeitemp as imei, using_login_validatebox_ as using_login_validatebox,
	bank_card_name_ as bank_card_name, bank_card_num_ as bank_card_num,change_bankcard_num_ as change_bankcard_num, bank_name_ as bank_name , bank_province_ as bank_province, bank_city_ as bank_city , bank_branch_ as bank_branch , seniorpromoter_ as seniorpromoter;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_or_update_bankcard
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_or_update_bankcard`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_or_update_bankcard`(IN `guid_` int,IN `platform_id_` varchar(256),IN bank_card_num_ varchar(64),IN bank_card_name_ varchar(64),IN bank_name_ varchar(64)
                                    ,IN bank_province_ varchar(64),IN bank_city_ varchar(64),IN bank_branch_ varchar(64))
    COMMENT '得到月盈利榜'
BEGIN
	DECLARE bank_card_name_old varchar(64);
    DECLARE bank_card_num_old varchar(64);
  
    select bank_card_name, bank_card_num into bank_card_name_old,bank_card_num_old from t_player_bankcard where guid = guid_ and platform_id = platform_id_;
    
    if (bank_card_name_old is null or bank_card_name_old = '**') and (bank_card_num_old is null or bank_card_num_old = '**') then
        insert into t_player_bankcard( guid , bank_card_name , bank_card_num , bank_name, bank_province, bank_city , bank_branch , platform_id) 
                     values(guid_, bank_card_name_, bank_card_num_, bank_name_, bank_province_, bank_city_, bank_branch_, platform_id_) on duplicate key update bank_card_name = bank_card_name_, 
                     bank_card_num = bank_card_num_, bank_name = bank_name_, bank_province = bank_province_, bank_city = bank_city_, bank_branch = bank_branch_, change_bankcard_num = change_bankcard_num - 1;
        select 1 ;
    else
        select 2 ;
    end if;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_proxy_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_proxy_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_proxy_account`(IN `guid_` int,IN `proxy_id_` int,IN `platform_id_` varchar(256))
label_pro:BEGIN

	DECLARE ret INT DEFAULT -1;
	DECLARE proxy_guid_ INTEGER DEFAULT 0; 
	DECLARE status_ TINYINT DEFAULT 0; 
	DECLARE order_count_ INT DEFAULT 0;
	DECLARE guest_id_ BIGINT;
	
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE password_ VARCHAR(32) DEFAULT '0';
	DECLARE nickname_ VARCHAR(32) DEFAULT '0';
	DECLARE phone_ VARCHAR(256) DEFAULT NULL;
	DECLARE phone_type_ VARCHAR(256) DEFAULT NULL;
	DECLARE version_ VARCHAR(256) DEFAULT NULL;
	DECLARE channel_id_ VARCHAR(256) DEFAULT NULL;
	DECLARE package_name_ VARCHAR(256) DEFAULT NULL;
	DECLARE imei_ VARCHAR(256) DEFAULT NULL;
	DECLARE ip_ VARCHAR(256) DEFAULT NULL;
	DECLARE invite_code_ varchar(32) DEFAULT '0';

	SELECT proxy_guid,status,1 FROM t_player_proxy WHERE guid = guid_ AND proxy_id = proxy_id_ INTO proxy_guid_,status_,order_count_;

	IF order_count_ = 0 THEN
		INSERT INTO t_player_proxy(guid,proxy_id,proxy_guid,status) VALUES(guid_,proxy_id_,0,0);
		IF ROW_COUNT() = 0 THEN
			SET ret = 1;
			SELECT ret,0 as proxy_guid,'0' as account,'0' as nickname;
			leave label_pro;
		END IF;

		SET proxy_guid_ = 0;
		SET status_ = 0;

	END IF;

	IF status_ = 0 THEN        
        SET guest_id_ = get_guest_id();
        SET account_ = CONCAT(CONCAT("guest_temp_", guest_id_),UNIX_TIMESTAMP(now()));
        SET password_ = MD5(account_);
        SET nickname_ = CONCAT(CONCAT("guest_temp_", guest_id_),UNIX_TIMESTAMP(now()));

		SELECT password,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code FROM t_account WHERE guid = guid_
		INTO password_,phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,invite_code_;

		SET imei_ =  CONCAT(imei_, "_", guest_id_);

		INSERT INTO t_account (account,password,is_guest,nickname,enable_transfer,create_time,phone,phone_type,version,channel_id,package_name,imei,ip,invite_code,login_count,platform_id) 
					VALUES (account_,password_,1,nickname_,1,NOW(),phone_,phone_type_,version_,channel_id_,package_name_,imei_,ip_,invite_code_,0,platform_id_);

		SELECT LAST_INSERT_ID() INTO proxy_guid_;
        
        SET account_ = CONCAT("guest_", proxy_guid_);
        SET password_ = MD5(account_);
        SET nickname_ = CONCAT("guest_", proxy_guid_);
        
        update t_account set account = account_ , password = password_, nickname = nickname_ where guid = proxy_guid_;

		UPDATE t_player_proxy SET proxy_guid = proxy_guid_, status = 1 WHERE guid = guid_ AND proxy_id = proxy_id_;

		IF ROW_COUNT() > 0 THEN
			SET ret = 0;
		ELSE
			SET ret = 2;
		END IF;

	ELSEIF status_ = 1 THEN
		SELECT account,nickname FROM t_account WHERE guid = proxy_guid_ INTO account_,nickname_;
		SET ret = 3;
	ELSEIF status_ = 2 THEN
		SET ret = 4;
	
	END IF;

	SELECT ret,proxy_guid_ as proxy_guid,account_ as account,nickname_ as nickname;
	
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for create_test_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_test_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `create_test_account`()
BEGIN
	DECLARE account_ VARCHAR(64) DEFAULT '0';
	DECLARE i INT DEFAULT 0;
	WHILE i < 50 DO
		SET i = i + 1;
		SET account_ = CONCAT("test_",i);
		INSERT INTO t_account (account,password,nickname,create_time,phone,phone_type,version,channel_id,package_name,imei,ip) VALUES (account_,MD5("123456"),account_,NOW(),"windows", "windows-test", "1.1", "test", "package-test", account_, "127.0.0.1");
	END WHILE;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for FreezeAccount
-- ----------------------------
DROP PROCEDURE IF EXISTS `FreezeAccount`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `FreezeAccount`(IN guid_ int(11),
                 IN status_ tinyint(4))
    COMMENT '封号，参数guid_：账号id，status_：设置的状态'
BEGIN
  DECLARE ret INT DEFAULT 0;
  DECLARE guid_t int(11);
  DECLARE status_t tinyint(4);
  
  update account.t_account set disabled = status_ where guid = guid_;
  
  select guid , disabled into guid_t , status_t from account.t_account where guid = guid_;
  
  if guid_t is null then
    set guid_t = -1;
  end if;
  if status_t is null then
    set status_t = -1;
  end if;
  
  if guid_t != guid_ or status_t != status_ then
    set ret = 1;
  else
    set ret = 0;
  end if;
  select ret as retCode , concat(guid_t,'|',status_t) as  retData;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for get_account_count
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_account_count`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_account_count`(IN `guid_` int, IN `platform_id_`  varchar(256))
BEGIN
	DECLARE ip_ varchar(256);
	DECLARE last_login_channel_id_ VARCHAR(256) DEFAULT '';
	DECLARE is_guest_ INT DEFAULT 0;
	DECLARE registerCount int DEFAULT '0';
	select ip,last_login_channel_id,is_guest into ip_,last_login_channel_id_,is_guest_ from t_account where guid = guid_ and platform_id = platform_id_;
	if ip_ is not null then 
		select count(*) into registerCount from t_account where ip = ip_ and create_time > date_sub(curdate(),interval 0 day);
		if registerCount > 3 then
			select "0" as retcode ,last_login_channel_id_ as last_login_channel_id ,is_guest_ as is_guest;
		else
			select "1" as retcode ,last_login_channel_id_ as last_login_channel_id ,is_guest_ as is_guest;
		end if;
	else
		select "0" as retcode ,last_login_channel_id_ as last_login_channel_id ,is_guest_ as is_guest ;
	end if;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for get_player_append_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_append_info`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_player_append_info`(IN `GUID_` int)
    COMMENT 'GUID_ '
BEGIN

    -- 推广员数据
    DECLARE seniorpromoter_ int DEFAULT 0;
    DECLARE identity_type_  int default 0;
    DECLARE identity_param_  int default 0;
    DECLARE risk_ int default 0;
    DECLARE create_time_ varchar(256) default '';
    
    -- 危险等级显示代理充值对应概率
    DECLARE risk_show_proxy_ varchar(64) default '';
    
    select seniorpromoter,type,level,risk,unix_timestamp(create_time) into seniorpromoter_,identity_type_,identity_param_,risk_,create_time_ FROM t_account WHERE guid = GUID_;
    if seniorpromoter_ = GUID_ then
        set seniorpromoter_ = 0;
    end if;
    
    select info into risk_show_proxy_ from t_globle_Append_info where `globle_key` = 'risk' and status = 1;
    
    select ifnull(seniorpromoter_ , 0) as seniorpromoter , ifnull ( identity_type_ , 0 ) as identity_type , ifnull (identity_param_ , 0 ) as identity_param , risk_ as risk , ifnull(risk_show_proxy_ , '') as risk_show_proxy,
    -- ifnull(create_time_,date_format(CURRENT_TIMESTAMP,'%Y-%m-%d %k:%i:%s'));
    ifnull(create_time_,unix_timestamp(now())) as create_time;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for get_player_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_data`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_player_data`(IN `guid_` int,IN `account_` varchar(64),IN `nick_` varchar(64),IN `money_` int)
BEGIN
	DECLARE guid_tmp INTEGER DEFAULT 0;
    DECLARE header_icon_ int default 0;
	#DECLARE t_error INTEGER DEFAULT 0; 
	#DECLARE done INT DEFAULT 0; 
	#DECLARE suc INT DEFAULT 1; 
	#DECLARE tmp_val INTEGER DEFAULT 0; 
	#DECLARE tmp_total INTEGER DEFAULT 0;
	#DECLARE updateNum INT DEFAULT 1;
	#DECLARE deleteNum INT DEFAULT 0;
	#DECLARE selectNum INT DEFAULT 0;

	#DECLARE mycur CURSOR FOR SELECT `val` FROM t_channel_invite_tax WHERE guid=guid_;#定义光标 
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET t_error=1;  
	#DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
					

	SELECT guid INTO guid_tmp FROM t_player WHERE guid=guid_;
	IF guid_tmp = 0 THEN
        select mod(RAND() * 10, 10) into header_icon_;
		REPLACE INTO t_player SET guid=guid_,account=account_,nickname=nick_,money=money_,header_icon = header_icon_;
		#ELSE
			#START TRANSACTION; #打开光标  
			#OPEN mycur; #开始循环 
			#REPEAT 
			#		FETCH mycur INTO tmp_val;
			#		 IF NOT done THEN
			#				SET selectNum = selectNum+1;
			#				SET tmp_total = tmp_total + tmp_val;
			#				IF t_error = 1 THEN 
			#					SET suc = 0;
			#				END IF;  
			#		 END IF; 
			#UNTIL done END REPEAT;
			#CLOSE mycur;


			#IF tmp_total > 0 THEN
			#	UPDATE t_player SET money=money+(tmp_total) WHERE guid=guid_;
			#	SET updateNum = row_count();
			#END IF;

			#DELETE FROM t_channel_invite_tax WHERE guid=guid_;
			#SET deleteNum = row_count();

			
			#IF suc = 0 OR updateNum < 1 OR deleteNum != selectNum THEN
			#		ROLLBACK;
			#ELSE
			#		COMMIT; 
			#END IF;
			#SET suc = 1;
	END IF;
	SELECT level, money, bank, login_award_day, login_award_receive_day, online_award_time, online_award_num, relief_payment_count, header_icon, slotma_addition FROM t_player WHERE guid=guid_;
	
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for get_player_identity
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_identity`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_player_identity`(IN `GUID_` int)
    COMMENT 'GUID_ '
BEGIN
    DECLARE seniorpromoter_ int DEFAULT 0;
    DECLARE identity_type_  int default 0;
    DECLARE identity_param_  int default 0;
    DECLARE create_ip_ varchar(64);
    DECLARE platform_id_ varchar(256);
    
    select seniorpromoter,type,level into seniorpromoter_,identity_type_,identity_param_ FROM t_account WHERE guid = GUID_;
    
    if seniorpromoter_ = GUID_ then
        set seniorpromoter_ = 0;
    end if;
    
    select ifnull(seniorpromoter_ , 0) as seniorpromoter , ifnull ( identity_type_ , 0 ) as identity_type , ifnull (identity_param_ , 0 ) as identity_param;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sms_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `sms_login`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sms_login`(IN `account_` varchar(64),IN `ip_` varchar(64),IN `phone_` varchar(256),IN `imei_` varchar(256), IN `platform_id_` varchar(256), IN `shared_id_` varchar(256))
    COMMENT '验证账号，参数account_：账号，password_：密码'
BEGIN
	DECLARE ret INT DEFAULT 0;
	DECLARE guid_ INT DEFAULT 0;
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
	DECLARE channel_id_ VARCHAR(256) DEFAULT '0';
	DECLARE enable_transfer_ INT DEFAULT 0;
	DECLARE invite_code_ VARCHAR(32) DEFAULT '0';
	DECLARE inviter_guid_ INT DEFAULT 0;
  	DECLARE ip_contorl varchar(64);
	DECLARE create_time_ INT;
	DECLARE register_time_ INT;
  	DECLARE bank_password_ varchar(32);
	DECLARE using_login_validatebox_ INT DEFAULT 0;
	DECLARE feng_ip_ INT DEFAULT 0;
	DECLARE bank_card_name_ VARCHAR(64) DEFAULT '**';
	DECLARE bank_card_num_ VARCHAR(64) DEFAULT '**';
  	DECLARE change_bankcard_num_ INT DEFAULT 1;
  	DECLARE bank_name_ varchar(64) DEFAULT '';
  	DECLARE bank_province_ varchar(64) DEFAULT '';
  	DECLARE bank_city_ varchar(64) DEFAULT '';
	DECLARE bank_branch_ varchar(64) DEFAULT '';	
	DECLARE shared_id_t VARCHAR(256) DEFAULT '0';


	SELECT guid,ifnull(bank_password,""), ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code,IFNULL(UNIX_TIMESTAMP(create_time),0),IFNULL(UNIX_TIMESTAMP(register_time),0),ifnull(shared_id,"")
	INTO guid_, bank_password_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_,create_time_,register_time_,shared_id_t
	FROM t_account WHERE account = account_ and platform_id = platform_id_;
	IF guid_ = 0 THEN
		SELECT guid,ifnull(bank_password,""), ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, password, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code,IFNULL(UNIX_TIMESTAMP(create_time),0),IFNULL(UNIX_TIMESTAMP(register_time),0),ifnull(shared_id,"")
	INTO guid_, bank_password_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, password_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_,create_time_,register_time_,shared_id_t
	FROM t_account WHERE imei = imei_ and platform_id = platform_id_;
		if guid_ = 0 THEN
			SET ret = 3;
		ELSEIF is_guest_ = 1 THEN
				update t_account set account = account_, is_guest = 2 where imei = imei_ and platform_id = platform_id_;
				set is_guest_ = 0;
		end if;
	END IF;
		
	IF shared_id_t = "" AND (ifnull(shared_id_,"")  != "") AND  guid_ != 0 THEN
		UPDATE t_account SET shared_id = shared_id_ WHERE guid = guid_;
	END IF;
	
	IF enable_transfer_ = 1 THEN
		SET ret = 37;
	ELSEIF disabled_ = 1 THEN
		SET ret = 15;
	END IF;
	
	-- select ip into ip_contorl from feng_ip where ip = ip_;
	-- if ip_contorl is not null then
	--	 update t_account set disabled = 1 where guid = guid_;
	--	 insert ignore into `account`.`feng_guid` (`guid`, `phone`, `mac`, `reason`, `handler`) 
	--	 VALUES (guid_,phone_,imei_,'login ip disabled','verify_account');
	--	 SET ret = 15;
	-- end if;
	
	IF ret = 0 THEN
		UPDATE t_account SET login_count = login_count+1 WHERE guid=guid_;
		SELECT login_validatebox INTO using_login_validatebox_ FROM t_channel_validatebox WHERE id = channel_id_;
	END IF;
	
	
	select count(*) into feng_ip_ from t_validatebox_feng_ip where ip = ip_ and enabled = 1 and time > date_sub(curdate(),interval 0 day);
	if feng_ip_ > 0 then
		set ret = 41;
	end if;
	
	SELECT ret, phone_ as phoneType, guid_ as guid, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, password_ as password, alipay_account_ as alipay_account, alipay_name_ as alipay_name, 
	change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id, enable_transfer_ as enable_transfer, inviter_guid_ as inviter_guid, invite_code_ as invite_code,IFNULL(create_time_,0) as create_time , IFNULL(register_time_,0) as register_time, ifnull(bank_password_ , "") as bank_password, using_login_validatebox_ as using_login_validatebox,
	bank_card_name_ as bank_card_name, bank_card_num_ as  bank_card_num, change_bankcard_num_ as change_bankcard_num, bank_name_ as bank_name , bank_province_ as bank_province, bank_city_ as bank_city , bank_branch_ as bank_branch ;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for verify_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `verify_account`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `verify_account`(IN `account_` varchar(64),IN `password_` varchar(32),IN `ip_` varchar(64),IN `phone_` varchar(256),IN `phone_type_` varchar(256),IN `version_` varchar(256),IN `l_channel_id_` varchar(256),
                                    IN `package_name_` varchar(256),IN `imei_` varchar(256),IN `deprecated_imei_` varchar(256),IN `platform_id_` varchar(256),IN `shared_id_` varchar(256))
    COMMENT '验证账号，参数account_：账号，password_：密码'
BEGIN
    DECLARE ret INT DEFAULT 0;
    DECLARE guid_ INT DEFAULT 0;
    DECLARE no_bank_password INT DEFAULT 0;
    DECLARE bank_password_ varchar(32);
    DECLARE vip_ INT DEFAULT 0;
    DECLARE login_time_ INT;
    DECLARE logout_time_ INT;
    DECLARE is_guest_ INT DEFAULT 0;
    DECLARE nickname_ VARCHAR(32) DEFAULT '0';
    DECLARE alipay_account_ VARCHAR(32) DEFAULT '0';
    DECLARE alipay_name_ VARCHAR(32) DEFAULT '0';
    DECLARE change_alipay_num_ INT DEFAULT 0;
    DECLARE disabled_ INT DEFAULT 0;
    DECLARE risk_ INT DEFAULT 0;
    DECLARE channel_id_ VARCHAR(256) DEFAULT '0';
    DECLARE enable_transfer_ INT DEFAULT 0;
    DECLARE invite_code_ VARCHAR(32) DEFAULT '0';
    DECLARE inviter_guid_ INT DEFAULT 0;
    DECLARE ip_contorl varchar(64);
    DECLARE create_time_ INT;
    DECLARE register_time_ INT;
    DECLARE imeitemp VARCHAR(256) DEFAULT '';
    DECLARE playerTemp int default 0;
    DECLARE registerCount int DEFAULT '0';
    DECLARE using_login_validatebox_ INT DEFAULT 0;
	DECLARE feng_ip_ INT DEFAULT 0;
	DECLARE bank_card_name_ VARCHAR(64) DEFAULT '**';
	DECLARE bank_card_num_ VARCHAR(64) DEFAULT '**';
  	DECLARE change_bankcard_num_ INT DEFAULT 1;
  	DECLARE bank_name_ varchar(64) DEFAULT '';
  	DECLARE bank_province_ varchar(64) DEFAULT '';
  	DECLARE bank_city_ varchar(64) DEFAULT '';
    DECLARE bank_branch_ varchar(64) DEFAULT '';
    DECLARE seniorpromoter_ INT DEFAULT 0;
    DECLARE shared_id_t VARCHAR(256) DEFAULT '0';

    SELECT login_validatebox INTO using_login_validatebox_ FROM t_channel_validatebox WHERE id = l_channel_id_;
    select count(*) into registerCount from t_account where ip = ip_ and create_time > date_sub(curdate(),interval 0 day);
    
    if registerCount >= 3 and using_login_validatebox_ = 0 then
        set using_login_validatebox_ = 1;
    end if;
    
    SELECT guid,ifnull(bank_password,""), ISNULL(bank_password), vip, UNIX_TIMESTAMP(login_time), UNIX_TIMESTAMP(logout_time), is_guest, nickname, alipay_account, alipay_name, change_alipay_num, disabled, risk, channel_id, enable_transfer,inviter_guid,invite_code,
    IFNULL(UNIX_TIMESTAMP(create_time),0),IFNULL(UNIX_TIMESTAMP(register_time),0),imei,seniorpromoter,ifnull(shared_id,"")
    INTO guid_,bank_password_, no_bank_password, vip_, login_time_, logout_time_, is_guest_, nickname_, alipay_account_, alipay_name_, change_alipay_num_, disabled_, risk_, channel_id_, enable_transfer_,inviter_guid_,invite_code_,create_time_,register_time_,imeitemp,
    seniorpromoter_,shared_id_t FROM t_account WHERE account = account_ AND password = password_ and platform_id = platform_id_;
	
	IF shared_id_t = "" AND (ifnull(shared_id_,"")  != "") AND  guid_ != 0 THEN
		UPDATE t_account SET shared_id = shared_id_ WHERE guid = guid_;
	END IF;
	
    IF guid_ = 0 THEN
        SET ret = 27;
        SELECT 3 INTO ret FROM t_account WHERE account = account_ LIMIT 1;
    END IF;

    IF enable_transfer_ = 1 THEN
        SET ret = 37;
        ELSEIF disabled_ = 1 THEN
        SET ret = 15;
    END IF;

    -- select ip into ip_contorl from feng_ip where ip = ip_;
    -- if ip_contorl is not null then
    --   update t_account set disabled = 1 where guid = guid_;
    -- 
    --   insert ignore into `account`.`feng_guid` (`guid`, `phone`, `mac`, `reason`, `handler`) 
    --   VALUES (guid_,phone_,imei_,'login ip disabled','verify_account');
    -- 
    --   SET ret = 15;
    -- end if;

    select count(*) into feng_ip_ from t_validatebox_feng_ip where ip = ip_ and enabled = 1 and time > date_sub(curdate(),interval 0 day);
    if feng_ip_ > 0 then
        set ret = 41;
    end if;

    IF ret = 0 THEN
        select bank_card_name,bank_card_num,change_bankcard_num,bank_name,bank_province,bank_city,bank_branch into bank_card_name_,bank_card_num_,change_bankcard_num_,bank_name_,bank_province_,bank_city_,bank_branch_ from t_player_bankcard where guid = guid_;
        select count(1) into playerTemp from t_account where imei = imei_ and platform_id = platform_id_; 
        if left(imeitemp,4) <> 'new_' and imeitemp = deprecated_imei_ and left(imei_,4) = 'new_'  then
            if playerTemp = 0 then
                UPDATE t_account SET imei = imei_,login_count = login_count+1,last_login_phone = phone_ , last_login_phone_type = phone_type_,last_login_version = version_,last_login_channel_id = l_channel_id_,last_login_imei = imei_,last_login_ip = ip_,login_time = now() WHERE guid=guid_;
            else
                insert into imei_update_fail_list (`guid` , `platform_id` , `imei` , `deprecated_imei` , `ip`) 
                VALUES (guid_, platform_id_, imei_ , deprecated_imei_, ip_);
                UPDATE t_account SET              login_count = login_count+1,last_login_phone = phone_ , last_login_phone_type = phone_type_,last_login_version = version_,last_login_channel_id = l_channel_id_,last_login_imei = imei_,last_login_ip = ip_,login_time = now() WHERE guid=guid_;
            end if;
        else
            UPDATE t_account SET              login_count = login_count+1,last_login_phone = phone_ , last_login_phone_type = phone_type_,last_login_version = version_,last_login_channel_id = l_channel_id_,last_login_imei = imei_,last_login_ip = ip_,login_time = now() WHERE guid=guid_;
        end if;
    END IF;
    
    SELECT ret, phone_ as phoneType, guid_ as guid, no_bank_password, vip_ as vip, IFNULL(login_time_, 0) as login_time, IFNULL(logout_time_, 0) as logout_time, nickname_ as nickname, is_guest_ as is_guest, alipay_account_ as alipay_account, alipay_name_ as alipay_name, 
    change_alipay_num_ as change_alipay_num, risk_ as risk, channel_id_ as channel_id,  enable_transfer_ as enable_transfer, inviter_guid_ as inviter_guid, invite_code_ as invite_code,IFNULL(create_time_,0) as create_time , IFNULL(register_time_,0) as register_time , 
    ifnull(bank_password_ , "") as bank_password, using_login_validatebox_ as using_login_validatebox, bank_card_name_ as bank_card_name, bank_card_num_ as  bank_card_num, change_bankcard_num_ as change_bankcard_num, bank_name_ as bank_name , bank_province_ as bank_province,
    bank_city_ as bank_city , bank_branch_ as bank_branch , seniorpromoter_ as seniorpromoter;
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for get_guest_id
-- ----------------------------
DROP FUNCTION IF EXISTS `get_guest_id`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `get_guest_id`() RETURNS bigint(20)
BEGIN
	REPLACE INTO t_guest_id SET id_key = 0;
	RETURN LAST_INSERT_ID();
END
;;
DELIMITER ;

-- ----------------------------
-- Auto increment value for cash_ali_account
-- ----------------------------
ALTER TABLE `cash_ali_account` AUTO_INCREMENT=2;

-- ----------------------------
-- Auto increment value for feedback
-- ----------------------------
ALTER TABLE `feedback` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for menus
-- ----------------------------
ALTER TABLE `menus` AUTO_INCREMENT=45;

-- ----------------------------
-- Auto increment value for permission_role
-- ----------------------------
ALTER TABLE `permission_role` AUTO_INCREMENT=45;

-- ----------------------------
-- Auto increment value for permission_user
-- ----------------------------
ALTER TABLE `permission_user` AUTO_INCREMENT=2;

-- ----------------------------
-- Auto increment value for permissions
-- ----------------------------
ALTER TABLE `permissions` AUTO_INCREMENT=416;

-- ----------------------------
-- Auto increment value for plant_statistics
-- ----------------------------
ALTER TABLE `plant_statistics` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for plant_statistics_detail
-- ----------------------------
ALTER TABLE `plant_statistics_detail` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for quick_reply_type
-- ----------------------------
ALTER TABLE `quick_reply_type` AUTO_INCREMENT=6;

-- ----------------------------
-- Auto increment value for role_user
-- ----------------------------
ALTER TABLE `role_user` AUTO_INCREMENT=5;

-- ----------------------------
-- Auto increment value for roles
-- ----------------------------
ALTER TABLE `roles` AUTO_INCREMENT=6;

-- ----------------------------
-- Auto increment value for sms
-- ----------------------------
ALTER TABLE `sms` AUTO_INCREMENT=26;

-- ----------------------------
-- Auto increment value for t_account
-- ----------------------------
ALTER TABLE `t_account` AUTO_INCREMENT=83;

-- ----------------------------
-- Auto increment value for t_channel_invite
-- ----------------------------
ALTER TABLE `t_channel_invite` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_guest_id
-- ----------------------------
ALTER TABLE `t_guest_id` AUTO_INCREMENT=10071;

-- ----------------------------
-- Auto increment value for users
-- ----------------------------
ALTER TABLE `users` AUTO_INCREMENT=4;
