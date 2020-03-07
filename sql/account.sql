/*
 Navicat MySQL Data Transfer

 Source Server         : localhost
 Source Server Type    : MySQL
 Source Server Version : 50728
 Source Host           : localhost:3306
 Source Schema         : account

 Target Server Type    : MySQL
 Target Server Version : 50728
 File Encoding         : 65001

 Date: 07/03/2020 17:06:07
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for black_alipay
-- ----------------------------
DROP TABLE IF EXISTS `black_alipay`;
CREATE TABLE `black_alipay`  (
  `alipay` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '支付宝账号(加黑将导致提现被挂起)',
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加黑的原因',
  `handler` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  PRIMARY KEY (`alipay`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for black_guid
-- ----------------------------
DROP TABLE IF EXISTS `black_guid`;
CREATE TABLE `black_guid`  (
  `guid` int(11) NOT NULL COMMENT 'guid(加黑将导致提现被挂起)',
  `phone` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联加黑的手机号，即account',
  `mac` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联加黑的imei',
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加黑的原因',
  `handler` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for cash_ali_account
-- ----------------------------
DROP TABLE IF EXISTS `cash_ali_account`;
CREATE TABLE `cash_ali_account`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ali_account` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `admin_account` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of cash_ali_account
-- ----------------------------
INSERT INTO `cash_ali_account` VALUES (1, 'rojmloj', '2019-08-15 00:14:26', '2019-08-15 00:14:26', 'admin@163.com');

-- ----------------------------
-- Table structure for feedback
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `processing_status` int(11) NULL DEFAULT NULL,
  `guid` int(11) NULL DEFAULT NULL,
  `reply_id` int(11) NULL DEFAULT NULL,
  `account` int(11) NULL DEFAULT NULL,
  `content` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  `is_readme` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  `author` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL,
  `processing_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for feng_guid
-- ----------------------------
DROP TABLE IF EXISTS `feng_guid`;
CREATE TABLE `feng_guid`  (
  `guid` int(11) NOT NULL COMMENT '要封掉的guid',
  `phone` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的手机号，即account',
  `mac` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的imei',
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封号的原因',
  `handler` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for feng_guid_copy
-- ----------------------------
DROP TABLE IF EXISTS `feng_guid_copy`;
CREATE TABLE `feng_guid_copy`  (
  `guid` int(11) NOT NULL COMMENT '要封掉的guid',
  `phone` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的手机号，即account',
  `mac` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的imei',
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封号的原因',
  `handler` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for feng_ip
-- ----------------------------
DROP TABLE IF EXISTS `feng_ip`;
CREATE TABLE `feng_ip`  (
  `ip` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '封掉的IP',
  `area` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '该IP所在的区域',
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封IP的原因',
  `handler` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  PRIMARY KEY (`ip`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for imei_update_fail_list
-- ----------------------------
DROP TABLE IF EXISTS `imei_update_fail_list`;
CREATE TABLE `imei_update_fail_list`  (
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `platform_id` smallint(6) NULL DEFAULT 0 COMMENT '平台id',
  `ip` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '客户端ip',
  `imei` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '准备更新的imei',
  `deprecated_imei` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '原imei 即guid 现在所对应的imei',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '创建时间',
  PRIMARY KEY (`guid`, `created_at`) USING BTREE,
  INDEX `index_imei`(`imei`) USING BTREE,
  INDEX `index_deprecated_imei`(`deprecated_imei`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for kill_guid
-- ----------------------------
DROP TABLE IF EXISTS `kill_guid`;
CREATE TABLE `kill_guid`  (
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `user` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '操作人',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`guid`) USING BTREE,
  INDEX `idx_created_at`(`created_at`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of kill_guid
-- ----------------------------
INSERT INTO `kill_guid` VALUES (21, 'admin@163.com', '2019-08-15 22:21:41');
INSERT INTO `kill_guid` VALUES (24, 'admin@163.com', '2019-08-15 11:16:58');

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `active` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `child` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `sort` int(10) NULL DEFAULT NULL,
  `slug` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `pid` int(11) NULL DEFAULT NULL,
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 45 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of menus
-- ----------------------------
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

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `permission_id` int(11) NULL DEFAULT NULL,
  `role_id` int(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 45 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
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

-- ----------------------------
-- Table structure for permission_user
-- ----------------------------
DROP TABLE IF EXISTS `permission_user`;
CREATE TABLE `permission_user`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NULL DEFAULT NULL,
  `permission_id` int(11) NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of permission_user
-- ----------------------------
INSERT INTO `permission_user` VALUES (1, 3, 409, '2019-08-16 23:58:51', NULL);

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `slug` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `model` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `level` int(10) NULL DEFAULT 0,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 416 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of permissions
-- ----------------------------
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

-- ----------------------------
-- Table structure for plant_statistics
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics`;
CREATE TABLE `plant_statistics`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_sum` int(11) NULL DEFAULT NULL,
  `order_count` int(11) NULL DEFAULT NULL,
  `order_fail_sum` int(11) NULL DEFAULT NULL,
  `order_fail_count` int(11) NULL DEFAULT NULL,
  `order_success_sum` int(11) NULL DEFAULT NULL,
  `order_success_user` int(11) NULL DEFAULT NULL,
  `order_success_count` int(11) NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for plant_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics_detail`;
CREATE TABLE `plant_statistics_detail`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_sum` int(11) NULL DEFAULT NULL,
  `order_count` int(11) NULL DEFAULT NULL,
  `order_fail_sum` int(11) NULL DEFAULT NULL,
  `order_fail_count` int(11) NULL DEFAULT NULL,
  `order_success_sum` int(11) NULL DEFAULT NULL,
  `order_success_user` int(11) NULL DEFAULT NULL,
  `order_success_count` int(11) NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for promoter_own_ips
-- ----------------------------
DROP TABLE IF EXISTS `promoter_own_ips`;
CREATE TABLE `promoter_own_ips`  (
  `bag_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID',
  `ip` char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'ip(如果在该表有查不到的IP，那么推广员ID为0，即默认推广员)',
  `promoter_id` int(11) NOT NULL COMMENT '推广员ID(也是guid)',
  `uptime` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '更新时间',
  PRIMARY KEY (`bag_id`, `ip`) USING BTREE,
  INDEX `idx_ip_bag_id`(`ip`, `bag_id`) USING BTREE,
  INDEX `idx_promoter_id`(`promoter_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for quick_reply_type
-- ----------------------------
DROP TABLE IF EXISTS `quick_reply_type`;
CREATE TABLE `quick_reply_type`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status` int(11) NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of quick_reply_type
-- ----------------------------
INSERT INTO `quick_reply_type` VALUES (5, 1, NULL, NULL, '测试');

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NULL DEFAULT NULL,
  `role_id` int(11) NULL DEFAULT NULL,
  `created_at` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `updated_at` datetime(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of role_user
-- ----------------------------
INSERT INTO `role_user` VALUES (2, 1, 4, '2019-08-16 21:17:16', NULL);
INSERT INTO `role_user` VALUES (3, 2, 5, '2019-08-16 22:02:43', '2019-08-17 16:15:26');
INSERT INTO `role_user` VALUES (4, 3, 5, '2019-08-16 23:58:51', NULL);

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`  (
  `id` int(11) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `slug` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `level` int(255) NULL DEFAULT NULL COMMENT '0',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of roles
-- ----------------------------
INSERT INTO `roles` VALUES (00000000004, 'admin', 'admin', '测试', 0, '2019-08-16 21:14:13', '2019-08-21 23:23:03');
INSERT INTO `roles` VALUES (00000000005, 'admin1', 'admin1', 'admin1', 0, '2019-08-16 23:44:34', '2019-08-17 00:00:38');

-- ----------------------------
-- Table structure for sms
-- ----------------------------
DROP TABLE IF EXISTS `sms`;
CREATE TABLE `sms`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '发送手机号',
  `content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '发送内容',
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '状态',
  `return` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '返回值',
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 26 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sms
-- ----------------------------
INSERT INTO `sms` VALUES (10, '18728483303', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:88.2/sid:0824222328639185', '2019-08-24 22:23:28', '2019-08-24 22:23:28');
INSERT INTO `sms` VALUES (11, '15328200638', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:88.1/sid:0824223035782227', '2019-08-24 22:30:35', '2019-08-24 22:30:35');
INSERT INTO `sms` VALUES (12, '18808165675', '您正在将账户绑定此手机，验证码500334。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:88/sid:0824223214325105', '2019-08-24 22:32:14', '2019-08-24 22:32:14');
INSERT INTO `sms` VALUES (13, '18808165675', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.9/sid:0824223647905783', '2019-08-24 22:36:48', '2019-08-24 22:36:48');
INSERT INTO `sms` VALUES (14, '15328200638', '您正在将账户绑定此手机，验证码358478。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.8/sid:0824223653376493', '2019-08-24 22:36:53', '2019-08-24 22:36:53');
INSERT INTO `sms` VALUES (15, '13733414639', '您正在将账户绑定此手机，验证码464962。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.7/sid:0824223844264544', '2019-08-24 22:38:44', '2019-08-24 22:38:44');
INSERT INTO `sms` VALUES (16, '16606911141', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.6/sid:0825095742682193', '2019-08-25 09:57:42', '2019-08-25 09:57:42');
INSERT INTO `sms` VALUES (17, '18583968687', '您正在将账户绑定此手机，验证码500334。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.5/sid:0825104325984363', '2019-08-25 10:43:26', '2019-08-25 10:43:26');
INSERT INTO `sms` VALUES (18, '18808165675', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.3/sid:0825141841964238', '2019-08-25 14:18:42', '2019-08-25 14:18:42');
INSERT INTO `sms` VALUES (19, '16606911142', '您正在将账户绑定此手机，验证码358478。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.2/sid:0825144143519146', '2019-08-25 14:41:43', '2019-08-25 14:41:43');
INSERT INTO `sms` VALUES (20, '15328200638', '您正在将账户绑定此手机，验证码464962。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87.1/sid:0825144711449757', '2019-08-25 14:47:11', '2019-08-25 14:47:11');
INSERT INTO `sms` VALUES (21, '18728483303', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:87/sid:0825145031584582', '2019-08-25 14:50:31', '2019-08-25 14:50:31');
INSERT INTO `sms` VALUES (22, '15608008806', '您正在将账户绑定此手机，验证码467041。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.9/sid:0825155649355426', '2019-08-25 15:56:49', '2019-08-25 15:56:49');
INSERT INTO `sms` VALUES (23, '18728483303', '您正在将账户绑定此手机，验证码500334。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.8/sid:0825155851855526', '2019-08-25 15:58:51', '2019-08-25 15:58:51');
INSERT INTO `sms` VALUES (24, '16606911142', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.7/sid:0825172318142773', '2019-08-25 17:23:18', '2019-08-25 17:23:18');
INSERT INTO `sms` VALUES (25, '16606911142', '您正在将账户绑定此手机，验证码724169。感谢您的支持！', '000', '000/Send:1/Consumption:.1/Tmoney:86.6/sid:0825174306293789', '2019-08-25 17:43:06', '2019-08-25 17:43:06');

-- ----------------------------
-- Table structure for t_account
-- ----------------------------
DROP TABLE IF EXISTS `t_account`;
CREATE TABLE `t_account`  (
  `guid` int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `account` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '账号',
  `password` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '密码',
  `is_guest` int(11) NOT NULL DEFAULT 0 COMMENT '是否是游客 1是游客',
  `nickname` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '昵称',
  `head_url` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '头像',
  `openid` char(60) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT 'openid',
  `enable_transfer` int(11) NOT NULL DEFAULT 0 COMMENT '1能够转账，0不能给其他玩家转账',
  `bank_password` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '银行密码',
  `vip` int(11) NOT NULL DEFAULT 0 COMMENT 'vip等级',
  `alipay_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加了星号的支付宝姓名',
  `alipay_name_y` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付宝姓名',
  `alipay_account` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '加了星号的支付宝账号',
  `alipay_account_y` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付宝账号',
  `bang_alipay_time` timestamp(0) NULL DEFAULT NULL COMMENT '支付宝绑时间',
  `create_time` timestamp(0) NULL DEFAULT NULL COMMENT '创建时间',
  `register_time` timestamp(0) NULL DEFAULT NULL COMMENT '注册时间',
  `login_time` timestamp(0) NULL DEFAULT NULL COMMENT '登陆时间',
  `logout_time` timestamp(0) NULL DEFAULT NULL COMMENT '退出时间',
  `online_time` int(11) NULL DEFAULT 0 COMMENT '累计在线时间',
  `login_count` int(11) NULL DEFAULT 1 COMMENT '登录次数',
  `phone` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '手机名字：ios，android',
  `phone_type` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '手机具体型号',
  `version` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '版本号',
  `channel_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号',
  `package_name` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '安装包名字',
  `imei` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '设备唯一码',
  `ip` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '客户端ip',
  `last_login_phone` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录手机名字：ios，android',
  `last_login_phone_type` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录手机具体型号',
  `last_login_version` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录版本号',
  `last_login_channel_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录渠道号',
  `last_login_package_name` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录安装包名字',
  `last_login_imei` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录设备唯一码',
  `last_login_ip` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '最后登录IP',
  `change_alipay_num` int(11) NULL DEFAULT 6 COMMENT '允许修改支付宝账号次数',
  `disabled` tinyint(4) NULL DEFAULT 0 COMMENT '0启用  1禁用',
  `risk` tinyint(4) NULL DEFAULT 0 COMMENT '危险等级0-9  9最危险',
  `recharge_count` bigint(20) NULL DEFAULT 0 COMMENT '总充值金额',
  `cash_count` bigint(20) NULL DEFAULT 0 COMMENT '总提现金额',
  `inviter_guid` int(11) NULL DEFAULT 0 COMMENT '邀请人的id',
  `invite_code` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '邀请码',
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `proxy_money` bigint(20) NULL DEFAULT 0 COMMENT '代理充值累计金额',
  `bank_card_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '**' COMMENT '银行卡姓名',
  `bank_card_num` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '**' COMMENT '银行卡号',
  `change_bankcard_num` int(11) NULL DEFAULT 6 COMMENT '允许修改银行卡号次数',
  `which_bank` int(11) NULL DEFAULT 0 COMMENT '所属银行',
  `band_bankcard_time` timestamp(0) NULL DEFAULT NULL COMMENT '银行卡绑定时间',
  `seniorpromoter` int(11) NOT NULL DEFAULT 0 COMMENT '所属推广员guid',
  `type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '默认值：0,1:线上推广员,2:线下推广员',
  `level` tinyint(1) NOT NULL DEFAULT 0 COMMENT '默认值:0,待激活:99,1-5一到五级推广员',
  `promoter_time` timestamp(0) NULL DEFAULT NULL COMMENT '成为推广员时间',
  `shared_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '共享设备码',
  PRIMARY KEY (`guid`) USING BTREE,
  UNIQUE INDEX `index_nickname`(`nickname`) USING BTREE,
  UNIQUE INDEX `index_imei`(`imei`, `platform_id`) USING BTREE,
  UNIQUE INDEX `index_account`(`account`, `platform_id`) USING BTREE,
  INDEX `index_invite_code`(`invite_code`) USING BTREE,
  INDEX `index_bang_alipay_time`(`bang_alipay_time`) USING BTREE,
  INDEX `index_create_time`(`create_time`) USING BTREE,
  INDEX `index_login_time`(`login_time`) USING BTREE,
  INDEX `index_register_time`(`register_time`) USING BTREE,
  INDEX `index_alipay_account_y`(`alipay_account_y`) USING BTREE,
  INDEX `index_ip_register_time`(`ip`, `register_time`) USING BTREE,
  INDEX `index_login_ip_time`(`last_login_ip`, `login_time`) USING BTREE,
  INDEX `index_bank_card_num`(`bank_card_num`) USING BTREE,
  INDEX `index_type_level`(`type`, `level`) USING BTREE,
  INDEX `index_seniorpromoter`(`seniorpromoter`, `guid`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '账号表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_account
-- ----------------------------
INSERT INTO `t_account` VALUES (1, '11', NULL, 0, 'guest_1', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '11', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:21:36', '2020-03-02 14:21:36', '2020-03-06 17:51:19', '2020-03-06 14:54:31', 1646881, 75, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.31', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.31', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (2, 'ddc1', NULL, 0, 'guest_2', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc1', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:22:00', '2020-03-02 14:22:00', '2020-03-07 13:48:06', '2020-03-07 13:48:06', 7146871, 57, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.57', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (3, 'ddc2', NULL, 0, 'guest_3', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc2', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:22:01', '2020-03-02 14:22:01', '2020-03-02 14:22:01', '2020-03-07 14:40:59', 2804095, 85, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.19', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (4, 'ddc3', NULL, 0, 'guest_4', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc3', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:22:02', '2020-03-02 14:22:02', '2020-03-07 14:53:07', '2020-03-06 19:17:26', 1248313, 82, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.57', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (5, '111', NULL, 0, 'guest_5', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '111', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:25:42', '2020-03-02 14:25:42', '2020-03-02 14:25:42', '2020-03-06 19:17:36', 11295000, 100, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.3', '', 'H5', '0.4.19', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (6, '222', NULL, 0, 'guest_6', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '222', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:31:04', '2020-03-02 14:31:04', '2020-03-06 17:35:04', '2020-03-06 14:48:59', 2604785, 56, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.3', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.3', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (7, '333', NULL, 0, 'guest_7', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '333', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:31:09', '2020-03-02 14:31:09', '2020-03-06 17:35:03', '2020-03-06 14:56:41', 927811, 52, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.3', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.3', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (8, '444', NULL, 0, 'guest_8', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '444', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:31:13', '2020-03-02 14:31:13', '2020-03-07 14:58:07', '2020-03-06 14:56:42', 645965, 48, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.3', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.57', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (9, '555', NULL, 0, 'guest_9', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '555', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 14:31:27', '2020-03-02 14:31:27', '2020-03-06 17:35:03', '2020-03-06 17:33:33', 8238652, 96, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.3', '', 'H5', '0.4.19', 'nil', 'gzmj', '', '192.168.2.3', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (10, 'ddc4', NULL, 0, 'guest_10', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc4', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-02 18:23:17', '2020-03-02 18:23:17', '2020-03-02 18:23:17', '2020-03-07 14:39:50', 1936868, 77, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.19', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (11, '777', NULL, 0, 'guest_11', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '777', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-03 10:45:25', '2020-03-03 10:45:25', '2020-03-03 10:45:25', '2020-03-03 11:15:07', 9366, 19, NULL, 'H5', '0.4.19', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.19', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (12, 'ddc`', NULL, 0, 'guest_12', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc`', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-03 15:18:46', '2020-03-03 15:18:46', '2020-03-03 15:18:46', '2020-03-03 15:18:52', 6, 2, NULL, 'H5', '0.4.20', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.20', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (13, '22', NULL, 0, 'guest_13', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '22', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-03 16:06:21', '2020-03-03 16:06:21', '2020-03-06 19:25:37', '2020-03-06 14:54:31', 1000862, 113, NULL, 'H5', '0.4.20', NULL, 'gzmj', NULL, '192.168.2.31', '', 'H5', '0.4.20', 'nil', 'gzmj', '', '192.168.2.31', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (14, '33', NULL, 0, 'guest_14', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '33', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-03 16:06:24', '2020-03-03 16:06:24', '2020-03-06 19:25:37', '2020-03-06 14:54:31', 1181113, 113, NULL, 'H5', '0.4.20', NULL, 'gzmj', NULL, '192.168.2.31', '', 'H5', '0.4.20', 'nil', 'gzmj', '', '192.168.2.31', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (15, 'ddc5', NULL, 0, 'guest_15', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc5', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-04 19:17:26', '2020-03-04 19:17:26', '2020-03-06 18:05:50', '2020-03-06 14:53:51', 156985, 29, NULL, 'H5', '0.4.25', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.25', 'nil', 'gzmj', '', '192.168.2.57', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (16, '44', NULL, 0, 'guest_16', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '44', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-05 09:59:21', '2020-03-05 09:59:21', '2020-03-05 09:59:21', '2020-03-05 16:32:03', 61321, 16, NULL, 'H5', '0.4.25', NULL, 'gzmj', NULL, '192.168.2.31', '', 'H5', '0.4.25', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);
INSERT INTO `t_account` VALUES (17, 'ddc', NULL, 0, 'guest_17', 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', 'ddc', 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, '2020-03-07 13:52:47', '2020-03-07 13:52:47', '2020-03-07 13:52:47', '2020-03-07 14:46:55', 3248, 2, NULL, 'H5', '0.4.28', NULL, 'gzmj', NULL, '192.168.2.57', '', 'H5', '0.4.28', 'nil', 'gzmj', '', 'nil', 6, 0, 0, 0, 0, 0, '0', '0', 0, '**', '**', 6, 0, NULL, 0, 0, 0, NULL, NULL);

-- ----------------------------
-- Table structure for t_account_bank
-- ----------------------------
DROP TABLE IF EXISTS `t_account_bank`;
CREATE TABLE `t_account_bank`  (
  `id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_account_extend_info
-- ----------------------------
DROP TABLE IF EXISTS `t_account_extend_info`;
CREATE TABLE `t_account_extend_info`  (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `key` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键',
  `value` varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '值',
  `created_at` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`guid`, `key`) USING BTREE,
  INDEX `idx_key`(`key`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_channel_invite
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite`;
CREATE TABLE `t_channel_invite`  (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号',
  `channel_lock` tinyint(3) NULL DEFAULT 0 COMMENT '1开启 0关闭',
  `big_lock` tinyint(3) NULL DEFAULT 1 COMMENT '1开启 0关闭',
  `tax_rate` int(11) UNSIGNED NOT NULL DEFAULT 1 COMMENT '税率 百分比',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_channel_validatebox
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_validatebox`;
CREATE TABLE `t_channel_validatebox`  (
  `id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道id',
  `login_validatebox` tinyint(1) NOT NULL COMMENT '是否开启登陆验证框',
  `create_validatebox` tinyint(1) NOT NULL COMMENT '是否开启创建账号验证框',
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '添加验证码原因',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_globle_append_info
-- ----------------------------
DROP TABLE IF EXISTS `t_globle_append_info`;
CREATE TABLE `t_globle_append_info`  (
  `globle_key` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'key',
  `info` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '内容',
  `status` tinyint(2) NULL DEFAULT 0 COMMENT '1 激活 其它未激活',
  `channel_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道号',
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '平台id',
  `created_time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`globle_key`, `created_time`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_globle_append_info
-- ----------------------------
INSERT INTO `t_globle_append_info` VALUES ('risk', '{\"1\":0,\"2\":0,\"3\":0,\"4\":0,\"5\":0}', 1, NULL, '', '2019-08-22 15:28:26');

-- ----------------------------
-- Table structure for t_guest_id
-- ----------------------------
DROP TABLE IF EXISTS `t_guest_id`;
CREATE TABLE `t_guest_id`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `id_key` int(11) NOT NULL DEFAULT 0 COMMENT '用于更新',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `index_id_key`(`id_key`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10071 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_guest_id
-- ----------------------------
INSERT INTO `t_guest_id` VALUES (10070, 0);

-- ----------------------------
-- Table structure for t_member
-- ----------------------------
DROP TABLE IF EXISTS `t_member`;
CREATE TABLE `t_member`  (
  `id` int(11) NOT NULL,
  `open_id` char(36) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '用户openid',
  `client_version` char(10) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '客户端版本号',
  `phone` char(15) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '手机号',
  `bank` char(32) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '保险箱',
  `nickname` char(15) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '昵称',
  `user_type` tinyint(1) NULL DEFAULT 0 COMMENT '是否是代理',
  `diamond` decimal(10, 2) NULL DEFAULT 0.00 COMMENT '钻石余额',
  `head_url` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '头像',
  `level` tinyint(2) NULL DEFAULT 0 COMMENT '用户等级 1-9',
  `money` decimal(10, 2) NULL DEFAULT 0.00 COMMENT '分数',
  `room_card` mediumint(5) NULL DEFAULT 0 COMMENT '房卡数量',
  `last_login_ip` char(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '最后登录ip',
  `last_login_time` int(11) NULL DEFAULT 0 COMMENT '登录时间',
  `imei` char(30) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '识别码',
  `account` char(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '' COMMENT '账号',
  `parent_id` mediumint(8) NULL DEFAULT 0 COMMENT '上级',
  `promote_id` mediumint(7) NULL DEFAULT 0 COMMENT '推广人的ID',
  `is_guest` tinyint(1) NULL DEFAULT 0 COMMENT '是不是游客',
  `created_at` int(11) NULL DEFAULT 0,
  `updated_at` int(11) NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = '会员表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_member
-- ----------------------------
INSERT INTO `t_member` VALUES (1, '1', '1', '15046676081', '1', '123', 1, 0.00, 'https://wx.qlogo.cn/mmopen/vi_32/DYAIOgq83erFVWKCQECibWxDPfrbEr5icT5XZNc5VFoRwjErM4lgztdFQOZFYSd9IBtWjX2Lmb5ic9icpK0QPK3JAg/132', 1, 100.00, 0, '1', 1, '1', '123123', 1, 1, 0, 0, 0);

-- ----------------------------
-- Table structure for t_online_account
-- ----------------------------
DROP TABLE IF EXISTS `t_online_account`;
CREATE TABLE `t_online_account`  (
  `guid` int(11) NOT NULL DEFAULT 0 COMMENT '全局唯一标识符',
  `first_game_type` int(11) NULL DEFAULT NULL COMMENT '5斗地主 6炸金花 8百人牛牛',
  `second_game_type` int(11) NULL DEFAULT NULL COMMENT '1新手场 2初级场 3 高级场 4富豪场',
  `game_id` int(11) NULL DEFAULT NULL COMMENT '游戏ID',
  `in_game` int(11) NOT NULL DEFAULT 0 COMMENT '1在玩游戏，0在大厅',
  PRIMARY KEY (`guid`) USING BTREE,
  INDEX `index_guid_game_id`(`guid`, `game_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '在线账号表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_online_account
-- ----------------------------
INSERT INTO `t_online_account` VALUES (54, 27, 1, 27001, 1);
INSERT INTO `t_online_account` VALUES (65, 25, 1, 15001, 1);
INSERT INTO `t_online_account` VALUES (66, 25, 1, 15001, 1);
INSERT INTO `t_online_account` VALUES (77, 25, 1, 15001, 0);

-- ----------------------------
-- Table structure for t_player_bankcard
-- ----------------------------
DROP TABLE IF EXISTS `t_player_bankcard`;
CREATE TABLE `t_player_bankcard`  (
  `guid` int(11) NOT NULL DEFAULT 0 COMMENT '账号guid',
  `bank_card_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '银行卡姓名',
  `bank_card_num` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '银行卡号',
  `change_bankcard_num` int(11) NULL DEFAULT 6 COMMENT '允许修改银行卡号次数',
  `bank_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '所属银行',
  `bank_province` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '开户省',
  `bank_city` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '开户市',
  `bank_branch` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '开户支行',
  `platform_id` varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `created_time` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_player_proxy
-- ----------------------------
DROP TABLE IF EXISTS `t_player_proxy`;
CREATE TABLE `t_player_proxy`  (
  `guid` int(11) NOT NULL DEFAULT 0 COMMENT '申请成为代理商的账号guid',
  `proxy_id` int(11) NOT NULL DEFAULT 0 COMMENT '代理商id',
  `proxy_guid` int(11) NULL DEFAULT NULL COMMENT '创建的代理商账号guid',
  `status` tinyint(4) NULL DEFAULT 0 COMMENT ' 创建代理商账号状态：0未创建 ，1 account创建成功等待创建t_player 2创建完毕',
  PRIMARY KEY (`proxy_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_promote
-- ----------------------------
DROP TABLE IF EXISTS `t_promote`;
CREATE TABLE `t_promote`  (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `username` char(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '',
  `password` char(64) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT '',
  `mobile` varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '手机号',
  `nick_name` varchar(30) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '用户名',
  `game_id` mediumint(8) NOT NULL DEFAULT 0 COMMENT '游戏id',
  `agent_id` mediumint(8) NULL DEFAULT 0 COMMENT '代理id',
  `room_card` mediumint(5) NULL DEFAULT 0 COMMENT '房卡数量',
  `diamond_num` decimal(10, 0) NULL DEFAULT 0 COMMENT '钻石数',
  `total` decimal(10, 0) NULL DEFAULT NULL COMMENT '购钻总额',
  `created_at` int(10) NULL DEFAULT NULL,
  `updated_at` int(10) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = latin1 COLLATE = latin1_swedish_ci COMMENT = '推广员表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_promote
-- ----------------------------
INSERT INTO `t_promote` VALUES (1, '17500000000', '$2y$10$Z1CWneAuCFTbuz5OVg2QsuYBQe4ViQAr9lHDLKHXfJwApgQjuSYlK', '17500000000', 'laoz', 0, 0, 0, 100, NULL, NULL, NULL);

-- ----------------------------
-- Table structure for t_validatebox_feng_ip
-- ----------------------------
DROP TABLE IF EXISTS `t_validatebox_feng_ip`;
CREATE TABLE `t_validatebox_feng_ip`  (
  `ip` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '封掉的IP,当天禁止注册账号',
  `time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(0) COMMENT '操作时间',
  `enabled` int(11) NOT NULL DEFAULT 1 COMMENT '是否开启此功能(1开启 0不开启)',
  PRIMARY KEY (`ip`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for tj_update_password_log
-- ----------------------------
DROP TABLE IF EXISTS `tj_update_password_log`;
CREATE TABLE `tj_update_password_log`  (
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `oldpassword` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '旧密码',
  `newpassword` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '新密码',
  `uptime` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`uptime`, `guid`) USING BTREE,
  INDEX `guid`(`guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `remember_token` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `created_at` timestamp(0) NULL DEFAULT NULL,
  `updated_at` timestamp(0) NULL DEFAULT NULL,
  `deleted_at` timestamp(0) NULL DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, 'admin@163.com', '$2y$10$fF68LHYl.d5YjMH.qhcyROSKruKT.7opZF0jK8rBuGV4L./bZPkQ2', '3KV0pTT1uNMXEzGbDPfRk1tOSsIUJEr8d7HxAyN6QP63BIhEFzVKmQviXYDh', NULL, '2019-08-19 15:54:45', NULL, 'admin@163.com');
INSERT INTO `users` VALUES (2, 'test', '$2y$10$WD8Rntg9Zh6YXPoWc6ZQ0ulfX8eySvxIO6yAa93FmeHUIU5Pkfhvq', 'VACIKPdpwPIaRdNfLdSxjJ1L7WxWajW4vXNHv2QfhRVE6x8bxv3WGf7omRi9', '2019-08-16 22:02:42', '2019-08-17 23:37:35', NULL, 'test@163.com');
INSERT INTO `users` VALUES (3, 'test1', '$2y$10$Zftw380CEpeZTI.YFl0nY.VNYiX4ODsKdIZ6jIY4sBlzMdkYz2/bK', '6e8q6hp3ddqK3UkeoheRz3pRLwlLrvxDVWU8Yxw1Ct4pQVD9MAkciqAlmdrm', '2019-08-16 23:58:50', '2019-08-17 00:23:14', NULL, 'test1@163.com');

-- ----------------------------
-- Procedure structure for charge_rate
-- ----------------------------
DROP PROCEDURE IF EXISTS `charge_rate`;
delimiter ;;
CREATE PROCEDURE `charge_rate`(IN `GUID_` int)
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
delimiter ;

-- ----------------------------
-- Procedure structure for check_is_agent
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_is_agent`;
delimiter ;;
CREATE PROCEDURE `check_is_agent`(IN `guid_1` int,IN `guid_2` int,IN `ignore_platform` int)
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
delimiter ;

-- ----------------------------
-- Procedure structure for check_platform
-- ----------------------------
DROP PROCEDURE IF EXISTS `check_platform`;
delimiter ;;
CREATE PROCEDURE `check_platform`(IN `guid1_` int,IN `guid2_` int)
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
delimiter ;

-- ----------------------------
-- Procedure structure for create_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_account`;
delimiter ;;
CREATE PROCEDURE `create_account`(IN `account_` VARCHAR(64), IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256) ,IN `platform_id_` varchar(256),IN `validatebox_feng_ip_` int , IN `shared_id_` varchar(256))
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
delimiter ;

-- ----------------------------
-- Procedure structure for create_guest_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_guest_account`;
delimiter ;;
CREATE PROCEDURE `create_guest_account`(IN `phone_` varchar(256), IN `phone_type_` varchar(256), IN `version_` varchar(256), IN `channel_id_` varchar(256), IN `package_name_` varchar(256), IN `imei_` varchar(256), IN `ip_` varchar(256),IN `deprecated_imei_` varchar(256), IN `platform_id_` varchar(256),IN `validatebox_feng_ip_` int,IN `shared_id_` varchar(256),IN `promotion_info_` varchar(1024))
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
delimiter ;

-- ----------------------------
-- Procedure structure for create_or_update_bankcard
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_or_update_bankcard`;
delimiter ;;
CREATE PROCEDURE `create_or_update_bankcard`(IN `guid_` int,IN `platform_id_` varchar(256),IN bank_card_num_ varchar(64),IN bank_card_name_ varchar(64),IN bank_name_ varchar(64)
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
delimiter ;

-- ----------------------------
-- Procedure structure for create_proxy_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_proxy_account`;
delimiter ;;
CREATE PROCEDURE `create_proxy_account`(IN `guid_` int,IN `proxy_id_` int,IN `platform_id_` varchar(256))
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
delimiter ;

-- ----------------------------
-- Procedure structure for create_test_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `create_test_account`;
delimiter ;;
CREATE PROCEDURE `create_test_account`()
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
delimiter ;

-- ----------------------------
-- Procedure structure for FreezeAccount
-- ----------------------------
DROP PROCEDURE IF EXISTS `FreezeAccount`;
delimiter ;;
CREATE PROCEDURE `FreezeAccount`(IN guid_ int(11),
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
delimiter ;

-- ----------------------------
-- Procedure structure for get_account_count
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_account_count`;
delimiter ;;
CREATE PROCEDURE `get_account_count`(IN `guid_` int, IN `platform_id_`  varchar(256))
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
delimiter ;

-- ----------------------------
-- Function structure for get_guest_id
-- ----------------------------
DROP FUNCTION IF EXISTS `get_guest_id`;
delimiter ;;
CREATE FUNCTION `get_guest_id`()
 RETURNS bigint(20)
BEGIN
	REPLACE INTO t_guest_id SET id_key = 0;
	RETURN LAST_INSERT_ID();
END
;;
delimiter ;

-- ----------------------------
-- Procedure structure for get_player_append_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_append_info`;
delimiter ;;
CREATE PROCEDURE `get_player_append_info`(IN `GUID_` int)
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
delimiter ;

-- ----------------------------
-- Procedure structure for get_player_data
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_data`;
delimiter ;;
CREATE PROCEDURE `get_player_data`(IN `guid_` int,IN `account_` varchar(64),IN `nick_` varchar(64),IN `money_` int)
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
delimiter ;

-- ----------------------------
-- Procedure structure for get_player_identity
-- ----------------------------
DROP PROCEDURE IF EXISTS `get_player_identity`;
delimiter ;;
CREATE PROCEDURE `get_player_identity`(IN `GUID_` int)
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
delimiter ;

-- ----------------------------
-- Procedure structure for sms_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `sms_login`;
delimiter ;;
CREATE PROCEDURE `sms_login`(IN `account_` varchar(64),IN `ip_` varchar(64),IN `phone_` varchar(256),IN `imei_` varchar(256), IN `platform_id_` varchar(256), IN `shared_id_` varchar(256))
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
delimiter ;

-- ----------------------------
-- Procedure structure for verify_account
-- ----------------------------
DROP PROCEDURE IF EXISTS `verify_account`;
delimiter ;;
CREATE PROCEDURE `verify_account`(IN `account_` varchar(64),IN `password_` varchar(32),IN `ip_` varchar(64),IN `phone_` varchar(256),IN `phone_type_` varchar(256),IN `version_` varchar(256),IN `l_channel_id_` varchar(256),
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
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
