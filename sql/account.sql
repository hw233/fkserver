/*
 Navicat Premium Data Transfer

 Source Server         : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com
 Source Server Type    : MySQL
 Source Server Version : 50726
 Source Host           : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com:3306
 Source Schema         : account

 Target Server Type    : MySQL
 Target Server Version : 50726
 File Encoding         : 65001

 Date: 02/06/2020 15:11:18
*/

CREATE DATABASE IF NOT EXISTS account;
USE account;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for black_alipay
-- ----------------------------
DROP TABLE IF EXISTS `black_alipay`;
CREATE TABLE `black_alipay` (
  `alipay` varchar(64) NOT NULL COMMENT '支付宝账号(加黑将导致提现被挂起)',
  `reason` varchar(255) DEFAULT NULL COMMENT '加黑的原因',
  `handler` varchar(255) DEFAULT NULL COMMENT '操作用户',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`alipay`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for black_guid
-- ----------------------------
DROP TABLE IF EXISTS `black_guid`;
CREATE TABLE `black_guid` (
  `guid` int(11) NOT NULL COMMENT 'guid(加黑将导致提现被挂起)',
  `phone` varchar(64) DEFAULT NULL COMMENT '关联加黑的手机号，即account',
  `mac` varchar(255) DEFAULT NULL COMMENT '关联加黑的imei',
  `reason` varchar(255) DEFAULT NULL COMMENT '加黑的原因',
  `handler` varchar(255) DEFAULT NULL COMMENT '操作用户',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for feedback
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `processing_status` int(11) DEFAULT NULL,
  `guid` int(11) DEFAULT NULL,
  `reply_id` int(11) DEFAULT NULL,
  `account` int(11) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `is_readme` varchar(255) DEFAULT NULL,
  `author` varchar(255) DEFAULT NULL,
  `processing_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `active` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `child` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `sort` int(10) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  `icon` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of menus
-- ----------------------------
BEGIN;
INSERT INTO `menus` VALUES (1, '0', '/account/index', '玩家管理', '1', '2019-08-17 13:08:16', '2019-08-17 13:08:16', NULL, 'account.index', NULL, NULL);
INSERT INTO `menus` VALUES (2, '0', '/index/index', '系统管理', NULL, '2019-08-17 00:18:13', '2019-08-17 00:18:15', NULL, 'index.index', NULL, NULL);
INSERT INTO `menus` VALUES (3, '0', '/users/index', '用户列表', NULL, '2019-08-17 00:18:13', '2019-08-17 00:18:15', NULL, 'users.index', NULL, NULL);
INSERT INTO `menus` VALUES (4, '0', '/roles/index', '角色管理', NULL, '2019-08-17 00:18:13', '2019-08-17 00:18:15', NULL, 'roles.index', NULL, NULL);
INSERT INTO `menus` VALUES (5, '0', '/permissions/index', '权限管理', NULL, '2019-08-17 00:18:13', '2019-08-17 00:18:16', NULL, 'permissions.index', NULL, NULL);
INSERT INTO `menus` VALUES (6, '0', '/version/view', '版本管理', '1', '2019-08-17 13:08:15', '2019-08-17 13:08:15', NULL, 'version.view', NULL, NULL);
INSERT INTO `menus` VALUES (7, '0', '/client/gameTax', '房间管理', NULL, '2019-08-17 13:21:03', '2019-08-17 13:21:03', NULL, 'client.gametax', NULL, NULL);
INSERT INTO `menus` VALUES (8, '0', '/cash/index', '提现管理', '1', '2019-08-17 13:07:32', '2019-08-17 13:07:32', NULL, 'cash.index', NULL, NULL);
INSERT INTO `menus` VALUES (12, '0', '/cash/index', '提现列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', NULL, 'cash.index', 8, NULL);
INSERT INTO `menus` VALUES (13, '0', '/cash/risk', '风控列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', NULL, 'cash.risk', 8, NULL);
INSERT INTO `menus` VALUES (14, '0', '/cash/riskSystem', '风控比例', '1', '2019-08-17 13:20:57', '2019-08-17 13:20:57', NULL, 'cash.risksystem', 8, NULL);
INSERT INTO `menus` VALUES (15, '0', '/cash/servers', '服务器列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', NULL, 'cash.servers', 8, NULL);
INSERT INTO `menus` VALUES (16, '0', '/cash/aliAccount', '支付宝黑名单', '1', '2019-08-17 13:20:51', '2019-08-17 13:20:51', NULL, 'cash.aliaccount', 8, NULL);
INSERT INTO `menus` VALUES (17, '0', '/notice/index', '通知管理', '1', '2019-08-17 13:08:14', '2019-08-17 13:08:14', NULL, 'notice.index', NULL, NULL);
INSERT INTO `menus` VALUES (18, '0', '/notice/system', '通知列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:16', NULL, 'notice.system', 17, NULL);
INSERT INTO `menus` VALUES (19, '0', '/notice/specify', '私信列表', '1', '2019-08-17 00:18:14', '2019-08-17 00:18:17', NULL, 'notice.specify', 17, NULL);
INSERT INTO `menus` VALUES (20, '0', '/notice/sms', '短信列表', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', NULL, 'notice.sms', 17, NULL);
INSERT INTO `menus` VALUES (21, '0', '/feedback/index', '反馈管理', '1', '2019-08-17 13:08:15', '2019-08-17 13:08:15', NULL, 'feedback.index', NULL, NULL);
INSERT INTO `menus` VALUES (22, '0', '/feedback/index', '反馈列表', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', NULL, 'feedback.index', 21, NULL);
INSERT INTO `menus` VALUES (23, '0', '/feedback/quickReplyType', '快捷回复', '1', '2019-08-17 13:21:08', '2019-08-17 13:21:08', NULL, 'feedback.quickreplytype', 21, NULL);
INSERT INTO `menus` VALUES (24, '0', '/feedback/banSay', '玩家禁言', '1', '2019-08-17 13:20:44', '2019-08-17 13:20:44', NULL, 'feedback.bansay', 21, NULL);
INSERT INTO `menus` VALUES (25, '0', '/version/view', '添加版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', NULL, 'version.view', 6, NULL);
INSERT INTO `menus` VALUES (26, '0', '/version/frame', '框架版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', NULL, 'version.frame', 6, NULL);
INSERT INTO `menus` VALUES (27, '0', '/version/hall', '大厅版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', NULL, 'version.hall', 6, NULL);
INSERT INTO `menus` VALUES (28, '0', '/version/game', '游戏版本', '1', '2019-08-17 00:18:15', '2019-08-17 00:18:17', NULL, 'version.game', 6, NULL);
INSERT INTO `menus` VALUES (29, '0', '/client/index', '客户端配置', '1', '2019-08-17 13:08:19', '2019-08-17 13:08:19', NULL, 'client.index', NULL, NULL);
INSERT INTO `menus` VALUES (30, '0', '/client/viewConfig', '创建配置', NULL, '2019-08-17 13:20:30', '2019-08-17 13:20:30', NULL, 'client.viewconfig', 29, NULL);
INSERT INTO `menus` VALUES (31, '0', '/client/listConfig', '配置列表', NULL, '2019-08-17 13:20:34', '2019-08-17 13:20:34', NULL, 'client.listconfig', 29, NULL);
INSERT INTO `menus` VALUES (32, '0', '/client/template', '模版列表', NULL, '2019-08-17 00:18:16', '2019-08-17 00:18:18', NULL, 'client.template', 29, NULL);
INSERT INTO `menus` VALUES (33, '0', '/client/templateCreate', '创建模板', NULL, '2019-08-17 13:20:27', '2019-08-17 13:20:27', NULL, 'client.templatecreate', 29, NULL);
INSERT INTO `menus` VALUES (34, '0', '/client/templateConfigCreate', '导入模板', NULL, '2019-08-17 13:20:22', '2019-08-17 13:20:22', NULL, 'client.templateconfigcreate', 29, NULL);
INSERT INTO `menus` VALUES (35, '0', '/client/gameTax', '税收配置', NULL, '2019-08-17 13:20:40', '2019-08-17 13:20:40', NULL, 'client.gametax', 29, NULL);
INSERT INTO `menus` VALUES (36, '0', '/cash/customer', '客服提现管理', NULL, '2019-08-17 00:18:16', '2019-08-17 00:18:18', NULL, 'cash.customer', 8, NULL);
INSERT INTO `menus` VALUES (37, '0', '/rechargeorder/index', '充值列表', NULL, '2019-08-17 00:18:16', '2019-08-17 00:18:19', NULL, 'rechargeorder.index', NULL, NULL);
INSERT INTO `menus` VALUES (38, '0', '/distribution/index', '渠道商管理', NULL, '2019-08-17 00:18:17', '2019-08-17 00:18:19', NULL, 'distribution.index', NULL, NULL);
INSERT INTO `menus` VALUES (39, '0', '/account/index', '玩家列表', NULL, '2019-08-17 00:18:17', '2019-08-17 00:18:19', NULL, 'account.index', 1, NULL);
INSERT INTO `menus` VALUES (40, '0', '/account/riskStar', '星级关注', NULL, '2019-08-17 13:19:57', '2019-08-17 13:19:57', NULL, 'account.riskstar', 1, NULL);
INSERT INTO `menus` VALUES (41, '0', '/account/logLogin', '登陆日志', NULL, '2019-08-17 13:19:51', '2019-08-17 13:19:51', NULL, 'account.loglogin', 1, NULL);
INSERT INTO `menus` VALUES (42, '0', '/gameConfig/index', '游戏配置', '1', '2019-08-17 13:19:33', '2019-08-17 13:19:33', NULL, 'gameconfig.index', NULL, NULL);
INSERT INTO `menus` VALUES (43, '0', '/gameConfig/index', '配置首页', NULL, '2019-08-17 13:20:08', '2019-08-17 13:20:08', NULL, 'gameconfig.index', 42, NULL);
INSERT INTO `menus` VALUES (44, '0', '/fengBlack/fengIp', 'IP封禁列表', NULL, '2019-08-17 13:19:46', '2019-08-17 13:19:46', NULL, 'fengblack.fengIp', 1, NULL);
COMMIT;

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `permission_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
BEGIN;
INSERT INTO `permission_role` VALUES (8, '2019-08-16 23:44:35', '2019-08-16 23:44:35', 409, 5);
INSERT INTO `permission_role` VALUES (9, '2019-08-17 13:02:48', '2019-08-17 13:02:48', 409, 4);
INSERT INTO `permission_role` VALUES (10, '2019-08-17 13:02:48', '2019-08-17 13:02:48', 410, 4);
INSERT INTO `permission_role` VALUES (11, '2019-08-17 13:02:48', '2019-08-17 13:02:48', 411, 4);
INSERT INTO `permission_role` VALUES (12, '2019-08-17 13:02:48', '2019-08-17 13:02:48', 375, 4);
INSERT INTO `permission_role` VALUES (13, '2019-08-17 13:02:48', '2019-08-17 13:02:48', 376, 4);
INSERT INTO `permission_role` VALUES (14, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 377, 4);
INSERT INTO `permission_role` VALUES (15, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 378, 4);
INSERT INTO `permission_role` VALUES (16, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 395, 4);
INSERT INTO `permission_role` VALUES (17, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 396, 4);
INSERT INTO `permission_role` VALUES (18, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 397, 4);
INSERT INTO `permission_role` VALUES (19, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 398, 4);
INSERT INTO `permission_role` VALUES (20, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 405, 4);
INSERT INTO `permission_role` VALUES (21, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 399, 4);
INSERT INTO `permission_role` VALUES (22, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 400, 4);
INSERT INTO `permission_role` VALUES (23, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 401, 4);
INSERT INTO `permission_role` VALUES (24, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 402, 4);
INSERT INTO `permission_role` VALUES (25, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 403, 4);
INSERT INTO `permission_role` VALUES (26, '2019-08-17 13:02:49', '2019-08-17 13:02:49', 404, 4);
INSERT INTO `permission_role` VALUES (27, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 382, 4);
INSERT INTO `permission_role` VALUES (28, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 383, 4);
INSERT INTO `permission_role` VALUES (29, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 384, 4);
INSERT INTO `permission_role` VALUES (30, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 385, 4);
INSERT INTO `permission_role` VALUES (31, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 386, 4);
INSERT INTO `permission_role` VALUES (32, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 406, 4);
INSERT INTO `permission_role` VALUES (33, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 387, 4);
INSERT INTO `permission_role` VALUES (34, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 388, 4);
INSERT INTO `permission_role` VALUES (35, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 389, 4);
INSERT INTO `permission_role` VALUES (36, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 390, 4);
INSERT INTO `permission_role` VALUES (37, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 392, 4);
INSERT INTO `permission_role` VALUES (38, '2019-08-17 13:02:50', '2019-08-17 13:02:50', 393, 4);
INSERT INTO `permission_role` VALUES (39, '2019-08-17 13:02:51', '2019-08-17 13:02:51', 394, 4);
INSERT INTO `permission_role` VALUES (40, '2019-08-17 13:02:51', '2019-08-17 13:02:51', 407, 4);
INSERT INTO `permission_role` VALUES (41, '2019-08-17 13:02:51', '2019-08-17 13:02:51', 408, 4);
INSERT INTO `permission_role` VALUES (42, '2019-08-17 13:02:51', '2019-08-17 13:02:51', 413, 4);
INSERT INTO `permission_role` VALUES (43, '2019-08-17 13:02:51', '2019-08-17 13:02:51', 414, 4);
INSERT INTO `permission_role` VALUES (44, '2019-08-21 23:23:03', '2019-08-21 23:23:03', 415, 4);
COMMIT;

-- ----------------------------
-- Table structure for permission_user
-- ----------------------------
DROP TABLE IF EXISTS `permission_user`;
CREATE TABLE `permission_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `permission_id` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of permission_user
-- ----------------------------
BEGIN;
INSERT INTO `permission_user` VALUES (1, 3, 409, '2019-08-16 23:58:51', NULL);
COMMIT;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `level` int(10) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=416 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of permissions
-- ----------------------------
BEGIN;
INSERT INTO `permissions` VALUES (210, '玩家管理', 'account.index', '', 'account', 0, '2019-08-16 21:12:10', '2019-08-23 10:05:29');
INSERT INTO `permissions` VALUES (211, '系统管理', 'index.index', NULL, 'index', 0, '2019-08-16 21:12:19', '2019-08-16 21:12:19');
INSERT INTO `permissions` VALUES (212, '用户列表', 'users.index', NULL, 'users', 0, '2019-08-16 21:12:19', '2019-08-16 21:12:19');
INSERT INTO `permissions` VALUES (213, '角色管理', 'roles.index', NULL, 'roles', 0, '2019-08-16 21:12:19', '2019-08-16 21:12:19');
INSERT INTO `permissions` VALUES (214, '权限管理', 'permissions.index', NULL, 'permissions', 0, '2019-08-16 21:12:19', '2019-08-16 21:12:19');
INSERT INTO `permissions` VALUES (215, '版本管理', 'version.view', NULL, 'version', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (216, '房间管理', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (217, '提现管理', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (218, '提现列表', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (219, '风控列表', 'cash.risk', NULL, 'cash', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (220, '风控比例', 'cash.risksystem', NULL, 'cash', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (221, '服务器列表', 'cash.servers', NULL, 'cash', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (222, '支付宝黑名单', 'cash.aliaccount', NULL, 'cash', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (223, '通知管理', 'notice.index', NULL, 'notice', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (224, '通知列表', 'notice.system', NULL, 'notice', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (225, '私信列表', 'notice.specify', NULL, 'notice', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (226, '短信列表', 'notice.sms', NULL, 'notice', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (227, '反馈管理', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:12:20', '2019-08-16 21:12:20');
INSERT INTO `permissions` VALUES (228, '反馈列表', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (229, '快捷回复', 'feedback.quickreplytype', NULL, 'feedback', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (230, '玩家禁言', 'feedback.bansay', NULL, 'feedback', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (231, '添加版本', 'version.view', NULL, 'version', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (232, '框架版本', 'version.frame', NULL, 'version', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (233, '大厅版本', 'version.hall', NULL, 'version', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (234, '游戏版本', 'version.game', NULL, 'version', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (235, '客户端配置', 'client.index', NULL, 'client', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (236, '创建配置', 'client.viewconfig', NULL, 'client', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (237, '配置列表', 'client.listconfig', NULL, 'client', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (238, '模版列表', 'client.template', NULL, 'client', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (239, '创建模板', 'client.templatecreate', NULL, 'client', 0, '2019-08-16 21:12:21', '2019-08-16 21:12:21');
INSERT INTO `permissions` VALUES (240, '导入模板', 'client.templateconfigcreate', NULL, 'client', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (241, '税收配置', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (242, '客服提现管理', 'cash.customer', NULL, 'cash', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (243, '充值列表', 'rechargeorder.index', NULL, 'rechargeorder', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (244, '渠道商管理', 'distribution.index', NULL, 'distribution', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (245, '玩家列表', 'account.index', NULL, 'account', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (246, '星级关注', 'account.riskstar', NULL, 'account', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (247, '登陆日志', 'account.loglogin', NULL, 'account', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (248, '游戏配置', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (249, '配置首页', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (250, 'IP封禁列表', 'fengblack.fengip', NULL, 'fengBlack', 0, '2019-08-16 21:12:22', '2019-08-16 21:12:22');
INSERT INTO `permissions` VALUES (251, '玩家管理', 'account.index', NULL, 'account', 0, '2019-08-16 21:12:36', '2019-08-16 21:12:36');
INSERT INTO `permissions` VALUES (252, '系统管理', 'index.index', NULL, 'index', 0, '2019-08-16 21:12:36', '2019-08-16 21:12:36');
INSERT INTO `permissions` VALUES (253, '用户列表', 'users.index', NULL, 'users', 0, '2019-08-16 21:12:36', '2019-08-16 21:12:36');
INSERT INTO `permissions` VALUES (254, '角色管理', 'roles.index', NULL, 'roles', 0, '2019-08-16 21:12:36', '2019-08-16 21:12:36');
INSERT INTO `permissions` VALUES (255, '权限管理', 'permissions.index', NULL, 'permissions', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (256, '版本管理', 'version.view', NULL, 'version', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (257, '房间管理', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (258, '提现管理', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (259, '提现列表', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (260, '风控列表', 'cash.risk', NULL, 'cash', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (261, '风控比例', 'cash.risksystem', NULL, 'cash', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (262, '服务器列表', 'cash.servers', NULL, 'cash', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (263, '支付宝黑名单', 'cash.aliaccount', NULL, 'cash', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (264, '通知管理', 'notice.index', NULL, 'notice', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (265, '通知列表', 'notice.system', NULL, 'notice', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (266, '私信列表', 'notice.specify', NULL, 'notice', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (267, '短信列表', 'notice.sms', NULL, 'notice', 0, '2019-08-16 21:12:37', '2019-08-16 21:12:37');
INSERT INTO `permissions` VALUES (268, '反馈管理', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (269, '反馈列表', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (270, '快捷回复', 'feedback.quickreplytype', NULL, 'feedback', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (271, '玩家禁言', 'feedback.bansay', NULL, 'feedback', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (272, '添加版本', 'version.view', NULL, 'version', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (273, '框架版本', 'version.frame', NULL, 'version', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (274, '大厅版本', 'version.hall', NULL, 'version', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (275, '游戏版本', 'version.game', NULL, 'version', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (276, '客户端配置', 'client.index', NULL, 'client', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (277, '创建配置', 'client.viewconfig', NULL, 'client', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (278, '配置列表', 'client.listconfig', NULL, 'client', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (279, '模版列表', 'client.template', NULL, 'client', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (280, '创建模板', 'client.templatecreate', NULL, 'client', 0, '2019-08-16 21:12:38', '2019-08-16 21:12:38');
INSERT INTO `permissions` VALUES (281, '导入模板', 'client.templateconfigcreate', NULL, 'client', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (282, '税收配置', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (283, '客服提现管理', 'cash.customer', NULL, 'cash', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (284, '充值列表', 'rechargeorder.index', NULL, 'rechargeorder', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (285, '渠道商管理', 'distribution.index', NULL, 'distribution', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (286, '玩家列表', 'account.index', NULL, 'account', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (287, '星级关注', 'account.riskstar', NULL, 'account', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (288, '登陆日志', 'account.loglogin', NULL, 'account', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (289, '游戏配置', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (290, '配置首页', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (291, 'IP封禁列表', 'fengblack.fengip', NULL, 'fengBlack', 0, '2019-08-16 21:12:39', '2019-08-16 21:12:39');
INSERT INTO `permissions` VALUES (292, '玩家管理', 'account.index', NULL, 'account', 0, '2019-08-16 21:13:16', '2019-08-16 21:13:16');
INSERT INTO `permissions` VALUES (293, '系统管理', 'index.index', NULL, 'index', 0, '2019-08-16 21:13:16', '2019-08-16 21:13:16');
INSERT INTO `permissions` VALUES (294, '用户列表', 'users.index', NULL, 'users', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (295, '角色管理', 'roles.index', NULL, 'roles', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (296, '权限管理', 'permissions.index', NULL, 'permissions', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (297, '版本管理', 'version.view', NULL, 'version', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (298, '房间管理', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (299, '提现管理', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (300, '提现列表', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (301, '风控列表', 'cash.risk', NULL, 'cash', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (302, '风控比例', 'cash.risksystem', NULL, 'cash', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (303, '服务器列表', 'cash.servers', NULL, 'cash', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (304, '支付宝黑名单', 'cash.aliaccount', NULL, 'cash', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (305, '通知管理', 'notice.index', NULL, 'notice', 0, '2019-08-16 21:13:17', '2019-08-16 21:13:17');
INSERT INTO `permissions` VALUES (306, '通知列表', 'notice.system', NULL, 'notice', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (307, '私信列表', 'notice.specify', NULL, 'notice', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (308, '短信列表', 'notice.sms', NULL, 'notice', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (309, '反馈管理', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (310, '反馈列表', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (311, '快捷回复', 'feedback.quickreplytype', NULL, 'feedback', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (312, '玩家禁言', 'feedback.bansay', NULL, 'feedback', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (313, '添加版本', 'version.view', NULL, 'version', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (314, '框架版本', 'version.frame', NULL, 'version', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (315, '大厅版本', 'version.hall', NULL, 'version', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (316, '游戏版本', 'version.game', NULL, 'version', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (317, '客户端配置', 'client.index', NULL, 'client', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (318, '创建配置', 'client.viewconfig', NULL, 'client', 0, '2019-08-16 21:13:18', '2019-08-16 21:13:18');
INSERT INTO `permissions` VALUES (319, '配置列表', 'client.listconfig', NULL, 'client', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (320, '模版列表', 'client.template', NULL, 'client', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (321, '创建模板', 'client.templatecreate', NULL, 'client', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (322, '导入模板', 'client.templateconfigcreate', NULL, 'client', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (323, '税收配置', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (324, '客服提现管理', 'cash.customer', NULL, 'cash', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (325, '充值列表', 'rechargeorder.index', NULL, 'rechargeorder', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (326, '渠道商管理', 'distribution.index', NULL, 'distribution', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (327, '玩家列表', 'account.index', NULL, 'account', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (328, '星级关注', 'account.riskstar', NULL, 'account', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (329, '登陆日志', 'account.loglogin', NULL, 'account', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (330, '游戏配置', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:13:19', '2019-08-16 21:13:19');
INSERT INTO `permissions` VALUES (331, '配置首页', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:13:20', '2019-08-16 21:13:20');
INSERT INTO `permissions` VALUES (332, 'IP封禁列表', 'fengblack.fengip', NULL, 'fengBlack', 0, '2019-08-16 21:13:20', '2019-08-16 21:13:20');
INSERT INTO `permissions` VALUES (333, '玩家管理', 'account.index', NULL, 'account', 0, '2019-08-16 21:13:26', '2019-08-16 21:13:26');
INSERT INTO `permissions` VALUES (334, '系统管理', 'index.index', NULL, 'index', 0, '2019-08-16 21:13:26', '2019-08-16 21:13:26');
INSERT INTO `permissions` VALUES (335, '用户列表', 'users.index', NULL, 'users', 0, '2019-08-16 21:13:26', '2019-08-16 21:13:26');
INSERT INTO `permissions` VALUES (336, '角色管理', 'roles.index', NULL, 'roles', 0, '2019-08-16 21:13:26', '2019-08-16 21:13:26');
INSERT INTO `permissions` VALUES (337, '权限管理', 'permissions.index', NULL, 'permissions', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (338, '版本管理', 'version.view', NULL, 'version', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (339, '房间管理', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (340, '提现管理', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (341, '提现列表', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (342, '风控列表', 'cash.risk', NULL, 'cash', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (343, '风控比例', 'cash.risksystem', NULL, 'cash', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (344, '服务器列表', 'cash.servers', NULL, 'cash', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (345, '支付宝黑名单', 'cash.aliaccount', NULL, 'cash', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (346, '通知管理', 'notice.index', NULL, 'notice', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (347, '通知列表', 'notice.system', NULL, 'notice', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (348, '私信列表', 'notice.specify', NULL, 'notice', 0, '2019-08-16 21:13:27', '2019-08-16 21:13:27');
INSERT INTO `permissions` VALUES (349, '短信列表', 'notice.sms', NULL, 'notice', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (350, '反馈管理', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (351, '反馈列表', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (352, '快捷回复', 'feedback.quickreplytype', NULL, 'feedback', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (353, '玩家禁言', 'feedback.bansay', NULL, 'feedback', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (354, '添加版本', 'version.view', NULL, 'version', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (355, '框架版本', 'version.frame', NULL, 'version', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (356, '大厅版本', 'version.hall', NULL, 'version', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (357, '游戏版本', 'version.game', NULL, 'version', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (358, '客户端配置', 'client.index', NULL, 'client', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (359, '创建配置', 'client.viewconfig', NULL, 'client', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (360, '配置列表', 'client.listconfig', NULL, 'client', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (361, '模版列表', 'client.template', NULL, 'client', 0, '2019-08-16 21:13:28', '2019-08-16 21:13:28');
INSERT INTO `permissions` VALUES (362, '创建模板', 'client.templatecreate', NULL, 'client', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (363, '导入模板', 'client.templateconfigcreate', NULL, 'client', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (364, '税收配置', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (365, '客服提现管理', 'cash.customer', NULL, 'cash', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (366, '充值列表', 'rechargeorder.index', NULL, 'rechargeorder', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (367, '渠道商管理', 'distribution.index', NULL, 'distribution', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (368, '玩家列表', 'account.index', NULL, 'account', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (369, '星级关注', 'account.riskstar', NULL, 'account', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (370, '登陆日志', 'account.loglogin', NULL, 'account', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (371, '游戏配置', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (372, '配置首页', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (373, 'IP封禁列表', 'fengblack.fengip', NULL, 'fengBlack', 0, '2019-08-16 21:13:29', '2019-08-16 21:13:29');
INSERT INTO `permissions` VALUES (374, '玩家管理', 'account.index', NULL, 'account', 0, '2019-08-16 21:14:15', '2019-08-16 21:14:15');
INSERT INTO `permissions` VALUES (375, '系统管理', 'index.index', NULL, 'index', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (376, '用户列表', 'users.index', NULL, 'users', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (377, '角色管理', 'roles.index', NULL, 'roles', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (378, '权限管理', 'permissions.index', NULL, 'permissions', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (379, '版本管理', 'version.view', NULL, 'version', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (380, '房间管理', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (381, '提现管理', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (382, '提现列表', 'cash.index', NULL, 'cash', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (383, '风控列表', 'cash.risk', NULL, 'cash', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (384, '风控比例', 'cash.risksystem', NULL, 'cash', 0, '2019-08-16 21:14:16', '2019-08-16 21:14:16');
INSERT INTO `permissions` VALUES (385, '服务器列表', 'cash.servers', NULL, 'cash', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (386, '支付宝黑名单', 'cash.aliaccount', NULL, 'cash', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (387, '通知管理', 'notice.index', NULL, 'notice', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (388, '通知列表', 'notice.system', NULL, 'notice', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (389, '私信列表', 'notice.specify', NULL, 'notice', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (390, '短信列表', 'notice.sms', NULL, 'notice', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (391, '反馈管理', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (392, '反馈列表', 'feedback.index', NULL, 'feedback', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (393, '快捷回复', 'feedback.quickreplytype', NULL, 'feedback', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (394, '玩家禁言', 'feedback.bansay', NULL, 'feedback', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (395, '添加版本', 'version.view', NULL, 'version', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (396, '框架版本', 'version.frame', NULL, 'version', 0, '2019-08-16 21:14:17', '2019-08-16 21:14:17');
INSERT INTO `permissions` VALUES (397, '大厅版本', 'version.hall', NULL, 'version', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (398, '游戏版本', 'version.game', NULL, 'version', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (399, '客户端配置', 'client.index', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (400, '创建配置', 'client.viewconfig', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (401, '配置列表', 'client.listconfig', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (402, '模版列表', 'client.template', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (403, '创建模板', 'client.templatecreate', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (404, '导入模板', 'client.templateconfigcreate', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (405, '税收配置', 'client.gametax', NULL, 'client', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (406, '客服提现管理', 'cash.customer', NULL, 'cash', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (407, '充值列表', 'rechargeorder.index', NULL, 'rechargeorder', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (408, '渠道商管理', 'distribution.index', NULL, 'distribution', 0, '2019-08-16 21:14:18', '2019-08-16 21:14:18');
INSERT INTO `permissions` VALUES (409, '玩家列表', 'account.index', NULL, 'account', 0, '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES (410, '星级关注', 'account.riskstar', NULL, 'account', 0, '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES (411, '登陆日志', 'account.loglogin', NULL, 'account', 0, '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES (412, '游戏配置', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES (413, '配置首页', 'gameconfig.index', NULL, 'gameConfig', 0, '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES (414, 'IP封禁列表', 'fengblack.fengip', NULL, 'fengBlack', 0, '2019-08-16 21:14:19', '2019-08-16 21:14:19');
INSERT INTO `permissions` VALUES (415, '牌局记录', 'record.board', '查看牌局记录', 'record', 0, '2019-08-21 23:21:51', '2019-08-22 00:16:10');
COMMIT;

-- ----------------------------
-- Table structure for plant_statistics
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics`;
CREATE TABLE `plant_statistics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_sum` int(11) DEFAULT NULL,
  `order_count` int(11) DEFAULT NULL,
  `order_fail_sum` int(11) DEFAULT NULL,
  `order_fail_count` int(11) DEFAULT NULL,
  `order_success_sum` int(11) DEFAULT NULL,
  `order_success_user` int(11) DEFAULT NULL,
  `order_success_count` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for plant_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics_detail`;
CREATE TABLE `plant_statistics_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_sum` int(11) DEFAULT NULL,
  `order_count` int(11) DEFAULT NULL,
  `order_fail_sum` int(11) DEFAULT NULL,
  `order_fail_count` int(11) DEFAULT NULL,
  `order_success_sum` int(11) DEFAULT NULL,
  `order_success_user` int(11) DEFAULT NULL,
  `order_success_count` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for promoter_own_ips
-- ----------------------------
DROP TABLE IF EXISTS `promoter_own_ips`;
CREATE TABLE `promoter_own_ips` (
  `bag_id` varchar(255) NOT NULL COMMENT '渠道包ID',
  `ip` char(15) NOT NULL COMMENT 'ip(如果在该表有查不到的IP，那么推广员ID为0，即默认推广员)',
  `promoter_id` int(11) NOT NULL COMMENT '推广员ID(也是guid)',
  `uptime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`bag_id`,`ip`) USING BTREE,
  KEY `idx_ip_bag_id` (`ip`,`bag_id`) USING BTREE,
  KEY `idx_promoter_id` (`promoter_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for quick_reply_type
-- ----------------------------
DROP TABLE IF EXISTS `quick_reply_type`;
CREATE TABLE `quick_reply_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of quick_reply_type
-- ----------------------------
BEGIN;
INSERT INTO `quick_reply_type` VALUES (5, 1, NULL, NULL, '测试');
COMMIT;

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `created_at` varchar(255) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of role_user
-- ----------------------------
BEGIN;
INSERT INTO `role_user` VALUES (2, 1, 4, '2019-08-16 21:17:16', NULL);
INSERT INTO `role_user` VALUES (3, 2, 5, '2019-08-16 22:02:43', '2019-08-17 16:15:26');
INSERT INTO `role_user` VALUES (4, 3, 5, '2019-08-16 23:58:51', NULL);
COMMIT;

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id` int(11) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `level` int(255) DEFAULT NULL COMMENT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of roles
-- ----------------------------
BEGIN;
INSERT INTO `roles` VALUES (00000000004, 'admin', 'admin', '测试', 0, '2019-08-16 21:14:13', '2019-08-21 23:23:03');
INSERT INTO `roles` VALUES (00000000005, 'admin1', 'admin1', 'admin1', 0, '2019-08-16 23:44:34', '2019-08-17 00:00:38');
COMMIT;

-- ----------------------------
-- Table structure for sms
-- ----------------------------
DROP TABLE IF EXISTS `sms`;
CREATE TABLE `sms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone` varchar(11) DEFAULT NULL COMMENT '发送手机号',
  `content` varchar(255) DEFAULT NULL COMMENT '发送内容',
  `status` varchar(255) DEFAULT NULL COMMENT '状态',
  `return` varchar(255) DEFAULT NULL COMMENT '返回值',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_account
-- ----------------------------
DROP TABLE IF EXISTS `t_account`;
CREATE TABLE `t_account` (
  `guid` int(8) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `account` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '账号',
  `password` varchar(32) CHARACTER SET utf8 DEFAULT NULL COMMENT '密码',
  `is_guest` int(11) NOT NULL DEFAULT '0' COMMENT '是否是游客 1是游客',
  `nickname` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '昵称',
  `head_url` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '头像',
  `openid` char(60) CHARACTER SET utf8 DEFAULT '' COMMENT 'openid',
  `enable_transfer` int(11) NOT NULL DEFAULT '0' COMMENT '1能够转账，0不能给其他玩家转账',
  `bank_password` varchar(32) CHARACTER SET utf8 DEFAULT NULL COMMENT '银行密码',
  `vip` int(11) NOT NULL DEFAULT '0' COMMENT 'vip等级',
  `alipay_name` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '加了星号的支付宝姓名',
  `alipay_name_y` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '支付宝姓名',
  `alipay_account` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '加了星号的支付宝账号',
  `alipay_account_y` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '支付宝账号',
  `bang_alipay_time` timestamp NULL DEFAULT NULL COMMENT '支付宝绑时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `register_time` timestamp NULL DEFAULT NULL COMMENT '注册时间',
  `login_time` timestamp NULL DEFAULT NULL COMMENT '登陆时间',
  `logout_time` timestamp NULL DEFAULT NULL COMMENT '退出时间',
  `online_time` int(11) DEFAULT '0' COMMENT '累计在线时间',
  `login_count` int(11) DEFAULT '1' COMMENT '登录次数',
  `phone` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '手机名字：ios，android',
  `phone_type` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '手机具体型号',
  `version` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '版本号',
  `channel_id` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '渠道号',
  `package_name` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '安装包名字',
  `imei` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '设备唯一码',
  `ip` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '客户端ip',
  `last_login_phone` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录手机名字：ios，android',
  `last_login_phone_type` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录手机具体型号',
  `last_login_version` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录版本号',
  `last_login_channel_id` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录渠道号',
  `last_login_package_name` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录安装包名字',
  `last_login_imei` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录设备唯一码',
  `last_login_ip` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '最后登录IP',
  `change_alipay_num` int(11) DEFAULT '6' COMMENT '允许修改支付宝账号次数',
  `disabled` tinyint(4) DEFAULT '0' COMMENT '0启用  1禁用',
  `risk` tinyint(4) DEFAULT '0' COMMENT '危险等级0-9  9最危险',
  `recharge_count` bigint(20) DEFAULT '0' COMMENT '总充值金额',
  `cash_count` bigint(20) DEFAULT '0' COMMENT '总提现金额',
  `inviter_guid` int(11) DEFAULT '0' COMMENT '邀请人的id',
  `invite_code` varchar(32) CHARACTER SET utf8 DEFAULT '0' COMMENT '邀请码',
  `platform_id` varchar(256) CHARACTER SET utf8 DEFAULT '0' COMMENT '平台id',
  `proxy_money` bigint(20) DEFAULT '0' COMMENT '代理充值累计金额',
  `bank_card_name` varchar(64) CHARACTER SET utf8 DEFAULT '**' COMMENT '银行卡姓名',
  `bank_card_num` varchar(64) CHARACTER SET utf8 DEFAULT '**' COMMENT '银行卡号',
  `change_bankcard_num` int(11) DEFAULT '6' COMMENT '允许修改银行卡号次数',
  `which_bank` int(11) DEFAULT '0' COMMENT '所属银行',
  `band_bankcard_time` timestamp NULL DEFAULT NULL COMMENT '银行卡绑定时间',
  `seniorpromoter` int(11) NOT NULL DEFAULT '0' COMMENT '所属推广员guid',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '默认值：0,1:线上推广员,2:线下推广员',
  `level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '默认值:0,待激活:99,1-5一到五级推广员',
  `promoter_time` timestamp NULL DEFAULT NULL COMMENT '成为推广员时间',
  `shared_id` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '共享设备码',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=124522 DEFAULT CHARSET=utf8mb4 COMMENT='账号表';

-- ----------------------------
-- Records of t_account
-- ----------------------------
BEGIN;
INSERT INTO `t_account` VALUES (100002, 'oi09jv5EPTMqCNV4S4T7zSK7dxeY', NULL, 0, '小咲QAQ', 'http://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83eqCJWibGZ3n8PRnmds0ibZKAibrBPnqbcAvfgeWaDwRnJ9C0biaicNjicGwb9neqfUzKKBbffqhvceKg5fA/132', 'oi09jv5EPTMqCNV4S4T7zSK7dxeY', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-15 17:57:46', '2020-05-15 17:57:46', '2020-06-02 13:12:34', '2020-06-02 13:12:36', 4647062, 56, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '118.113.135.37', '', 'Android', '1.4.61', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100003, 'oi09jv4fBKG3c2VVswBviXk30r28', NULL, 0, '......', 'http://thirdwx.qlogo.cn/mmopen/vi_32/AXLO2MHYamhQ2SiaNtNnkOtXmgh1fSfLfWDrKnt5msl2RJsHJskkmcf7ibgFurDvYafvOPZ7SibuVliauwU5riaX9mg/132', 'oi09jv4fBKG3c2VVswBviXk30r28', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-15 18:03:11', '2020-05-15 18:03:11', '2020-05-31 13:28:15', '2020-05-31 13:29:17', 15573152, 32, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '118.113.135.37', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100004, 'oi09jv73hGfMtEu1eOEMa2Q_0FlQ', NULL, 0, '神净讨魔', 'http://thirdwx.qlogo.cn/mmopen/vi_32/PiajxSqBRaEJbytqc5zicmA1lkVmO7k64uJJgADSEhPEjicNZ6kmtf4vIlMVX1rEp2TkLv16x310ILzdwo4ibd3BgQ/132', 'oi09jv73hGfMtEu1eOEMa2Q_0FlQ', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-15 18:08:39', '2020-05-15 18:08:39', '2020-05-15 19:01:45', '2020-05-22 18:26:02', 5214660, 16, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '118.113.135.37', '', 'Android', '1.4.59', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100005, 'oi09jvywAota9LaJaCCgv6rVPz08', NULL, 0, '源源不断的圆', 'http://thirdwx.qlogo.cn/mmopen/vi_32/FES6APrrkR4HlPDASs3CFeFRTZsHz6ViaQNliaORspVIAqO2csJFw3OYVwb76Gyjbksq54scUGQDmH2miaaSibibJDw/132', 'oi09jvywAota9LaJaCCgv6rVPz08', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-15 18:11:36', '2020-05-15 18:11:36', '2020-05-25 16:28:13', '2020-05-27 14:51:31', 1208211, 10, NULL, 'Ios', '1.4.59', NULL, 'gzmj', NULL, '118.113.135.37', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100006, 'oi09jv5hBl9_-PPLQJBsUV8awwdE', NULL, 0, '罗艺&互联网&游戏', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTJGCjMHxibsI7uoD5zbVqrciaAzeIcy3Xj0CLicOcLeocvBu9H4l3YicNUyToNJF2XdHZXbk0ZkssDTFw/132', 'oi09jv5hBl9_-PPLQJBsUV8awwdE', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-19 03:37:58', '2020-05-19 03:37:58', '2020-05-19 03:47:29', '2020-05-19 03:48:13', 631, 5, NULL, 'Ios', '1.4.59', NULL, 'gzmj', NULL, '182.148.13.147', '', 'Ios', '1.4.59', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100007, 'oi09jvydMN-0wYRV1snwMXEoYgIc', NULL, 0, '平儿4134    教您自己调百病', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTIwZLMettqia5WJfxOQFSKiaYuAuhYIvGzssURAiaZhgsMgqO4PUdQtibNqwMJL3LJ5Vu3lAAUlmGLUcw/132', 'oi09jvydMN-0wYRV1snwMXEoYgIc', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-20 21:39:56', '2020-05-20 21:39:56', '2020-05-20 21:39:56', '2020-05-21 13:15:52', 56193, 3, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '117.136.4.187', '', 'Android', '1.4.59', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100008, 'oi09jvwfvVWnherWQRDMCIwGhp-Q', NULL, 0, '豹子头、零充', 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTIDeujlOxcicMK2icU36or5U3cATibzaZJuaP2giaYXCGndsg1T4hibCUGjiaZ89otK5IFKdkrJgsjib5Zibg/132', 'oi09jvwfvVWnherWQRDMCIwGhp-Q', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-20 22:34:58', '2020-05-20 22:34:58', '2020-05-20 22:34:58', '2020-05-31 18:14:34', 3815712, 25, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '218.26.55.87', '', 'Android', '1.4.59', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (100009, 'oi09jvyllXcnrZOTBqDkdVB0iKw0', NULL, 0, '费费', 'http://thirdwx.qlogo.cn/mmopen/vi_32/mXjxRicmKncbODXoUHdEiaiaxQmBMH4mkcdoiabGJrg0A0d4OPdlTLibAYT0nf0Z6ibM2icYgAwrialdcJDFibdJ6bW30Ag/132', 'oi09jvyllXcnrZOTBqDkdVB0iKw0', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-21 16:28:29', '2020-05-21 16:28:29', '2020-05-21 16:28:29', '2020-05-29 13:49:02', 1131764, 17, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '171.221.129.225', '', 'Android', '1.4.59', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124483, 'oi09jv4EBEWJesq4m35kx-Yml_J0', NULL, 0, '宋二胡', 'http://thirdwx.qlogo.cn/mmopen/vi_32/6xPbQ8o3TswQiaXgiaqeq7V3psNj2EkH3YTMvHU095ibRqs5ZEzYQG7QzZdKILz0PbcD9XBMSfeOvHc5urTWO4ticg/132', 'oi09jv4EBEWJesq4m35kx-Yml_J0', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-22 10:54:21', '2020-05-22 10:54:21', '2020-05-22 10:54:21', '2020-05-22 10:58:09', 357, 5, NULL, 'Android', '1.4.59', NULL, 'gzmj', NULL, '223.104.197.212', '', 'Android', '1.4.59', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124484, 'oi09jv4SljwIh0hI4QHFD44UFYns', NULL, 0, '还好', 'http://thirdwx.qlogo.cn/mmopen/vi_32/suRycuEh9liaZfqjZ3gUmTnStt0s7EMyTQxS2GT21TzFZMRKh1ZJlmUWSQVv5CwKft2QfmSibqcP8l5R0vNkJUkg/132', 'oi09jv4SljwIh0hI4QHFD44UFYns', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-22 18:50:28', '2020-05-22 18:50:28', '2020-05-22 18:50:28', '2020-05-29 14:43:15', 718894, 5, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '171.221.129.225', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124485, 'oi09jv8pR2wYBCsfugNBlJNnGYTA', NULL, 0, 'A友闲喵喵', 'http://thirdwx.qlogo.cn/mmopen/vi_32/wq6RVDiaICJvWEgcibtnNLG7a4TtwTuaAQkLfick4EVQrFyzibFPsMy2Hsw9k3ic7Hvsjicw5A4BNUkKSufEVibX2dksA/132', 'oi09jv8pR2wYBCsfugNBlJNnGYTA', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-23 09:59:34', '2020-05-23 09:59:34', '2020-05-23 10:11:04', '2020-05-23 20:26:41', 191939, 17, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '171.221.129.225', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124486, 'oi09jv33mDX5Z2dZH7NhleEit2WA', NULL, 0, '心寒', 'http://thirdwx.qlogo.cn/mmopen/vi_32/nqnft3b1rdqiaSBRzic1sDsBd9uWlECnexPdFDic52yEJicTqSv7tLLhP0fqr7k6l1FPK2axvyVKxDh5hj5cWdan0Q/132', 'oi09jv33mDX5Z2dZH7NhleEit2WA', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-24 18:32:06', '2020-05-24 18:32:06', '2020-05-24 18:32:06', '2020-05-25 14:37:04', 72398, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '124.164.37.148', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124487, 'oi09jv8z_GDojE_ejzkfhYAfLx4g', NULL, 0, '大江', 'http://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83epGSrV5olX0T17jibeqhKZFMUN6Ff4gt4A5eQlHOKJibNcuTyscrPn8ic13YfRSv2gBK83z4w4NTAIUw/132', 'oi09jv8z_GDojE_ejzkfhYAfLx4g', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-25 18:01:12', '2020-05-25 18:01:12', '2020-05-25 18:01:12', '2020-05-25 18:01:24', 12, 2, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '112.101.249.241', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124488, 'oi09jvxCuf4aexcsooyRPwUeqews', NULL, 0, '', 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTKnXqrCwxoUGshicwWVOvq2G2Mp7YSyia6cnS37B3MBUEAL8Yz8tlGhqxFVlpmrgNPxdookWeE8jxew/132', 'oi09jvxCuf4aexcsooyRPwUeqews', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-25 22:40:16', '2020-05-25 22:40:16', '2020-05-25 22:40:16', '2020-05-25 22:42:07', 176, 4, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '223.104.197.5', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124489, 'oi09jv2rTPjIm3xqmgf-Vp5mhhNg', NULL, 0, '不喇叭', 'http://thirdwx.qlogo.cn/mmopen/vi_32/gWve9qJ3eqzDZEJGDaJFt1FA4ceZXjSLXzl2DWWfGw70qnibNUfDfjHS7xj4eR2UvxcibEBuX9rkdib52P3odRbqA/132', 'oi09jv2rTPjIm3xqmgf-Vp5mhhNg', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-26 10:31:25', '2020-05-26 10:31:25', '2020-05-26 10:31:25', '2020-05-26 10:42:51', 1757, 6, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '202.186.172.244', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124490, 'oi09jv1bFLE0naBQov6hTTeEDK70', NULL, 0, 'AAA熊猫金库', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ORJaR9vwpaJrhJJSIMbV8UPMU9icXgiaIvCBia6zxZvPO7JOVJBXrHrN2GeLG2cXSsaRwj7wZsB2bpNyw6e7S4rew/132', 'oi09jv1bFLE0naBQov6hTTeEDK70', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-26 10:41:09', '2020-05-26 10:41:09', '2020-05-26 10:41:09', '2020-05-26 10:41:53', 44, 2, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '183.223.254.12', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124491, 'oi09jv2zdod__m_Jyy4liGD6yKM0', NULL, 0, '阿郎', 'http://thirdwx.qlogo.cn/mmopen/vi_32/rYPM1MkTJ32icFB9Xpj0Ux9ErlFn4pSWQZqLgGicAkHZPERALtL5MC2W6u19ZkshgWFI1Mp73Hs3iaUkXwEOrEA0g/132', 'oi09jv2zdod__m_Jyy4liGD6yKM0', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-26 18:22:29', '2020-05-26 18:22:29', '2020-05-26 18:22:29', '2020-05-26 18:37:53', 6452, 12, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '101.206.170.103', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124492, 'oi09jv6rH0euWtgTJeZBA8YouhkY', NULL, 0, '小角色', 'http://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83erZSzAbWpicMjMRz0cRxdiaPQgcTTM4IN5piadjrkZfLzuge3sKbh0WBEbKlCZibguKKGbOXicHicYBRibWw/132', 'oi09jv6rH0euWtgTJeZBA8YouhkY', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-27 12:23:04', '2020-05-27 12:23:04', '2020-05-27 12:23:04', '2020-05-27 19:34:32', 51891, 6, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '218.26.55.102', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124493, 'oi09jv41jucLjkfOuYEnirhUd6fg', NULL, 0, '刘朋', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTKDYj9IQXhWOh0IX8VOltcIV94OmqJ13kQ4gNQBV0I6iaLJye8h9aWDZAQwqicHUibibUicVceCeiaEXDTw/132', 'oi09jv41jucLjkfOuYEnirhUd6fg', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-27 22:37:56', '2020-05-27 22:37:56', '2020-05-27 22:37:56', '2020-05-27 22:52:00', 1206, 5, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '218.26.54.245', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124494, 'oi09jv-MKp6EdMQPUv2fMNyJJhn8', NULL, 0, '赵海东', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTLUoMalkP03Glot6gpFNOFrykhRiccjA6aPCtbj4pqsnzE3vUBd3MFvtmrfMpQHiabrzxpPYhLZMDdQ/132', 'oi09jv-MKp6EdMQPUv2fMNyJJhn8', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-28 20:00:36', '2020-05-28 20:00:36', '2020-05-28 20:00:36', '2020-05-28 20:00:51', 26, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '60.220.238.139', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124495, 'oi09jv8R9vZHtQilRYUlHJAY3L2E', NULL, 0, '...', 'http://thirdwx.qlogo.cn/mmopen/vi_32/QouKUlZzB3r19nZUjWeBMba3dBg8XXeurorUc1RtXib7oOtRYmD4JJcry5UicsD5n4sCWW0ppN92bk4ZmLKlcllA/132', 'oi09jv8R9vZHtQilRYUlHJAY3L2E', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-28 20:52:44', '2020-05-28 20:52:44', '2020-05-28 20:52:44', '2020-05-28 20:53:25', 41, 2, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '171.117.22.59', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124496, 'oi09jvyOArNYLczktGQAANBPtFpA', NULL, 0, '二凯', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTLDMEGhjbUnMCMCkSvnia1aib9G4wk8Z0OxfrOGrG7KQ0SaK3OkZeeVqzjwRQL0oa0DPib5WbjqszUcQ/132', 'oi09jvyOArNYLczktGQAANBPtFpA', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-28 22:14:38', '2020-05-28 22:14:38', '2020-05-28 22:14:38', '2020-05-28 22:19:49', 395, 5, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '117.136.91.228', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124497, 'oi09jvyHN02VX-4V-Eo3mJga4ivM', NULL, 0, '启辰@加油', 'http://thirdwx.qlogo.cn/mmopen/vi_32/R9JHfb2MI5jRp31d5MVetWwfb70w1JXcgfGs7X5zFV6NrxaEM6xDJrLzFZhnrUrCLjWtLtjJ8ibnBibIezGIFDgg/132', 'oi09jvyHN02VX-4V-Eo3mJga4ivM', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-29 13:13:49', '2020-05-29 13:13:49', '2020-05-29 13:13:49', '2020-05-29 13:14:01', 12, 2, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '117.136.4.96', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124498, 'oi09jv8YR3YJMN_H5lOC1u_TWWcU', NULL, 0, '八零飛', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTI51cu6AvvQV2pIUBveCT5kicMlTCyjgsMCOCZZSdnrHnNiam7qicwnqkTfUS4JCtTc7WrrrLpdeFSmg/132', 'oi09jv8YR3YJMN_H5lOC1u_TWWcU', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-29 13:34:42', '2020-05-29 13:34:42', '2020-05-29 13:34:42', '2020-05-29 13:36:02', 89, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '117.136.4.67', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124499, 'oi09jv8oggbrNY6cBQzWw-MZLS4g', NULL, 0, '平儿', 'http://thirdwx.qlogo.cn/mmopen/vi_32/tjHqSRko78RP9RfOJuTiaA62Kic4JDtIweYqf8hbkM9RrHyMVpcLXR6btUG2UUfyJ00b5LBrBGTd2pwtr2kqHKTg/132', 'oi09jv8oggbrNY6cBQzWw-MZLS4g', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-29 13:44:11', '2020-05-29 13:44:11', '2020-05-29 13:44:11', '2020-05-29 13:53:21', 650, 4, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '223.104.197.141', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124500, 'oi09jv8acMcdr8U0E6wXEE2wzxQU', NULL, 0, '你好', 'http://thirdwx.qlogo.cn/mmopen/vi_32/1ls9wYOvWHHAribQt43SpNBYnjgGPz23hqyZ4BA8TvaeesibMtsnGGdehTw22Q8zh8EE3ibOBPrAIQVhjglLCwHQw/132', 'oi09jv8acMcdr8U0E6wXEE2wzxQU', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-29 17:28:19', '2020-05-29 17:28:19', '2020-05-29 17:28:19', '2020-05-29 17:31:14', 197, 3, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '124.164.66.51', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124501, 'oi09jvyk57ZrzXfa2dkeQnDh8H8o', NULL, 0, '郭先生', 'http://thirdwx.qlogo.cn/mmopen/vi_32/IPBNdriaTRVFGZ5BicAjcpZ5aU9dtFr9uKCoXy0ab3D6icBUacfeDDcsWPicIG4SjWshanv9dxZ2uXhr3mUljtpjkA/132', 'oi09jvyk57ZrzXfa2dkeQnDh8H8o', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-29 22:15:16', '2020-05-29 22:15:16', '2020-05-29 22:15:16', '2020-05-29 22:16:52', 146, 4, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '117.136.4.78', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124502, 'oi09jv-DtWq92zbcsbDhEbDm4xYI', NULL, 0, '太平洋售后申纬洲', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTLmNlrYPEF0wFmd2OJayeCBbB2Woia6ibeMaKpzQJ63FX6up5OvYicJsMht7NA9JEzhLrFzxWN2jU4Qg/132', 'oi09jv-DtWq92zbcsbDhEbDm4xYI', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-30 16:27:27', '2020-05-30 16:27:27', '2020-05-30 16:27:27', '2020-05-30 16:27:44', 17, 2, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '223.104.197.224', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124503, 'oi09jv2j6Es3plnARLUTMpRFRqt4', NULL, 0, '暖阳下', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Uu5UgEkp1w2NH5QicyDwUFxGnKUOnEfHAVH5IFBzjdjI2HBKAf9ib3740DM9iasAIdcNvhanTdHkIfmx4lsMMGxwg/132', 'oi09jv2j6Es3plnARLUTMpRFRqt4', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-30 18:12:40', '2020-05-30 18:12:40', '2020-05-30 18:12:40', '2020-05-30 18:31:52', 1192, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '117.136.90.139', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124504, 'oi09jv_-DBOfhfr0UZtlBhJprm4g', NULL, 0, '愿得一人心，不愿去相亲', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTIY0OylgicaH6OrANBr1UJfib5rYJ7SGRrv300hZgNO7rrdfFHkGQiakuMoW3smAVgq2OU2YTXlwrLsQ/132', 'oi09jv_-DBOfhfr0UZtlBhJprm4g', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-30 18:32:23', '2020-05-30 18:32:23', '2020-05-30 18:32:23', '2020-05-30 18:32:38', 23, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '183.202.24.8', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124505, 'oi09jvxt9n8L9RKV0xwD3i3rBsF0', NULL, 0, '兲〃', 'http://thirdwx.qlogo.cn/mmopen/vi_32/lwUjqAFRa6mVUtCJwh4rAQF6u4pvyYviaegGSs4qVLm6Dsicibp7mYNQiaQQQIoH0rziart7FN6Nh0W7uOB5TGtKYyA/132', 'oi09jvxt9n8L9RKV0xwD3i3rBsF0', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-30 19:13:02', '2020-05-30 19:13:02', '2020-05-30 19:13:02', '2020-05-30 19:29:46', 1021, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '183.200.57.193', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124506, 'oi09jvzHXm372PNQl1NbnZhfppK4', NULL, 0, '幸福人生', 'http://thirdwx.qlogo.cn/mmopen/vi_32/7VMCppG7Q45jNRwF4GTt1gAuMq3O39MRVmMKgdszOfwNZmpmrppiarbDkQmHWgib0XZZGJ7COHbltOL7av5oq9gw/132', 'oi09jvzHXm372PNQl1NbnZhfppK4', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-30 23:04:32', '2020-05-30 23:04:32', '2020-05-30 23:04:32', '2020-05-31 00:17:19', 14437, 8, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '223.104.192.92', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124507, 'oi09jv7t28nHFtk4cWD-jlgQ8b0Q', NULL, 0, '王家乐', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTJa2C5FUP1yn9ewFxaucrLQiaYeoX4RYHK1vIYE5ZVEVib4cLWBQ1z6kWeGIzrMeE9WZ8ItI6tPRUDg/132', 'oi09jv7t28nHFtk4cWD-jlgQ8b0Q', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-31 11:00:30', '2020-05-31 11:00:30', '2020-05-31 11:00:30', '2020-05-31 13:00:34', 14349, 4, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '117.136.90.98', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124508, 'oi09jv0QwhGXnEg2a6Gb3MKI-H6I', NULL, 0, '时光荏苒', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTJLELZJibUBoicicFnmNYG0JL1DsSDJzyEava0uHm22MccUvVTr2FYtfhkrzJib0QB79HOFic49YlZkj8Q/132', 'oi09jv0QwhGXnEg2a6Gb3MKI-H6I', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-31 11:04:13', '2020-05-31 11:04:13', '2020-05-31 11:04:13', '2020-05-31 11:04:19', 6, 2, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '183.202.72.255', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124509, 'oi09jv-3YQUVqygMVEeBXJsFaTC0', NULL, 0, '迷迷糊糊', 'http://thirdwx.qlogo.cn/mmopen/vi_32/UeaZXP1mibibH45Lic4srhNIsRYXEniaYuqvrUD1RtMyqVXhZFoSTibzrvYSyKdV6m67NPsXFWibLEUY1RibCXe89Wzsg/132', 'oi09jv-3YQUVqygMVEeBXJsFaTC0', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-31 17:03:18', '2020-05-31 17:03:18', '2020-05-31 17:03:18', '2020-05-31 17:03:53', 40, 3, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '223.104.197.43', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124510, 'oi09jv4nujoKTNwCjZiFApBMLQ2Y', NULL, 0, '现实', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTJAEDER5XgbFibB9pd2kr6BKkXktiaStfLwyrZjkZiaZnr7S6C66Z8cNYpLnSfLJvl7qpia2mdSB73LrA/132', 'oi09jv4nujoKTNwCjZiFApBMLQ2Y', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-31 18:58:14', '2020-05-31 18:58:14', '2020-05-31 18:58:14', '2020-05-31 18:58:39', 34, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '112.224.2.241', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124511, 'oi09jv0x5ELDT43jMUQiVLo74I5Y', NULL, 0, '落日', 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTIFMicib2CVhQBlvh5iaVrQxruI3YnDUScKL2xq3A9KgxfgkvuicKDu0xIuDLxphibKLibnrdZxOrPYarQA/132', 'oi09jv0x5ELDT43jMUQiVLo74I5Y', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-05-31 21:04:40', '2020-05-31 21:04:40', '2020-05-31 21:04:40', '2020-05-31 21:11:37', 1737, 9, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '1.68.110.1', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124512, 'oi09jv57eiGD-QM02ISZHxLQxyhk', NULL, 0, '三好先森', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTKMbB7doSjNovDnicohSvIc3icpyF9mOUX4EbEaIXfDjshIhvRGwaXw8adtJHEtXicXickYwmvJfjPQGA/132', 'oi09jv57eiGD-QM02ISZHxLQxyhk', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 11:16:59', '2020-06-01 11:16:59', '2020-06-01 11:16:59', '2020-06-01 11:24:05', 766, 6, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '223.104.197.41', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124513, 'oi09jv0JraJnj_Q0iIdM3MKWYrr0', NULL, 0, 'ST', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTLqWOPyTPysTdMZQkw2pibqdkm4ibP0o62NXk3XiccLNFbAzqoflUibTGmVhCETZXZ8O9fYjT85uqAEFw/132', 'oi09jv0JraJnj_Q0iIdM3MKWYrr0', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 14:17:17', '2020-06-01 14:17:17', '2020-06-01 14:17:17', '2020-06-01 14:18:06', 49, 2, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '223.104.147.37', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124514, 'oi09jvw2MEWG5FPV3Z8RKlUz5MGI', NULL, 0, '孤狼', 'http://thirdwx.qlogo.cn/mmopen/vi_32/4allw31a0bqgg45pQvzDTDaHa2n03CAllcRxv8jsZPUiaDDsyAwrNiac5KDWZ3Ju6GwibHIKTElmCU4paCN0TQjNA/132', 'oi09jvw2MEWG5FPV3Z8RKlUz5MGI', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 14:47:43', '2020-06-01 14:47:43', '2020-06-01 14:47:43', '2020-06-01 14:48:14', 31, 2, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '153.99.135.5', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124515, 'oi09jv-7lkDrRcE1HRnbYQz9um8I', NULL, 0, 'L-', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTIrwqXCejt9ZhtPxUrWOibicRwk0nLudjibx0Y7hvJy9eCrxsibeyibaI7dtoG2U4Y3XI0ZN9ib8kJNXn8Q/132', 'oi09jv-7lkDrRcE1HRnbYQz9um8I', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 16:23:06', '2020-06-01 16:23:06', '2020-06-01 16:23:05', '2020-06-01 16:23:45', 40, 2, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '118.73.128.236', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124516, 'oi09jv9eLOQxvr_oU8we5DHZxwXw', NULL, 0, 'A兜兜里没有糖', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTJOVrjicIjtZ2uBujXfic4eNDCJrA6yepSY1Iziby6yxdE6cfTBHERVGSibsWnHo60fO1R8TJEZOOE4LA/132', 'oi09jv9eLOQxvr_oU8we5DHZxwXw', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 16:48:12', '2020-06-01 16:48:12', '2020-06-01 16:48:12', '2020-06-01 16:48:21', 9, 2, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '118.76.183.13', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124517, 'oi09jvyKRd_djufdvWcUHGD5x2rA', NULL, 0, '靳.', 'http://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83erTibWKxNLFdPRhXkjCiawKsOanbqwh2ibQZAOM9kwLt44uzic92RONicBfDzUxEsUhdS2Pq4cWDRqxvfQ/132', 'oi09jvyKRd_djufdvWcUHGD5x2rA', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 16:54:00', '2020-06-01 16:54:00', '2020-06-01 16:54:00', '2020-06-01 16:55:20', 240, 6, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '117.136.90.79', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124518, 'oi09jv1rGzzToHpjfTthBbj_2ZEk', NULL, 0, '随便', 'http://thirdwx.qlogo.cn/mmopen/vi_32/LOj2uWOlbMo2XU93rRblqnKSYkeHcsbHEQ6OkZGEl9QYuFLyZfswXgRgTurFTebxBtvzZVJKUQKMYZHiatSkjIA/132', 'oi09jv1rGzzToHpjfTthBbj_2ZEk', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 17:15:23', '2020-06-01 17:15:23', '2020-06-01 17:15:23', '2020-06-01 17:17:05', 123, 3, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '49.90.43.175', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124519, 'oi09jv2KFwsq90n_JEarmtQP4AmM', NULL, 0, '但愿如此', 'http://thirdwx.qlogo.cn/mmopen/vi_32/9VE30oTuD4q5hia1mTJ7cJf47BnicsHHdYLiaicDAo6yp2JrhGKnYt7c0B63njOO7nWuZpkWNMia8k56xuXciaSqV4FQ/132', 'oi09jv2KFwsq90n_JEarmtQP4AmM', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 19:07:06', '2020-06-01 19:07:06', '2020-06-01 19:07:06', '2020-06-01 19:07:24', 18, 2, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '211.97.129.47', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124520, 'oi09jv9P2lwl-MUktCp6LkB0GFvI', NULL, 0, 'Nest', 'http://thirdwx.qlogo.cn/mmopen/vi_32/PiajxSqBRaEKoibod8bfkvZaXibnsTNHIK41ymIZ1SpwmN4W0VcHE5FrwPbz5mUpiazx903c9ZnG3XeQcv68bZNRPA/132', 'oi09jv9P2lwl-MUktCp6LkB0GFvI', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 19:16:08', '2020-06-01 19:16:08', '2020-06-01 19:16:08', '2020-06-01 19:17:10', 76, 3, NULL, 'Ios', '1.4.60', NULL, 'gzmj', NULL, '117.136.90.1', '', 'Ios', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (124521, 'oi09jv-ywkK1joxt2304rUXpb5Rc', NULL, 0, '对方正在输入', 'http://thirdwx.qlogo.cn/mmopen/vi_32/Q0j4TwGTfTJp0JzSialEHSINeA1LcGBcDpKZ6UE04vl4n1neXr9lwkny3p02Qkf3icPdWEGZGLlbdURkgtialGu2w/132', 'oi09jv-ywkK1joxt2304rUXpb5Rc', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-06-01 21:48:29', '2020-06-01 21:48:29', '2020-06-01 21:48:29', '2020-06-01 21:57:41', 2199, 9, NULL, 'Android', '1.4.60', NULL, 'gzmj', NULL, '223.11.219.157', '', 'Android', '1.4.60', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
COMMIT;

-- ----------------------------
-- Table structure for t_account_extend_info
-- ----------------------------
DROP TABLE IF EXISTS `t_account_extend_info`;
CREATE TABLE `t_account_extend_info` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `key` varchar(256) NOT NULL DEFAULT '' COMMENT '键',
  `value` varchar(1024) NOT NULL DEFAULT '' COMMENT '值',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_agent
-- ----------------------------
DROP TABLE IF EXISTS `t_agent`;
CREATE TABLE `t_agent` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '代理ID',
  `mobile` char(12) DEFAULT '' COMMENT '代理手机号码',
  `password` varchar(64) DEFAULT '' COMMENT '代理密码',
  `guid` int(10) DEFAULT '0' COMMENT '游戏ID',
  `nickname` char(15) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '昵称',
  `desc` varchar(255) DEFAULT '' COMMENT '备注',
  `type` tinyint(1) DEFAULT '1' COMMENT '类型 1代理员 2推广员',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态  1启用 2删除',
  `created_at` int(10) DEFAULT '0' COMMENT '添加时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=latin1 COMMENT='代理表';

-- ----------------------------
-- Records of t_agent
-- ----------------------------
BEGIN;
INSERT INTO `t_agent` VALUES (66, '17665036371', '$2y$10$G/zz8KKEDZYdRcnB.QSVFe9xHIqFu7/kf34eLZp29bFF1ecWWl1sW', 100002, '??QAQ', '', 1, 1, 1589537035);
INSERT INTO `t_agent` VALUES (67, '17683146641', '$2y$10$MlTAKHwkA9VBC69fRHzVmuBSkxxwPu0ahxnq8emZTu271qbCbsCYO', 100004, '神净讨魔', '', 1, 1, 1590057589);
INSERT INTO `t_agent` VALUES (68, '18583601564', '$2y$10$F7R9ZwFk4RRDkjQT51n33uJS4T850kZKe0/jzWp6Q6aBKRQTAaiEy', 124485, 'A友闲喵喵', '', 1, 1, 1590199802);
COMMIT;

-- ----------------------------
-- Table structure for t_channel_invite
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite`;
CREATE TABLE `t_channel_invite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` varchar(255) DEFAULT NULL COMMENT '渠道号',
  `channel_lock` tinyint(3) DEFAULT '0' COMMENT '1开启 0关闭',
  `big_lock` tinyint(3) DEFAULT '1' COMMENT '1开启 0关闭',
  `tax_rate` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '税率 百分比',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;
