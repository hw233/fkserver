/*
 Navicat Premium Data Transfer

 Source Server         : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com
 Source Server Type    : MySQL
 Source Server Version : 50726
 Source Host           : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com:3306
 Source Schema         : agent_admin

 Target Server Type    : MySQL
 Target Server Version : 50726
 File Encoding         : 65001

 Date: 02/06/2020 15:11:59
*/


CREATE DATABASE IF NOT EXISTS agent_admin;
USE agent_admin;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


-- ----------------------------
-- Table structure for fa_admin
-- ----------------------------
DROP TABLE IF EXISTS `fa_admin`;
CREATE TABLE `fa_admin` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `username` varchar(20) NOT NULL DEFAULT '' COMMENT '用户名',
  `nickname` varchar(50) CHARACTER SET utf8mb4 NOT NULL DEFAULT '' COMMENT '昵称',
  `password` varchar(32) NOT NULL DEFAULT '' COMMENT '密码',
  `salt` varchar(30) NOT NULL DEFAULT '' COMMENT '密码盐',
  `avatar` varchar(255) NOT NULL DEFAULT '' COMMENT '头像',
  `email` varchar(100) NOT NULL DEFAULT '' COMMENT '电子邮箱',
  `loginfailure` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '失败次数',
  `logintime` int(10) DEFAULT NULL COMMENT '登录时间',
  `loginip` varchar(50) DEFAULT NULL COMMENT '登录IP',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `token` varchar(59) NOT NULL DEFAULT '' COMMENT 'Session标识',
  `status` varchar(30) NOT NULL DEFAULT 'normal' COMMENT '状态',
  `guid` int(10) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `username` (`username`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8 COMMENT='管理员表';

-- ----------------------------
-- Records of fa_admin
-- ----------------------------
BEGIN;
INSERT INTO `fa_admin` VALUES (1, 'admin', 'Admin', 'e49279a291838421e26de71e254ef71f', 'bbc604', '/assets/img/avatar.png', 'admin@admin.com', 0, 1587971929, '118.113.135.37', 1492186163, 1587974773, '', 'normal', 0);
INSERT INTO `fa_admin` VALUES (82, '17665036371', '小咲QAQ', 'ad846ae14da3a43360ce87d9183c8e97', 'bONB4V', '/assets/img/avatar.png', '', 0, 1590143337, '171.221.129.225', NULL, 1590143337, '5f6c7efe-6b90-4b5a-b879-e770bb5a7e88', 'normal', 100002);
INSERT INTO `fa_admin` VALUES (83, '17683146641', '神净讨魔', '218d4ddeff09b44f130c5eda65718223', 'LnOp2u', '/assets/img/avatar.png', '', 0, 1590143313, '171.221.129.225', NULL, 1590143326, '', 'normal', 100004);
INSERT INTO `fa_admin` VALUES (84, '18583601564', 'A友闲喵喵', '5948870c81f319be41d7c3615a48a47a', 'XnG2Rf', '/assets/img/avatar.png', '', 0, 1590209734, '171.221.129.225', NULL, 1590209734, '1611faae-7f7b-416c-9f62-2ce2623bf204', 'normal', 124485);
COMMIT;

-- ----------------------------
-- Table structure for fa_admin_log
-- ----------------------------
DROP TABLE IF EXISTS `fa_admin_log`;
CREATE TABLE `fa_admin_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `admin_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '管理员ID',
  `username` varchar(30) NOT NULL DEFAULT '' COMMENT '管理员名字',
  `url` varchar(1500) NOT NULL DEFAULT '' COMMENT '操作页面',
  `title` varchar(100) NOT NULL DEFAULT '' COMMENT '日志标题',
  `content` text NOT NULL COMMENT '内容',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT 'IP',
  `useragent` varchar(255) NOT NULL DEFAULT '' COMMENT 'User-Agent',
  `createtime` int(10) DEFAULT NULL COMMENT '操作时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `name` (`username`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=150 DEFAULT CHARSET=utf8 COMMENT='管理员日志表';

-- ----------------------------
-- Records of fa_admin_log
-- ----------------------------
BEGIN;
INSERT INTO `fa_admin_log` VALUES (1, 1, 'admin', '/dWuBQkUHcR.php/index/login?url=%2FdWuBQkUHcR.php', '登录', '{\"url\":\"\\/dWuBQkUHcR.php\",\"__token__\":\"c7013e51b52d1a4a07aa31b031d3b528\",\"username\":\"admin\",\"captcha\":\"ru6i\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739377);
INSERT INTO `fa_admin_log` VALUES (2, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/multi/ids/66', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"66\",\"params\":\"ismenu=0\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739418);
INSERT INTO `fa_admin_log` VALUES (3, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739418);
INSERT INTO `fa_admin_log` VALUES (4, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/multi/ids/4', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"4\",\"params\":\"ismenu=0\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739420);
INSERT INTO `fa_admin_log` VALUES (5, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739420);
INSERT INTO `fa_admin_log` VALUES (6, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/multi/ids/3', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"3\",\"params\":\"ismenu=0\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739425);
INSERT INTO `fa_admin_log` VALUES (7, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739425);
INSERT INTO `fa_admin_log` VALUES (8, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"eb79944aca480c11d218d8e0e431264d\",\"row\":{\"ismenu\":\"1\",\"pid\":\"0\",\"name\":\"club\",\"title\":\"\\u8054\\u76df\\/\\u4eb2\\u53cb\\u7fa4\\u7ba1\\u7406\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739676);
INSERT INTO `fa_admin_log` VALUES (9, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739676);
INSERT INTO `fa_admin_log` VALUES (10, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"63c5cc48c76c2f18f6c9c2345546154c\",\"row\":{\"ismenu\":\"1\",\"pid\":\"85\",\"name\":\"\\u8054\\u76df\\/\\u4eb2\\u53cb\\u7fa4\\u5217\\u8868\",\"title\":\"geek\\/club\\/index\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739708);
INSERT INTO `fa_admin_log` VALUES (11, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"9da06edd6c1297803656102f5977c285\",\"row\":{\"ismenu\":\"1\",\"pid\":\"85\",\"name\":\"geek\\/club\\/index\",\"title\":\"\\u8054\\u76df\\/\\u4eb2\\u53cb\\u7fa4\\u5217\\u8868\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739716);
INSERT INTO `fa_admin_log` VALUES (12, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583739716);
INSERT INTO `fa_admin_log` VALUES (13, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"48da1b19ee703b18afbe33c8c31a9cdd\",\"row\":{\"ismenu\":\"1\",\"pid\":\"0\",\"name\":\"player\",\"title\":\"\\u73a9\\u5bb6\\u7ba1\\u7406\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583740008);
INSERT INTO `fa_admin_log` VALUES (14, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583740008);
INSERT INTO `fa_admin_log` VALUES (15, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"aa4cf05bee03f250c3a1be56e461b8e9\",\"row\":{\"ismenu\":\"1\",\"pid\":\"87\",\"name\":\"geek\\/player\\/index\",\"title\":\"\\u73a9\\u5bb6\\u5217\\u8868\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583740036);
INSERT INTO `fa_admin_log` VALUES (16, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583740036);
INSERT INTO `fa_admin_log` VALUES (17, 1, 'admin', '/dWuBQkUHcR.php/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"3d7fb8b1638729af977ca1a0ffdf3f40\",\"row\":{\"ismenu\":\"1\",\"pid\":\"87\",\"name\":\"geek\\/log\",\"title\":\"\\u73a9\\u5bb6\\u6218\\u7ee9\\u67e5\\u8be2\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583740207);
INSERT INTO `fa_admin_log` VALUES (18, 1, 'admin', '/dWuBQkUHcR.php/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583740207);
INSERT INTO `fa_admin_log` VALUES (19, 3, '18200584725', '/admin/index/login', '登录', '{\"__token__\":\"ab8daefa3eca5ce84cfef8a0ecc385aa\",\"username\":\"18200584725\",\"captcha\":\"6b7r\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583821144);
INSERT INTO `fa_admin_log` VALUES (20, 5, '18200584723', '/admin/index/login', '登录', '{\"__token__\":\"4a03d033cac9bb7feb3cfcad4d0a3467\",\"username\":\"18200584723\",\"captcha\":\"mfka\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583821194);
INSERT INTO `fa_admin_log` VALUES (21, 1, 'admin', '/admin/index/login', '登录', '{\"__token__\":\"483a1e0d106af09c4a872a35b2961be6\",\"username\":\"admin\",\"captcha\":\"73ke\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583822014);
INSERT INTO `fa_admin_log` VALUES (22, 3, '18200584725', '/admin/index/login', '登录', '{\"__token__\":\"5bf582406867a0c0582dd7b6b1d46d44\",\"username\":\"18200584725\",\"captcha\":\"at5c\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583822238);
INSERT INTO `fa_admin_log` VALUES (23, 5, '18200584723', '/admin/index/login', '登录', '{\"__token__\":\"d64cdd23a63b1ba576dcc32958e150c0\",\"username\":\"18200584723\",\"captcha\":\"yqjt\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583822258);
INSERT INTO `fa_admin_log` VALUES (24, 5, '18200584723', '/admin/geek/player/addMoney/guid/2/ids/2?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"number\":\"1\",\"uid\":\"2\"},\"guid\":\"2\",\"ids\":\"2\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583823036);
INSERT INTO `fa_admin_log` VALUES (25, 5, '18200584723', '/admin/auth/rule/multi/ids/2', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"2\",\"params\":\"ismenu=0\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583823354);
INSERT INTO `fa_admin_log` VALUES (26, 5, '18200584723', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583823354);
INSERT INTO `fa_admin_log` VALUES (27, 5, '18200584723', '/admin/auth/rule/multi/ids/88', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"88\",\"params\":\"ismenu=0\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583826296);
INSERT INTO `fa_admin_log` VALUES (28, 5, '18200584723', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583826297);
INSERT INTO `fa_admin_log` VALUES (29, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"90a17ffe55e59bc09cb1bc4273ea9d97\",\"username\":\"135165181616\",\"captcha\":\"ejld\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583906684);
INSERT INTO `fa_admin_log` VALUES (30, 1, 'admin', '/admin/index/login', '登录', '{\"__token__\":\"7018f35ff8cba90c14a5f2d264a67dad\",\"username\":\"admin\",\"captcha\":\"mdqj\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583906707);
INSERT INTO `fa_admin_log` VALUES (31, 1, 'admin', '/admin/index/login', '登录', '{\"__token__\":\"df8e501e7880fb6eb0caef6a1bbe748c\",\"username\":\"admin\",\"captcha\":\"hvkj\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583907297);
INSERT INTO `fa_admin_log` VALUES (32, 16, '18200584725', '/admin/index/login', '登录', '{\"__token__\":\"51f861bf2af4da99037b6a10bba35a38\",\"username\":\"18200584725\",\"captcha\":\"ra3b\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583910391);
INSERT INTO `fa_admin_log` VALUES (33, 16, '18200584725', '/admin/index/login', '', '{\"__token__\":\"4bdc0fe30b02a1bfb53a3c658e05cb46\",\"username\":\"18200584725\",\"captcha\":\"ljb7\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583910407);
INSERT INTO `fa_admin_log` VALUES (34, 1, 'admin', '/admin/index/login', '登录', '{\"__token__\":\"9e779fb9049dca915cda0509c42a9e38\",\"username\":\"admin\",\"captcha\":\"kjhh\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583910561);
INSERT INTO `fa_admin_log` VALUES (35, 0, 'Unknown', '/admin/index/login', '', '{\"__token__\":\"cfcdfe9740ce12824b4cc5f06f60185d\",\"username\":\"18200584725\",\"captcha\":\"ptaw\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583910578);
INSERT INTO `fa_admin_log` VALUES (36, 16, '18200584725', '/admin/index/login', '登录', '{\"__token__\":\"3b48332ba28981e3d16ba5df89a1e8de\",\"username\":\"18200584725\",\"captcha\":\"hsgy\"}', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1583910600);
INSERT INTO `fa_admin_log` VALUES (37, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"42db8d4e48ad0d6d5feb0cf17b7cf378\",\"username\":\"admin\",\"captcha\":\"h2bd\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1587535525);
INSERT INTO `fa_admin_log` VALUES (38, 1, 'admins', '/admin/index/login', '登录', '{\"__token__\":\"2da926927a233ac437361fb9f6514b1b\",\"username\":\"admins\",\"captcha\":\"mt4a\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1587535534);
INSERT INTO `fa_admin_log` VALUES (39, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"ef4bcf9aa6ceec86ac703bef66a3a123\",\"username\":\"1234567\",\"captcha\":\"f7qh\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1587536850);
INSERT INTO `fa_admin_log` VALUES (40, 67, '1234567', '/admin/index/login', '登录', '{\"__token__\":\"e3d1ce2c8af6a06d5876071716ec579c\",\"username\":\"1234567\",\"captcha\":\"xvg5\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3722.400 QQBrowser/10.5.3751.400', 1587536886);
INSERT INTO `fa_admin_log` VALUES (41, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"377cb9112bff4764f62a10052e2c9a2f\",\"username\":\"admin\",\"captcha\":\"mvuq\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.58', 1587553042);
INSERT INTO `fa_admin_log` VALUES (42, 0, 'Unknown', '/admin/index/login', '', '{\"__token__\":\"4e2d5f68bb6dfc19035d6150ad6fe2e1\",\"username\":\"admin\",\"captcha\":\"mvuq\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.58', 1587553044);
INSERT INTO `fa_admin_log` VALUES (43, 1, 'admins', '/admin/index/login', '登录', '{\"__token__\":\"b25499c41682a0b3db0f5ae402d231e4\",\"username\":\"admins\",\"captcha\":\"itey\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.58', 1587553064);
INSERT INTO `fa_admin_log` VALUES (44, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"071e6e8d928343daf942dd5bcdc41b56\",\"username\":\"admin\",\"captcha\":\"zjdu\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.62', 1587605504);
INSERT INTO `fa_admin_log` VALUES (45, 1, 'admins', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"3fa567d163988e1aaea02e63b49de01d\",\"username\":\"admins\",\"captcha\":\"xbhd\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.62', 1587605512);
INSERT INTO `fa_admin_log` VALUES (46, 0, 'Unknown', '/admin/index/login?url=%2Fadmin%2Fgeek%2Fclub%2Findex%3Fref%3Daddtabs', '登录', '{\"url\":\"\\/admin\\/geek\\/club\\/index?ref=addtabs\",\"__token__\":\"2ee7b2569f1248559af35b91e5da020a\",\"username\":\"admin\",\"captcha\":\"m5bh\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.62', 1587620960);
INSERT INTO `fa_admin_log` VALUES (47, 1, 'admins', '/admin/index/login?url=%2Fadmin%2Fgeek%2Fclub%2Findex%3Fref%3Daddtabs', '登录', '{\"url\":\"\\/admin\\/geek\\/club\\/index?ref=addtabs\",\"__token__\":\"7ce017b98eefd0ce6143b96e3bd5624a\",\"username\":\"admins\",\"captcha\":\"rxrv\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36 Edg/81.0.416.62', 1587620967);
INSERT INTO `fa_admin_log` VALUES (48, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"1bf75e17747b5b944e7b3940077cf944\",\"username\":\"admin\",\"captcha\":\"fakc\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587879474);
INSERT INTO `fa_admin_log` VALUES (49, 1, 'admins', '/admin/index/login', '登录', '{\"__token__\":\"ebf1ba5840f0cfb90d0dac5a8a9a8a7b\",\"username\":\"admins\",\"captcha\":\"7mcd\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587879481);
INSERT INTO `fa_admin_log` VALUES (50, 0, 'Unknown', '/admin/index/login?url=%2Fadmin%2Fgeek%2Fplayer%2Findex%2Fids%2F699867%3Fdialog%3D1', '', '{\"url\":\"\\/admin\\/geek\\/player\\/index\\/ids\\/699867?dialog=1\",\"__token__\":\"18131528a702de873c4b3950ff61cb91\",\"username\":\"admin\",\"captcha\":\"ormr\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587887102);
INSERT INTO `fa_admin_log` VALUES (51, 0, 'Unknown', '/admin/index/login?url=%2Fadmin%2Fgeek%2Fplayer%2Findex%2Fids%2F699867%3Fdialog%3D1', '登录', '{\"url\":\"\\/admin\\/geek\\/player\\/index\\/ids\\/699867?dialog=1\",\"__token__\":\"53dac4e60b5e77016030233c0d741bb8\",\"username\":\"admin\",\"captcha\":\"mg5h\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587887110);
INSERT INTO `fa_admin_log` VALUES (52, 1, 'admins', '/admin/index/login?url=%2Fadmin%2Fgeek%2Fplayer%2Findex%2Fids%2F699867%3Fdialog%3D1', '登录', '{\"url\":\"\\/admin\\/geek\\/player\\/index\\/ids\\/699867?dialog=1\",\"__token__\":\"8c880eb1b4141fea4ab451c773638589\",\"username\":\"admins\",\"captcha\":\"wlwz\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587887116);
INSERT INTO `fa_admin_log` VALUES (53, 1, 'admins', '/admin/index/login?url=%2Fadmin%2Fgeek%2Fclub%2Findex%3Fref%3Daddtabs', '登录', '{\"url\":\"\\/admin\\/geek\\/club\\/index?ref=addtabs\",\"__token__\":\"7b4cb6f767220fea16507c22ce45d8b8\",\"username\":\"admins\",\"captcha\":\"snf5\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587888039);
INSERT INTO `fa_admin_log` VALUES (54, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587894786);
INSERT INTO `fa_admin_log` VALUES (55, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"! = 699867\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587894927);
INSERT INTO `fa_admin_log` VALUES (56, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"! = 699867\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587894932);
INSERT INTO `fa_admin_log` VALUES (57, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"not in 699867\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895059);
INSERT INTO `fa_admin_log` VALUES (58, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"not in 699867\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895061);
INSERT INTO `fa_admin_log` VALUES (59, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"not in \"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895141);
INSERT INTO `fa_admin_log` VALUES (60, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"699867\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895154);
INSERT INTO `fa_admin_log` VALUES (61, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\",\"custom\":{\"id\":\"neq 699867\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895166);
INSERT INTO `fa_admin_log` VALUES (62, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895184);
INSERT INTO `fa_admin_log` VALUES (63, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895188);
INSERT INTO `fa_admin_log` VALUES (64, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895212);
INSERT INTO `fa_admin_log` VALUES (65, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895235);
INSERT INTO `fa_admin_log` VALUES (66, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895242);
INSERT INTO `fa_admin_log` VALUES (67, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895262);
INSERT INTO `fa_admin_log` VALUES (68, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895369);
INSERT INTO `fa_admin_log` VALUES (69, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895614);
INSERT INTO `fa_admin_log` VALUES (70, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895616);
INSERT INTO `fa_admin_log` VALUES (71, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895618);
INSERT INTO `fa_admin_log` VALUES (72, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895621);
INSERT INTO `fa_admin_log` VALUES (73, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895622);
INSERT INTO `fa_admin_log` VALUES (74, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895625);
INSERT INTO `fa_admin_log` VALUES (75, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895627);
INSERT INTO `fa_admin_log` VALUES (76, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895629);
INSERT INTO `fa_admin_log` VALUES (77, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895631);
INSERT INTO `fa_admin_log` VALUES (78, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895648);
INSERT INTO `fa_admin_log` VALUES (79, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895649);
INSERT INTO `fa_admin_log` VALUES (80, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587895885);
INSERT INTO `fa_admin_log` VALUES (81, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587896355);
INSERT INTO `fa_admin_log` VALUES (82, 1, 'admins', '/admin/geek/player/index', '玩家列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"nickname\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"nickname\",\"keyField\":\"id\",\"searchField\":[\"nickname\"],\"nickname\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587896367);
INSERT INTO `fa_admin_log` VALUES (83, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587896369);
INSERT INTO `fa_admin_log` VALUES (84, 1, 'admins', '/admin/geek/club/index', '联盟/亲友群列表', '{\"q_word\":[\"\"],\"pageNumber\":\"1\",\"pageSize\":\"10\",\"andOr\":\"AND\",\"orderBy\":[[\"name\",\"ASC\"]],\"searchTable\":\"tbl\",\"showField\":\"name\",\"keyField\":\"id\",\"searchField\":[\"name\"],\"name\":\"\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587896371);
INSERT INTO `fa_admin_log` VALUES (85, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"436569012900be6e2bd1d1d8408776d2\",\"username\":\"17683146641\",\"captcha\":\"pvqh\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587897994);
INSERT INTO `fa_admin_log` VALUES (86, 71, '17683146641', '/admin/index/login', '登录', '{\"__token__\":\"d29af9f18a477b9b47965417df5ccd9d\",\"username\":\"17683146641\",\"captcha\":\"k3qh\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587898015);
INSERT INTO `fa_admin_log` VALUES (87, 75, '12345678', '/admin/index/login', '登录', '{\"__token__\":\"d7260c89ae921deb2fdf48a8d3bf4324\",\"username\":\"12345678\",\"captcha\":\"wxgp\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587900205);
INSERT INTO `fa_admin_log` VALUES (88, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587900217);
INSERT INTO `fa_admin_log` VALUES (89, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587900768);
INSERT INTO `fa_admin_log` VALUES (90, 0, 'Unknown', '/admin/index/login?url=%2Fadmin%2Findex%2Findex', '登录', '{\"url\":\"\\/admin\\/index\\/index\",\"__token__\":\"52ec9dea723f573712044040ddd4a07f\",\"username\":\"654978450\",\"captcha\":\"hvhh\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952107);
INSERT INTO `fa_admin_log` VALUES (91, 0, 'Unknown', '/admin/index/login?url=%2Fadmin%2Findex%2Findex', '登录', '{\"url\":\"\\/admin\\/index\\/index\",\"__token__\":\"dff9df2cba3812ceea5c191566d00bb1\",\"username\":\"654978450\",\"captcha\":\"37zk\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952118);
INSERT INTO `fa_admin_log` VALUES (92, 75, '12345678', '/admin/index/login?url=%2Fadmin%2Findex%2Findex', '登录', '{\"url\":\"\\/admin\\/index\\/index\",\"__token__\":\"67627263c1e13f3bdb114f4b8c9662aa\",\"username\":\"12345678\",\"captcha\":\"ecnj\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952132);
INSERT INTO `fa_admin_log` VALUES (93, 75, '12345678', '/admin/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"3fba2db412a6883d494845348459a7a0\",\"row\":{\"ismenu\":\"1\",\"pid\":\"0\",\"name\":\"admin_log\",\"title\":\"\\u8d44\\u91d1\\u6d41\\u6c34\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952177);
INSERT INTO `fa_admin_log` VALUES (94, 75, '12345678', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952178);
INSERT INTO `fa_admin_log` VALUES (95, 75, '12345678', '/admin/auth/rule/add?dialog=1', '权限管理 菜单规则 添加', '{\"dialog\":\"1\",\"__token__\":\"ceb5c5cb813bf02a158af5c535c91cf4\",\"row\":{\"ismenu\":\"1\",\"pid\":\"90\",\"name\":\"log\\/admin_money_log\\/index\",\"title\":\"\\u5145\\u503c\\u8bb0\\u5f55\",\"icon\":\"fa fa-circle-o\",\"weigh\":\"0\",\"condition\":\"\",\"remark\":\"\",\"status\":\"normal\"}}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952210);
INSERT INTO `fa_admin_log` VALUES (96, 75, '12345678', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952211);
INSERT INTO `fa_admin_log` VALUES (97, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952652);
INSERT INTO `fa_admin_log` VALUES (98, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952681);
INSERT INTO `fa_admin_log` VALUES (99, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952729);
INSERT INTO `fa_admin_log` VALUES (100, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587952773);
INSERT INTO `fa_admin_log` VALUES (101, 75, '12345678', '/admin/geek/club/move_money/ids/614229?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"100\",\"transfer_type\":\"1\"},\"ids\":\"614229\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587953043);
INSERT INTO `fa_admin_log` VALUES (102, 74, '654978450', '/admin/index/login', '登录', '{\"__token__\":\"153c23b1ccdda1c48db6e35161c896a5\",\"username\":\"654978450\",\"captcha\":\"kee3\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587954374);
INSERT INTO `fa_admin_log` VALUES (103, 1, 'admin', '/admin/index/login?url=%2Fadmin%2Findex%2Findex', '登录', '{\"url\":\"\\/admin\\/index\\/index\",\"__token__\":\"337e54989d989ea33e40a394fccd67a3\",\"username\":\"admin\",\"captcha\":\"83rm\"}', '192.168.2.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36 Edg/81.0.416.64', 1587970251);
INSERT INTO `fa_admin_log` VALUES (104, 1, 'admin', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"7607217bcddc20311a9f31df059678d3\",\"username\":\"admin\",\"captcha\":\"f3ty\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587971929);
INSERT INTO `fa_admin_log` VALUES (105, 76, '17665036371', '/admin/index/login', '登录', '{\"__token__\":\"e9a07ebe9fa99047557de486940a53ae\",\"username\":\"17665036371\",\"captcha\":\"ZHPK\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587974792);
INSERT INTO `fa_admin_log` VALUES (106, 0, 'Unknown', '/admin/index/login', '登录', '{\"__token__\":\"e83a172792dfc59ef6d55081ca72119c\",\"username\":\"654978450\",\"captcha\":\"HLKB\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981116);
INSERT INTO `fa_admin_log` VALUES (107, 77, '17665036371', '/admin/index/login', '登录', '{\"__token__\":\"7760e0f8f2679481321e3fa646bc9ee5\",\"username\":\"17665036371\",\"captcha\":\"fpyk\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981139);
INSERT INTO `fa_admin_log` VALUES (108, 77, '17665036371', '/admin/auth/rule/multi/ids/4', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"4\",\"params\":\"ismenu=1\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981179);
INSERT INTO `fa_admin_log` VALUES (109, 77, '17665036371', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981179);
INSERT INTO `fa_admin_log` VALUES (110, 77, '17665036371', '/admin/addon/install', '插件管理', '{\"name\":\"geetest\",\"force\":\"0\",\"uid\":\"23004\",\"token\":\"bbb4f2a2-b563-4ae8-977a-55a4950b30c2\",\"version\":\"1.0.0\",\"faversion\":\"1.0.0.20200228_beta\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981209);
INSERT INTO `fa_admin_log` VALUES (111, 77, '17665036371', '/admin/geek/club/move_money/ids/893897?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"300\",\"transfer_type\":\"1\"},\"ids\":\"893897\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981230);
INSERT INTO `fa_admin_log` VALUES (112, 77, '17665036371', '/admin/geek/club/move_money/ids/893897?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"20\",\"transfer_type\":\"1\"},\"ids\":\"893897\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587981351);
INSERT INTO `fa_admin_log` VALUES (113, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '', '{\"url\":\"\\/admin\",\"__token__\":\"62808567e06274c7df07b8db5deddbfe\",\"username\":\"17683146641\",\"captcha\":\"imdm\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36', 1587983007);
INSERT INTO `fa_admin_log` VALUES (114, 78, '17683146641', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"f241bdbb3f2f77d0e466138133e9d1fa\",\"username\":\"17683146641\",\"captcha\":\"yuht\",\"keeplogin\":\"1\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36', 1587983017);
INSERT INTO `fa_admin_log` VALUES (115, 78, '17683146641', '/admin/geek/club/move_money/ids/636073?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"1000\",\"transfer_type\":\"1\"},\"ids\":\"636073\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36', 1587983118);
INSERT INTO `fa_admin_log` VALUES (116, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"aebe6e3af3b6f5cbc1bf62869c0bef2f\",\"username\":\"18328714949\",\"captcha\":\"bvhs\"}', '182.150.135.55', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587992678);
INSERT INTO `fa_admin_log` VALUES (117, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '', '{\"url\":\"\\/admin\",\"__token__\":\"57c3cd68fb6fd67abfbd8510bedb8fd6\",\"username\":\"18328714948\",\"captcha\":\"bvhs\"}', '182.150.135.55', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587992687);
INSERT INTO `fa_admin_log` VALUES (118, 79, '18328714948', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"97ac62d658be433a942903bb8d16b038\",\"username\":\"18328714948\",\"captcha\":\"pqpz\"}', '182.150.135.55', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587992696);
INSERT INTO `fa_admin_log` VALUES (119, 79, '18328714948', '/admin/geek/club/move_money/ids/64111258?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"5000\",\"transfer_type\":\"1\"},\"ids\":\"64111258\"}', '182.150.135.55', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587992738);
INSERT INTO `fa_admin_log` VALUES (120, 79, '18328714948', '/admin/geek/club/move_money/ids/871591?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"5000\",\"transfer_type\":\"1\"},\"ids\":\"871591\"}', '182.150.135.55', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1587992753);
INSERT INTO `fa_admin_log` VALUES (121, 77, '17665036371', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"2c0d38a3eddd121879aa2b4153a782ea\",\"username\":\"17665036371\",\"captcha\":\"gt5d\"}', '171.223.98.213', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1587993093);
INSERT INTO `fa_admin_log` VALUES (122, 77, '17665036371', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"709d53ccf7c83f55ea98fca203001365\",\"username\":\"17665036371\",\"captcha\":\"afwt\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1588067529);
INSERT INTO `fa_admin_log` VALUES (123, 77, '17665036371', '/admin/auth/rule/multi/ids/87', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"87\",\"params\":\"ismenu=0\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1588072128);
INSERT INTO `fa_admin_log` VALUES (124, 77, '17665036371', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36', 1588072128);
INSERT INTO `fa_admin_log` VALUES (125, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"49604bad913d4ed830484f44cdc08391\",\"username\":\"176655036371\",\"captcha\":\"mhnv\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589196944);
INSERT INTO `fa_admin_log` VALUES (126, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"60707da67defb2d423fffd9e9a781de6\",\"username\":\"176655036371\",\"captcha\":\"xfap\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589196955);
INSERT INTO `fa_admin_log` VALUES (127, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '', '{\"url\":\"\\/admin\",\"__token__\":\"edc7ff7a72efc7bf050b64735d568c72\",\"username\":\"17665036371\",\"captcha\":\"xfap\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589196986);
INSERT INTO `fa_admin_log` VALUES (128, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"d2dc21bc55463f50bfa5bedbf4a16fee\",\"username\":\"17665036371\",\"captcha\":\"knvu\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589196991);
INSERT INTO `fa_admin_log` VALUES (129, 0, 'Unknown', '/admin/index/login?url=%2Fadmin', '', '{\"url\":\"\\/admin\",\"__token__\":\"44c6afb36a8a5f3574994622e90d1e58\",\"username\":\"17665036371\",\"captcha\":\"2w0m\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589197004);
INSERT INTO `fa_admin_log` VALUES (130, 77, '17665036371', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"3cb2d4f092c2a748108d5f0dccdb7299\",\"username\":\"17665036371\",\"captcha\":\"pk55\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589197009);
INSERT INTO `fa_admin_log` VALUES (131, 77, '17665036371', '/admin/geek/club/move_money/ids/82940828?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"400\",\"transfer_type\":\"1\"},\"ids\":\"82940828\"}', '171.214.211.79', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589197026);
INSERT INTO `fa_admin_log` VALUES (132, 81, '1192658478', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"2dbc05191932852746fb8186313a931b\",\"username\":\"1192658478\",\"captcha\":\"r7gc\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589352178);
INSERT INTO `fa_admin_log` VALUES (133, 81, '1192658478', '/admin/geek/club/move_money/ids/65970828?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"10000\",\"transfer_type\":\"1\"},\"ids\":\"65970828\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589352254);
INSERT INTO `fa_admin_log` VALUES (134, 82, '17665036371', '/admin/index/login', '登录', '{\"__token__\":\"bb4bd8207201208ee958b26e226790d9\",\"username\":\"17665036371\",\"captcha\":\"d2pe\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589537147);
INSERT INTO `fa_admin_log` VALUES (135, 82, '17665036371', '/admin/geek/club/move_money/ids/636588?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"20000\",\"transfer_type\":\"1\"},\"ids\":\"636588\"}', '118.113.135.37', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1589537162);
INSERT INTO `fa_admin_log` VALUES (136, 82, '17665036371', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"1670c59dc3264724ab80141ceca14dc4\",\"username\":\"17665036371\",\"captcha\":\"ELH7\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590142926);
INSERT INTO `fa_admin_log` VALUES (137, 82, '17665036371', '/admin/geek/player/addMoney/guid/100005/ids/100005?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"number\":\"50\",\"uid\":\"100005\"},\"guid\":\"100005\",\"ids\":\"100005\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590142958);
INSERT INTO `fa_admin_log` VALUES (138, 82, '17665036371', '/admin/geek/player/addMoney/guid/100004/ids/100004?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"number\":\"50\",\"uid\":\"100004\"},\"guid\":\"100004\",\"ids\":\"100004\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143049);
INSERT INTO `fa_admin_log` VALUES (139, 82, '17665036371', '/admin/geek/player/addMoney/guid/100004/ids/100004?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"number\":\"10000\",\"uid\":\"100004\"},\"guid\":\"100004\",\"ids\":\"100004\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143130);
INSERT INTO `fa_admin_log` VALUES (140, 82, '17665036371', '/admin/geek/player/addMoney/guid/100004/ids/100004?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"number\":\"500\",\"uid\":\"100004\"},\"guid\":\"100004\",\"ids\":\"100004\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143151);
INSERT INTO `fa_admin_log` VALUES (141, 82, '17665036371', '/admin/auth/rule/multi/ids/4', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"4\",\"params\":\"ismenu=0\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143262);
INSERT INTO `fa_admin_log` VALUES (142, 82, '17665036371', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143262);
INSERT INTO `fa_admin_log` VALUES (143, 82, '17665036371', '/admin/auth/rule/multi/ids/5', '权限管理 菜单规则', '{\"action\":\"\",\"ids\":\"5\",\"params\":\"ismenu=0\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143272);
INSERT INTO `fa_admin_log` VALUES (144, 82, '17665036371', '/admin/index/index', '', '{\"action\":\"refreshmenu\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143272);
INSERT INTO `fa_admin_log` VALUES (145, 83, '17683146641', '/admin/index/login', '登录', '{\"__token__\":\"e854a83357daeaf9d6946d4b87a98e22\",\"username\":\"17683146641\",\"captcha\":\"dauw\",\"keeplogin\":\"1\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143313);
INSERT INTO `fa_admin_log` VALUES (146, 82, '17665036371', '/admin/index/login', '登录', '{\"__token__\":\"68999e2380f2441cd8786e0e246f450a\",\"username\":\"17665036371\",\"captcha\":\"JAMY\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143337);
INSERT INTO `fa_admin_log` VALUES (147, 82, '17665036371', '/admin/geek/club/move_money/ids/83880576?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"500\",\"transfer_type\":\"1\"},\"ids\":\"83880576\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER', 1590143620);
INSERT INTO `fa_admin_log` VALUES (148, 84, '18583601564', '/admin/index/login?url=%2Fadmin', '登录', '{\"url\":\"\\/admin\",\"__token__\":\"7d7eaf69047d6405b83c6bc0bd77f1e2\",\"username\":\"18583601564\",\"captcha\":\"smvs\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36', 1590209734);
INSERT INTO `fa_admin_log` VALUES (149, 84, '18583601564', '/admin/geek/club/move_money/ids/878900?dialog=1', '', '{\"dialog\":\"1\",\"row\":{\"amount\":\"500\",\"transfer_type\":\"1\"},\"ids\":\"878900\"}', '171.221.129.225', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36', 1590209751);
COMMIT;

-- ----------------------------
-- Table structure for fa_attachment
-- ----------------------------
DROP TABLE IF EXISTS `fa_attachment`;
CREATE TABLE `fa_attachment` (
  `id` int(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `admin_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '管理员ID',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '会员ID',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT '物理路径',
  `imagewidth` varchar(30) NOT NULL DEFAULT '' COMMENT '宽度',
  `imageheight` varchar(30) NOT NULL DEFAULT '' COMMENT '高度',
  `imagetype` varchar(30) NOT NULL DEFAULT '' COMMENT '图片类型',
  `imageframes` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '图片帧数',
  `filesize` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '文件大小',
  `mimetype` varchar(100) NOT NULL DEFAULT '' COMMENT 'mime类型',
  `extparam` varchar(255) NOT NULL DEFAULT '' COMMENT '透传数据',
  `createtime` int(10) DEFAULT NULL COMMENT '创建日期',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `uploadtime` int(10) DEFAULT NULL COMMENT '上传时间',
  `storage` varchar(100) NOT NULL DEFAULT 'local' COMMENT '存储位置',
  `sha1` varchar(40) NOT NULL DEFAULT '' COMMENT '文件 sha1编码',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='附件表';

-- ----------------------------
-- Records of fa_attachment
-- ----------------------------
BEGIN;
INSERT INTO `fa_attachment` VALUES (1, 1, 0, '/assets/img/qrcode.png', '150', '150', 'png', 0, 21859, 'image/png', '', 1499681848, 1499681848, 1499681848, 'local', '17163603d0263e4838b9387ff2cd4877e8b018f6');
COMMIT;

-- ----------------------------
-- Table structure for fa_auth_group
-- ----------------------------
DROP TABLE IF EXISTS `fa_auth_group`;
CREATE TABLE `fa_auth_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '父组别',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '组名',
  `rules` text NOT NULL COMMENT '规则ID',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `status` varchar(30) NOT NULL DEFAULT '' COMMENT '状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COMMENT='分组表';

-- ----------------------------
-- Records of fa_auth_group
-- ----------------------------
BEGIN;
INSERT INTO `fa_auth_group` VALUES (1, 0, 'Admin group', '*', 1490883540, 149088354, 'normal');
INSERT INTO `fa_auth_group` VALUES (2, 1, 'Second group', '13,14,16,15,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,40,41,42,43,44,45,46,47,48,49,50,55,56,57,58,59,60,61,62,63,64,65,1,9,10,11,7,6,8,2,4,5', 1490883540, 1505465692, 'normal');
INSERT INTO `fa_auth_group` VALUES (3, 2, 'Third group', '1,4,9,10,11,13,14,15,16,17,40,41,42,43,44,45,46,47,48,49,50,55,56,57,58,59,60,61,62,63,64,65,5', 1490883540, 1502205322, 'normal');
INSERT INTO `fa_auth_group` VALUES (4, 1, 'Second group 2', '1,4,13,14,15,16,17,55,56,57,58,59,60,61,62,63,64,65', 1490883540, 1502205350, 'normal');
INSERT INTO `fa_auth_group` VALUES (5, 2, 'Third group 2', '1,2,6,7,8,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34', 1490883540, 1502205344, 'normal');
COMMIT;

-- ----------------------------
-- Table structure for fa_auth_group_access
-- ----------------------------
DROP TABLE IF EXISTS `fa_auth_group_access`;
CREATE TABLE `fa_auth_group_access` (
  `uid` int(10) unsigned NOT NULL COMMENT '会员ID',
  `group_id` int(10) unsigned NOT NULL COMMENT '级别ID',
  UNIQUE KEY `uid_group_id` (`uid`,`group_id`) USING BTREE,
  KEY `uid` (`uid`) USING BTREE,
  KEY `group_id` (`group_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='权限分组表';

-- ----------------------------
-- Records of fa_auth_group_access
-- ----------------------------
BEGIN;
INSERT INTO `fa_auth_group_access` VALUES (1, 1);
INSERT INTO `fa_auth_group_access` VALUES (2, 1);
INSERT INTO `fa_auth_group_access` VALUES (3, 1);
INSERT INTO `fa_auth_group_access` VALUES (5, 1);
INSERT INTO `fa_auth_group_access` VALUES (6, 1);
INSERT INTO `fa_auth_group_access` VALUES (7, 1);
INSERT INTO `fa_auth_group_access` VALUES (11, 1);
INSERT INTO `fa_auth_group_access` VALUES (12, 1);
INSERT INTO `fa_auth_group_access` VALUES (13, 1);
INSERT INTO `fa_auth_group_access` VALUES (14, 1);
INSERT INTO `fa_auth_group_access` VALUES (15, 1);
INSERT INTO `fa_auth_group_access` VALUES (16, 1);
INSERT INTO `fa_auth_group_access` VALUES (17, 1);
INSERT INTO `fa_auth_group_access` VALUES (18, 1);
INSERT INTO `fa_auth_group_access` VALUES (19, 1);
INSERT INTO `fa_auth_group_access` VALUES (21, 1);
INSERT INTO `fa_auth_group_access` VALUES (22, 1);
INSERT INTO `fa_auth_group_access` VALUES (23, 1);
INSERT INTO `fa_auth_group_access` VALUES (24, 1);
INSERT INTO `fa_auth_group_access` VALUES (25, 1);
INSERT INTO `fa_auth_group_access` VALUES (26, 1);
INSERT INTO `fa_auth_group_access` VALUES (27, 1);
INSERT INTO `fa_auth_group_access` VALUES (28, 1);
INSERT INTO `fa_auth_group_access` VALUES (29, 1);
INSERT INTO `fa_auth_group_access` VALUES (30, 1);
INSERT INTO `fa_auth_group_access` VALUES (31, 1);
INSERT INTO `fa_auth_group_access` VALUES (32, 1);
INSERT INTO `fa_auth_group_access` VALUES (35, 1);
INSERT INTO `fa_auth_group_access` VALUES (36, 1);
INSERT INTO `fa_auth_group_access` VALUES (40, 1);
INSERT INTO `fa_auth_group_access` VALUES (41, 1);
INSERT INTO `fa_auth_group_access` VALUES (42, 1);
INSERT INTO `fa_auth_group_access` VALUES (43, 1);
INSERT INTO `fa_auth_group_access` VALUES (44, 1);
INSERT INTO `fa_auth_group_access` VALUES (45, 1);
INSERT INTO `fa_auth_group_access` VALUES (46, 1);
INSERT INTO `fa_auth_group_access` VALUES (47, 1);
INSERT INTO `fa_auth_group_access` VALUES (48, 1);
INSERT INTO `fa_auth_group_access` VALUES (49, 1);
INSERT INTO `fa_auth_group_access` VALUES (50, 1);
INSERT INTO `fa_auth_group_access` VALUES (51, 1);
INSERT INTO `fa_auth_group_access` VALUES (52, 1);
INSERT INTO `fa_auth_group_access` VALUES (53, 1);
INSERT INTO `fa_auth_group_access` VALUES (54, 1);
INSERT INTO `fa_auth_group_access` VALUES (55, 1);
INSERT INTO `fa_auth_group_access` VALUES (56, 1);
INSERT INTO `fa_auth_group_access` VALUES (57, 1);
INSERT INTO `fa_auth_group_access` VALUES (58, 1);
INSERT INTO `fa_auth_group_access` VALUES (59, 1);
INSERT INTO `fa_auth_group_access` VALUES (60, 1);
INSERT INTO `fa_auth_group_access` VALUES (61, 1);
INSERT INTO `fa_auth_group_access` VALUES (62, 1);
INSERT INTO `fa_auth_group_access` VALUES (63, 1);
INSERT INTO `fa_auth_group_access` VALUES (64, 1);
INSERT INTO `fa_auth_group_access` VALUES (65, 1);
INSERT INTO `fa_auth_group_access` VALUES (66, 1);
INSERT INTO `fa_auth_group_access` VALUES (67, 1);
INSERT INTO `fa_auth_group_access` VALUES (68, 1);
INSERT INTO `fa_auth_group_access` VALUES (69, 1);
INSERT INTO `fa_auth_group_access` VALUES (70, 1);
INSERT INTO `fa_auth_group_access` VALUES (71, 1);
INSERT INTO `fa_auth_group_access` VALUES (72, 1);
INSERT INTO `fa_auth_group_access` VALUES (73, 1);
INSERT INTO `fa_auth_group_access` VALUES (74, 1);
INSERT INTO `fa_auth_group_access` VALUES (75, 1);
INSERT INTO `fa_auth_group_access` VALUES (76, 1);
INSERT INTO `fa_auth_group_access` VALUES (77, 1);
INSERT INTO `fa_auth_group_access` VALUES (78, 1);
INSERT INTO `fa_auth_group_access` VALUES (79, 1);
INSERT INTO `fa_auth_group_access` VALUES (80, 1);
INSERT INTO `fa_auth_group_access` VALUES (81, 1);
INSERT INTO `fa_auth_group_access` VALUES (82, 1);
INSERT INTO `fa_auth_group_access` VALUES (83, 1);
INSERT INTO `fa_auth_group_access` VALUES (84, 1);
COMMIT;

-- ----------------------------
-- Table structure for fa_auth_rule
-- ----------------------------
DROP TABLE IF EXISTS `fa_auth_rule`;
CREATE TABLE `fa_auth_rule` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` enum('menu','file') NOT NULL DEFAULT 'file' COMMENT 'menu为菜单,file为权限节点',
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '父ID',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '规则名称',
  `title` varchar(50) NOT NULL DEFAULT '' COMMENT '规则名称',
  `icon` varchar(50) NOT NULL DEFAULT '' COMMENT '图标',
  `condition` varchar(255) NOT NULL DEFAULT '' COMMENT '条件',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `ismenu` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否为菜单',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `weigh` int(10) NOT NULL DEFAULT '0' COMMENT '权重',
  `status` varchar(30) NOT NULL DEFAULT '' COMMENT '状态',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `name` (`name`) USING BTREE,
  KEY `pid` (`pid`) USING BTREE,
  KEY `weigh` (`weigh`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8 COMMENT='节点表';

-- ----------------------------
-- Records of fa_auth_rule
-- ----------------------------
BEGIN;
INSERT INTO `fa_auth_rule` VALUES (1, 'file', 0, 'dashboard', 'Dashboard', 'fa fa-dashboard', '', 'Dashboard tips', 1, 1497429920, 1497429920, 143, 'normal');
INSERT INTO `fa_auth_rule` VALUES (2, 'file', 0, 'general', 'General', 'fa fa-cogs', '', '', 0, 1497429920, 1583823354, 137, 'normal');
INSERT INTO `fa_auth_rule` VALUES (3, 'file', 0, 'category', 'Category', 'fa fa-leaf', '', 'Category tips', 0, 1497429920, 1583739425, 119, 'normal');
INSERT INTO `fa_auth_rule` VALUES (4, 'file', 0, 'addon', 'Addon', 'fa fa-rocket', '', 'Addon tips', 0, 1502035509, 1590143262, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (5, 'file', 0, 'auth', 'Auth', 'fa fa-group', '', '', 0, 1497429920, 1590143272, 99, 'normal');
INSERT INTO `fa_auth_rule` VALUES (6, 'file', 2, 'general/config', 'Config', 'fa fa-cog', '', 'Config tips', 1, 1497429920, 1497430683, 60, 'normal');
INSERT INTO `fa_auth_rule` VALUES (7, 'file', 2, 'general/attachment', 'Attachment', 'fa fa-file-image-o', '', 'Attachment tips', 1, 1497429920, 1497430699, 53, 'normal');
INSERT INTO `fa_auth_rule` VALUES (8, 'file', 2, 'general/profile', 'Profile', 'fa fa-user', '', '', 1, 1497429920, 1497429920, 34, 'normal');
INSERT INTO `fa_auth_rule` VALUES (9, 'file', 5, 'auth/admin', 'Admin', 'fa fa-user', '', 'Admin tips', 1, 1497429920, 1497430320, 118, 'normal');
INSERT INTO `fa_auth_rule` VALUES (10, 'file', 5, 'auth/adminlog', 'Admin log', 'fa fa-list-alt', '', 'Admin log tips', 1, 1497429920, 1497430307, 113, 'normal');
INSERT INTO `fa_auth_rule` VALUES (11, 'file', 5, 'auth/group', 'Group', 'fa fa-group', '', 'Group tips', 1, 1497429920, 1497429920, 109, 'normal');
INSERT INTO `fa_auth_rule` VALUES (12, 'file', 5, 'auth/rule', 'Rule', 'fa fa-bars', '', 'Rule tips', 1, 1497429920, 1497430581, 104, 'normal');
INSERT INTO `fa_auth_rule` VALUES (13, 'file', 1, 'dashboard/index', 'View', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 136, 'normal');
INSERT INTO `fa_auth_rule` VALUES (14, 'file', 1, 'dashboard/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 135, 'normal');
INSERT INTO `fa_auth_rule` VALUES (15, 'file', 1, 'dashboard/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 133, 'normal');
INSERT INTO `fa_auth_rule` VALUES (16, 'file', 1, 'dashboard/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 134, 'normal');
INSERT INTO `fa_auth_rule` VALUES (17, 'file', 1, 'dashboard/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 132, 'normal');
INSERT INTO `fa_auth_rule` VALUES (18, 'file', 6, 'general/config/index', 'View', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 52, 'normal');
INSERT INTO `fa_auth_rule` VALUES (19, 'file', 6, 'general/config/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 51, 'normal');
INSERT INTO `fa_auth_rule` VALUES (20, 'file', 6, 'general/config/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 50, 'normal');
INSERT INTO `fa_auth_rule` VALUES (21, 'file', 6, 'general/config/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 49, 'normal');
INSERT INTO `fa_auth_rule` VALUES (22, 'file', 6, 'general/config/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 48, 'normal');
INSERT INTO `fa_auth_rule` VALUES (23, 'file', 7, 'general/attachment/index', 'View', 'fa fa-circle-o', '', 'Attachment tips', 0, 1497429920, 1497429920, 59, 'normal');
INSERT INTO `fa_auth_rule` VALUES (24, 'file', 7, 'general/attachment/select', 'Select attachment', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 58, 'normal');
INSERT INTO `fa_auth_rule` VALUES (25, 'file', 7, 'general/attachment/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 57, 'normal');
INSERT INTO `fa_auth_rule` VALUES (26, 'file', 7, 'general/attachment/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 56, 'normal');
INSERT INTO `fa_auth_rule` VALUES (27, 'file', 7, 'general/attachment/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 55, 'normal');
INSERT INTO `fa_auth_rule` VALUES (28, 'file', 7, 'general/attachment/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 54, 'normal');
INSERT INTO `fa_auth_rule` VALUES (29, 'file', 8, 'general/profile/index', 'View', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 33, 'normal');
INSERT INTO `fa_auth_rule` VALUES (30, 'file', 8, 'general/profile/update', 'Update profile', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 32, 'normal');
INSERT INTO `fa_auth_rule` VALUES (31, 'file', 8, 'general/profile/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 31, 'normal');
INSERT INTO `fa_auth_rule` VALUES (32, 'file', 8, 'general/profile/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 30, 'normal');
INSERT INTO `fa_auth_rule` VALUES (33, 'file', 8, 'general/profile/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 29, 'normal');
INSERT INTO `fa_auth_rule` VALUES (34, 'file', 8, 'general/profile/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 28, 'normal');
INSERT INTO `fa_auth_rule` VALUES (35, 'file', 3, 'category/index', 'View', 'fa fa-circle-o', '', 'Category tips', 0, 1497429920, 1497429920, 142, 'normal');
INSERT INTO `fa_auth_rule` VALUES (36, 'file', 3, 'category/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 141, 'normal');
INSERT INTO `fa_auth_rule` VALUES (37, 'file', 3, 'category/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 140, 'normal');
INSERT INTO `fa_auth_rule` VALUES (38, 'file', 3, 'category/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 139, 'normal');
INSERT INTO `fa_auth_rule` VALUES (39, 'file', 3, 'category/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 138, 'normal');
INSERT INTO `fa_auth_rule` VALUES (40, 'file', 9, 'auth/admin/index', 'View', 'fa fa-circle-o', '', 'Admin tips', 0, 1497429920, 1497429920, 117, 'normal');
INSERT INTO `fa_auth_rule` VALUES (41, 'file', 9, 'auth/admin/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 116, 'normal');
INSERT INTO `fa_auth_rule` VALUES (42, 'file', 9, 'auth/admin/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 115, 'normal');
INSERT INTO `fa_auth_rule` VALUES (43, 'file', 9, 'auth/admin/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 114, 'normal');
INSERT INTO `fa_auth_rule` VALUES (44, 'file', 10, 'auth/adminlog/index', 'View', 'fa fa-circle-o', '', 'Admin log tips', 0, 1497429920, 1497429920, 112, 'normal');
INSERT INTO `fa_auth_rule` VALUES (45, 'file', 10, 'auth/adminlog/detail', 'Detail', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 111, 'normal');
INSERT INTO `fa_auth_rule` VALUES (46, 'file', 10, 'auth/adminlog/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 110, 'normal');
INSERT INTO `fa_auth_rule` VALUES (47, 'file', 11, 'auth/group/index', 'View', 'fa fa-circle-o', '', 'Group tips', 0, 1497429920, 1497429920, 108, 'normal');
INSERT INTO `fa_auth_rule` VALUES (48, 'file', 11, 'auth/group/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 107, 'normal');
INSERT INTO `fa_auth_rule` VALUES (49, 'file', 11, 'auth/group/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 106, 'normal');
INSERT INTO `fa_auth_rule` VALUES (50, 'file', 11, 'auth/group/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 105, 'normal');
INSERT INTO `fa_auth_rule` VALUES (51, 'file', 12, 'auth/rule/index', 'View', 'fa fa-circle-o', '', 'Rule tips', 0, 1497429920, 1497429920, 103, 'normal');
INSERT INTO `fa_auth_rule` VALUES (52, 'file', 12, 'auth/rule/add', 'Add', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 102, 'normal');
INSERT INTO `fa_auth_rule` VALUES (53, 'file', 12, 'auth/rule/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 101, 'normal');
INSERT INTO `fa_auth_rule` VALUES (54, 'file', 12, 'auth/rule/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1497429920, 1497429920, 100, 'normal');
INSERT INTO `fa_auth_rule` VALUES (55, 'file', 4, 'addon/index', 'View', 'fa fa-circle-o', '', 'Addon tips', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (56, 'file', 4, 'addon/add', 'Add', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (57, 'file', 4, 'addon/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (58, 'file', 4, 'addon/del', 'Delete', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (59, 'file', 4, 'addon/downloaded', 'Local addon', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (60, 'file', 4, 'addon/state', 'Update state', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (63, 'file', 4, 'addon/config', 'Setting', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (64, 'file', 4, 'addon/refresh', 'Refresh', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (65, 'file', 4, 'addon/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1502035509, 1502035509, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (66, 'file', 0, 'user', 'User', 'fa fa-list', '', '', 0, 1516374729, 1583739418, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (67, 'file', 66, 'user/user', 'User', 'fa fa-user', '', '', 1, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (68, 'file', 67, 'user/user/index', 'View', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (69, 'file', 67, 'user/user/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (70, 'file', 67, 'user/user/add', 'Add', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (71, 'file', 67, 'user/user/del', 'Del', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (72, 'file', 67, 'user/user/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (73, 'file', 66, 'user/group', 'User group', 'fa fa-users', '', '', 1, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (74, 'file', 73, 'user/group/add', 'Add', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (75, 'file', 73, 'user/group/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (76, 'file', 73, 'user/group/index', 'View', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (77, 'file', 73, 'user/group/del', 'Del', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (78, 'file', 73, 'user/group/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (79, 'file', 66, 'user/rule', 'User rule', 'fa fa-circle-o', '', '', 1, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (80, 'file', 79, 'user/rule/index', 'View', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (81, 'file', 79, 'user/rule/del', 'Del', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (82, 'file', 79, 'user/rule/add', 'Add', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (83, 'file', 79, 'user/rule/edit', 'Edit', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (84, 'file', 79, 'user/rule/multi', 'Multi', 'fa fa-circle-o', '', '', 0, 1516374729, 1516374729, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (85, 'file', 0, 'club', '联盟/亲友群管理', 'fa fa-circle-o', '', '', 1, 1583739676, 1583739676, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (86, 'file', 85, 'geek/club/index', '联盟/亲友群列表', 'fa fa-circle-o', '', '', 1, 1583739716, 1583739716, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (87, 'file', 0, 'player', '玩家管理', 'fa fa-circle-o', '', '', 0, 1583740008, 1588072128, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (88, 'file', 87, 'geek/player/index', '玩家列表', 'fa fa-circle-o', '', '', 0, 1583740036, 1583826296, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (89, 'file', 87, 'geek/log', '玩家战绩查询', 'fa fa-circle-o', '', '', 1, 1583740207, 1583740207, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (90, 'file', 0, 'admin_log', '资金流水', 'fa fa-circle-o', '', '', 1, 1587952177, 1587952177, 0, 'normal');
INSERT INTO `fa_auth_rule` VALUES (91, 'file', 90, 'log/admin_money_log/index', '充值记录', 'fa fa-circle-o', '', '', 1, 1587952210, 1587952210, 0, 'normal');
COMMIT;

-- ----------------------------
-- Table structure for fa_category
-- ----------------------------
DROP TABLE IF EXISTS `fa_category`;
CREATE TABLE `fa_category` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '父ID',
  `type` varchar(30) NOT NULL DEFAULT '' COMMENT '栏目类型',
  `name` varchar(30) NOT NULL DEFAULT '',
  `nickname` varchar(50) NOT NULL DEFAULT '',
  `flag` set('hot','index','recommend') NOT NULL DEFAULT '',
  `image` varchar(100) NOT NULL DEFAULT '' COMMENT '图片',
  `keywords` varchar(255) NOT NULL DEFAULT '' COMMENT '关键字',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `diyname` varchar(30) NOT NULL DEFAULT '' COMMENT '自定义名称',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `weigh` int(10) NOT NULL DEFAULT '0' COMMENT '权重',
  `status` varchar(30) NOT NULL DEFAULT '' COMMENT '状态',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `weigh` (`weigh`,`id`) USING BTREE,
  KEY `pid` (`pid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COMMENT='分类表';

-- ----------------------------
-- Records of fa_category
-- ----------------------------
BEGIN;
INSERT INTO `fa_category` VALUES (1, 0, 'page', '官方新闻', 'news', 'recommend', '/assets/img/qrcode.png', '', '', 'news', 1495262190, 1495262190, 1, 'normal');
INSERT INTO `fa_category` VALUES (2, 0, 'page', '移动应用', 'mobileapp', 'hot', '/assets/img/qrcode.png', '', '', 'mobileapp', 1495262244, 1495262244, 2, 'normal');
INSERT INTO `fa_category` VALUES (3, 2, 'page', '微信公众号', 'wechatpublic', 'index', '/assets/img/qrcode.png', '', '', 'wechatpublic', 1495262288, 1495262288, 3, 'normal');
INSERT INTO `fa_category` VALUES (4, 2, 'page', 'Android开发', 'android', 'recommend', '/assets/img/qrcode.png', '', '', 'android', 1495262317, 1495262317, 4, 'normal');
INSERT INTO `fa_category` VALUES (5, 0, 'page', '软件产品', 'software', 'recommend', '/assets/img/qrcode.png', '', '', 'software', 1495262336, 1499681850, 5, 'normal');
INSERT INTO `fa_category` VALUES (6, 5, 'page', '网站建站', 'website', 'recommend', '/assets/img/qrcode.png', '', '', 'website', 1495262357, 1495262357, 6, 'normal');
INSERT INTO `fa_category` VALUES (7, 5, 'page', '企业管理软件', 'company', 'index', '/assets/img/qrcode.png', '', '', 'company', 1495262391, 1495262391, 7, 'normal');
INSERT INTO `fa_category` VALUES (8, 6, 'page', 'PC端', 'website-pc', 'recommend', '/assets/img/qrcode.png', '', '', 'website-pc', 1495262424, 1495262424, 8, 'normal');
INSERT INTO `fa_category` VALUES (9, 6, 'page', '移动端', 'website-mobile', 'recommend', '/assets/img/qrcode.png', '', '', 'website-mobile', 1495262456, 1495262456, 9, 'normal');
INSERT INTO `fa_category` VALUES (10, 7, 'page', 'CRM系统 ', 'company-crm', 'recommend', '/assets/img/qrcode.png', '', '', 'company-crm', 1495262487, 1495262487, 10, 'normal');
INSERT INTO `fa_category` VALUES (11, 7, 'page', 'SASS平台软件', 'company-sass', 'recommend', '/assets/img/qrcode.png', '', '', 'company-sass', 1495262515, 1495262515, 11, 'normal');
INSERT INTO `fa_category` VALUES (12, 0, 'test', '测试1', 'test1', 'recommend', '/assets/img/qrcode.png', '', '', 'test1', 1497015727, 1497015727, 12, 'normal');
INSERT INTO `fa_category` VALUES (13, 0, 'test', '测试2', 'test2', 'recommend', '/assets/img/qrcode.png', '', '', 'test2', 1497015738, 1497015738, 13, 'normal');
COMMIT;

-- ----------------------------
-- Table structure for fa_config
-- ----------------------------
DROP TABLE IF EXISTS `fa_config`;
CREATE TABLE `fa_config` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL DEFAULT '' COMMENT '变量名',
  `group` varchar(30) NOT NULL DEFAULT '' COMMENT '分组',
  `title` varchar(100) NOT NULL DEFAULT '' COMMENT '变量标题',
  `tip` varchar(100) NOT NULL DEFAULT '' COMMENT '变量描述',
  `type` varchar(30) NOT NULL DEFAULT '' COMMENT '类型:string,text,int,bool,array,datetime,date,file',
  `value` text NOT NULL COMMENT '变量值',
  `content` text NOT NULL COMMENT '变量字典数据',
  `rule` varchar(100) NOT NULL DEFAULT '' COMMENT '验证规则',
  `extend` varchar(255) NOT NULL DEFAULT '' COMMENT '扩展属性',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8 COMMENT='系统配置';

-- ----------------------------
-- Records of fa_config
-- ----------------------------
BEGIN;
INSERT INTO `fa_config` VALUES (1, 'name', 'basic', 'Site name', '请填写站点名称', 'string', '我的网站', '', 'required', '');
INSERT INTO `fa_config` VALUES (2, 'beian', 'basic', 'Beian', '粤ICP备15000000号-1', 'string', '', '', '', '');
INSERT INTO `fa_config` VALUES (3, 'cdnurl', 'basic', 'Cdn url', '如果静态资源使用第三方云储存请配置该值', 'string', '', '', '', '');
INSERT INTO `fa_config` VALUES (4, 'version', 'basic', 'Version', '如果静态资源有变动请重新配置该值', 'string', '1.0.1', '', 'required', '');
INSERT INTO `fa_config` VALUES (5, 'timezone', 'basic', 'Timezone', '', 'string', 'Asia/Shanghai', '', 'required', '');
INSERT INTO `fa_config` VALUES (6, 'forbiddenip', 'basic', 'Forbidden ip', '一行一条记录', 'text', '', '', '', '');
INSERT INTO `fa_config` VALUES (7, 'languages', 'basic', 'Languages', '', 'array', '{\"backend\":\"zh-cn\",\"frontend\":\"zh-cn\"}', '', 'required', '');
INSERT INTO `fa_config` VALUES (8, 'fixedpage', 'basic', 'Fixed page', '请尽量输入左侧菜单栏存在的链接', 'string', 'dashboard', '', 'required', '');
INSERT INTO `fa_config` VALUES (9, 'categorytype', 'dictionary', 'Category type', '', 'array', '{\"default\":\"Default\",\"page\":\"Page\",\"article\":\"Article\",\"test\":\"Test\"}', '', '', '');
INSERT INTO `fa_config` VALUES (10, 'configgroup', 'dictionary', 'Config group', '', 'array', '{\"basic\":\"Basic\",\"email\":\"Email\",\"dictionary\":\"Dictionary\",\"user\":\"User\",\"example\":\"Example\"}', '', '', '');
INSERT INTO `fa_config` VALUES (11, 'mail_type', 'email', 'Mail type', '选择邮件发送方式', 'select', '1', '[\"Please select\",\"SMTP\",\"Mail\"]', '', '');
INSERT INTO `fa_config` VALUES (12, 'mail_smtp_host', 'email', 'Mail smtp host', '错误的配置发送邮件会导致服务器超时', 'string', 'smtp.qq.com', '', '', '');
INSERT INTO `fa_config` VALUES (13, 'mail_smtp_port', 'email', 'Mail smtp port', '(不加密默认25,SSL默认465,TLS默认587)', 'string', '465', '', '', '');
INSERT INTO `fa_config` VALUES (14, 'mail_smtp_user', 'email', 'Mail smtp user', '（填写完整用户名）', 'string', '10000', '', '', '');
INSERT INTO `fa_config` VALUES (15, 'mail_smtp_pass', 'email', 'Mail smtp password', '（填写您的密码）', 'string', 'password', '', '', '');
INSERT INTO `fa_config` VALUES (16, 'mail_verify_type', 'email', 'Mail vertify type', '（SMTP验证方式[推荐SSL]）', 'select', '2', '[\"None\",\"TLS\",\"SSL\"]', '', '');
INSERT INTO `fa_config` VALUES (17, 'mail_from', 'email', 'Mail from', '', 'string', '10000@qq.com', '', '', '');
COMMIT;

-- ----------------------------
-- Table structure for fa_ems
-- ----------------------------
DROP TABLE IF EXISTS `fa_ems`;
CREATE TABLE `fa_ems` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `event` varchar(30) NOT NULL DEFAULT '' COMMENT '事件',
  `email` varchar(100) NOT NULL DEFAULT '' COMMENT '邮箱',
  `code` varchar(10) NOT NULL DEFAULT '' COMMENT '验证码',
  `times` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '验证次数',
  `ip` varchar(30) NOT NULL DEFAULT '' COMMENT 'IP',
  `createtime` int(10) unsigned DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='邮箱验证码表';

-- ----------------------------
-- Table structure for fa_sms
-- ----------------------------
DROP TABLE IF EXISTS `fa_sms`;
CREATE TABLE `fa_sms` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `event` varchar(30) NOT NULL DEFAULT '' COMMENT '事件',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `code` varchar(10) NOT NULL DEFAULT '' COMMENT '验证码',
  `times` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '验证次数',
  `ip` varchar(30) NOT NULL DEFAULT '' COMMENT 'IP',
  `createtime` int(10) unsigned DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='短信验证码表';

-- ----------------------------
-- Table structure for fa_statistical
-- ----------------------------
DROP TABLE IF EXISTS `fa_statistical`;
CREATE TABLE `fa_statistical` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `room_card` varchar(255) DEFAULT '',
  `club` int(11) DEFAULT NULL,
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for fa_test
-- ----------------------------
DROP TABLE IF EXISTS `fa_test`;
CREATE TABLE `fa_test` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '管理员ID',
  `category_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '分类ID(单选)',
  `category_ids` varchar(100) NOT NULL COMMENT '分类ID(多选)',
  `week` enum('monday','tuesday','wednesday') NOT NULL COMMENT '星期(单选):monday=星期一,tuesday=星期二,wednesday=星期三',
  `flag` set('hot','index','recommend') NOT NULL DEFAULT '' COMMENT '标志(多选):hot=热门,index=首页,recommend=推荐',
  `genderdata` enum('male','female') NOT NULL DEFAULT 'male' COMMENT '性别(单选):male=男,female=女',
  `hobbydata` set('music','reading','swimming') NOT NULL COMMENT '爱好(多选):music=音乐,reading=读书,swimming=游泳',
  `title` varchar(50) NOT NULL DEFAULT '' COMMENT '标题',
  `content` text NOT NULL COMMENT '内容',
  `image` varchar(100) NOT NULL DEFAULT '' COMMENT '图片',
  `images` varchar(1500) NOT NULL DEFAULT '' COMMENT '图片组',
  `attachfile` varchar(100) NOT NULL DEFAULT '' COMMENT '附件',
  `keywords` varchar(100) NOT NULL DEFAULT '' COMMENT '关键字',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `city` varchar(100) NOT NULL DEFAULT '' COMMENT '省市',
  `json` varchar(255) DEFAULT NULL COMMENT '配置:key=名称,value=值',
  `price` float(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '价格',
  `views` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '点击',
  `startdate` date DEFAULT NULL COMMENT '开始日期',
  `activitytime` datetime DEFAULT NULL COMMENT '活动时间(datetime)',
  `year` year(4) DEFAULT NULL COMMENT '年',
  `times` time DEFAULT NULL COMMENT '时间',
  `refreshtime` int(10) DEFAULT NULL COMMENT '刷新时间(int)',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `deletetime` int(10) DEFAULT NULL COMMENT '删除时间',
  `weigh` int(10) NOT NULL DEFAULT '0' COMMENT '权重',
  `switch` tinyint(1) NOT NULL DEFAULT '0' COMMENT '开关',
  `status` enum('normal','hidden') NOT NULL DEFAULT 'normal' COMMENT '状态',
  `state` enum('0','1','2') NOT NULL DEFAULT '1' COMMENT '状态值:0=禁用,1=正常,2=推荐',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='测试表';

-- ----------------------------
-- Records of fa_test
-- ----------------------------
BEGIN;
INSERT INTO `fa_test` VALUES (1, 0, 12, '12,13', 'monday', 'hot,index', 'male', 'music,reading', '我是一篇测试文章', '<p>我是测试内容</p>', '/assets/img/avatar.png', '/assets/img/avatar.png,/assets/img/qrcode.png', '/assets/img/avatar.png', '关键字', '描述', '广西壮族自治区/百色市/平果县', '{\"a\":\"1\",\"b\":\"2\"}', 0.00, 0, '2017-07-10', '2017-07-10 18:24:45', 2017, '18:24:45', 1499682285, 1499682526, 1499682526, NULL, 0, 1, 'normal', '1');
COMMIT;

-- ----------------------------
-- Table structure for fa_user
-- ----------------------------
DROP TABLE IF EXISTS `fa_user`;
CREATE TABLE `fa_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `group_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '组别ID',
  `username` varchar(32) NOT NULL DEFAULT '' COMMENT '用户名',
  `nickname` varchar(50) NOT NULL DEFAULT '' COMMENT '昵称',
  `password` varchar(32) NOT NULL DEFAULT '' COMMENT '密码',
  `salt` varchar(30) NOT NULL DEFAULT '' COMMENT '密码盐',
  `email` varchar(100) NOT NULL DEFAULT '' COMMENT '电子邮箱',
  `mobile` varchar(11) NOT NULL DEFAULT '' COMMENT '手机号',
  `avatar` varchar(255) NOT NULL DEFAULT '' COMMENT '头像',
  `level` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '等级',
  `gender` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '性别',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `bio` varchar(100) NOT NULL DEFAULT '' COMMENT '格言',
  `money` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '余额',
  `score` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '积分',
  `successions` int(10) unsigned NOT NULL DEFAULT '1' COMMENT '连续登录天数',
  `maxsuccessions` int(10) unsigned NOT NULL DEFAULT '1' COMMENT '最大连续登录天数',
  `prevtime` int(10) DEFAULT NULL COMMENT '上次登录时间',
  `logintime` int(10) DEFAULT NULL COMMENT '登录时间',
  `loginip` varchar(50) NOT NULL DEFAULT '' COMMENT '登录IP',
  `loginfailure` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '失败次数',
  `joinip` varchar(50) NOT NULL DEFAULT '' COMMENT '加入IP',
  `jointime` int(10) DEFAULT NULL COMMENT '加入时间',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `token` varchar(50) NOT NULL DEFAULT '' COMMENT 'Token',
  `status` varchar(30) NOT NULL DEFAULT '' COMMENT '状态',
  `verification` varchar(255) NOT NULL DEFAULT '' COMMENT '验证',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `username` (`username`) USING BTREE,
  KEY `email` (`email`) USING BTREE,
  KEY `mobile` (`mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='会员表';

-- ----------------------------
-- Records of fa_user
-- ----------------------------
BEGIN;
INSERT INTO `fa_user` VALUES (1, 1, 'admin', 'admin', 'c13f62012fd6a8fdf06b3452a94430e5', 'rpR6Bv', 'admin@163.com', '13888888888', '', 0, 0, '2017-04-15', '', 0.00, 0, 1, 1, 1516170492, 1516171614, '127.0.0.1', 0, '127.0.0.1', 1491461418, 0, 1516171614, '', 'normal', '');
COMMIT;

-- ----------------------------
-- Table structure for fa_user_group
-- ----------------------------
DROP TABLE IF EXISTS `fa_user_group`;
CREATE TABLE `fa_user_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT '' COMMENT '组名',
  `rules` text COMMENT '权限节点',
  `createtime` int(10) DEFAULT NULL COMMENT '添加时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `status` enum('normal','hidden') DEFAULT NULL COMMENT '状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='会员组表';

-- ----------------------------
-- Records of fa_user_group
-- ----------------------------
BEGIN;
INSERT INTO `fa_user_group` VALUES (1, '默认组', '1,2,3,4,5,6,7,8,9,10,11,12', 1515386468, 1516168298, 'normal');
COMMIT;

-- ----------------------------
-- Table structure for fa_user_money_log
-- ----------------------------
DROP TABLE IF EXISTS `fa_user_money_log`;
CREATE TABLE `fa_user_money_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '会员ID',
  `money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '变更余额',
  `before` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '变更前余额',
  `after` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '变更后余额',
  `memo` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='会员余额变动表';

-- ----------------------------
-- Table structure for fa_user_rule
-- ----------------------------
DROP TABLE IF EXISTS `fa_user_rule`;
CREATE TABLE `fa_user_rule` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(10) DEFAULT NULL COMMENT '父ID',
  `name` varchar(50) DEFAULT NULL COMMENT '名称',
  `title` varchar(50) DEFAULT '' COMMENT '标题',
  `remark` varchar(100) DEFAULT NULL COMMENT '备注',
  `ismenu` tinyint(1) DEFAULT NULL COMMENT '是否菜单',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `updatetime` int(10) DEFAULT NULL COMMENT '更新时间',
  `weigh` int(10) DEFAULT '0' COMMENT '权重',
  `status` enum('normal','hidden') DEFAULT NULL COMMENT '状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COMMENT='会员规则表';

-- ----------------------------
-- Records of fa_user_rule
-- ----------------------------
BEGIN;
INSERT INTO `fa_user_rule` VALUES (1, 0, 'index', '前台', '', 1, 1516168079, 1516168079, 1, 'normal');
INSERT INTO `fa_user_rule` VALUES (2, 0, 'api', 'API接口', '', 1, 1516168062, 1516168062, 2, 'normal');
INSERT INTO `fa_user_rule` VALUES (3, 1, 'user', '会员模块', '', 1, 1515386221, 1516168103, 12, 'normal');
INSERT INTO `fa_user_rule` VALUES (4, 2, 'user', '会员模块', '', 1, 1515386221, 1516168092, 11, 'normal');
INSERT INTO `fa_user_rule` VALUES (5, 3, 'index/user/login', '登录', '', 0, 1515386247, 1515386247, 5, 'normal');
INSERT INTO `fa_user_rule` VALUES (6, 3, 'index/user/register', '注册', '', 0, 1515386262, 1516015236, 7, 'normal');
INSERT INTO `fa_user_rule` VALUES (7, 3, 'index/user/index', '会员中心', '', 0, 1516015012, 1516015012, 9, 'normal');
INSERT INTO `fa_user_rule` VALUES (8, 3, 'index/user/profile', '个人资料', '', 0, 1516015012, 1516015012, 4, 'normal');
INSERT INTO `fa_user_rule` VALUES (9, 4, 'api/user/login', '登录', '', 0, 1515386247, 1515386247, 6, 'normal');
INSERT INTO `fa_user_rule` VALUES (10, 4, 'api/user/register', '注册', '', 0, 1515386262, 1516015236, 8, 'normal');
INSERT INTO `fa_user_rule` VALUES (11, 4, 'api/user/index', '会员中心', '', 0, 1516015012, 1516015012, 10, 'normal');
INSERT INTO `fa_user_rule` VALUES (12, 4, 'api/user/profile', '个人资料', '', 0, 1516015012, 1516015012, 3, 'normal');
COMMIT;

-- ----------------------------
-- Table structure for fa_user_score_log
-- ----------------------------
DROP TABLE IF EXISTS `fa_user_score_log`;
CREATE TABLE `fa_user_score_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '会员ID',
  `score` int(10) NOT NULL DEFAULT '0' COMMENT '变更积分',
  `before` int(10) NOT NULL DEFAULT '0' COMMENT '变更前积分',
  `after` int(10) NOT NULL DEFAULT '0' COMMENT '变更后积分',
  `memo` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='会员积分变动表';

-- ----------------------------
-- Table structure for fa_user_token
-- ----------------------------
DROP TABLE IF EXISTS `fa_user_token`;
CREATE TABLE `fa_user_token` (
  `token` varchar(50) NOT NULL COMMENT 'Token',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '会员ID',
  `createtime` int(10) DEFAULT NULL COMMENT '创建时间',
  `expiretime` int(10) DEFAULT NULL COMMENT '过期时间',
  PRIMARY KEY (`token`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='会员Token表';

SET FOREIGN_KEY_CHECKS = 1;
