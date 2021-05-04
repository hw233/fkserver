/*
 Navicat Premium Data Transfer

 Source Server         : 8.135.114.94-youyu
 Source Server Type    : MariaDB
 Source Server Version : 100508
 Source Host           : 172.16.5.58:3306
 Source Schema         : account

 Target Server Type    : MariaDB
 Target Server Version : 100508
 File Encoding         : 65001

 Date: 04/05/2021 15:23:43
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_account
-- ----------------------------
DROP TABLE IF EXISTS `t_account`;
CREATE TABLE `t_account` (
  `guid` int(8) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `account` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '账号',
  `password` varchar(32) CHARACTER SET utf8 DEFAULT NULL COMMENT '密码',
  `is_guest` int(11) NOT NULL DEFAULT 0 COMMENT '是否是游客 1是游客',
  `nickname` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '昵称',
  `head_url` varchar(255) CHARACTER SET utf8 DEFAULT '' COMMENT '头像',
  `openid` char(60) CHARACTER SET utf8 DEFAULT '' COMMENT 'openid',
  `vip` int(11) NOT NULL DEFAULT 0 COMMENT 'vip等级',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `register_time` timestamp NULL DEFAULT NULL COMMENT '注册时间',
  `login_time` timestamp NULL DEFAULT NULL COMMENT '登陆时间',
  `logout_time` timestamp NULL DEFAULT NULL COMMENT '退出时间',
  `online_time` int(11) DEFAULT 0 COMMENT '累计在线时间',
  `login_count` int(11) DEFAULT 1 COMMENT '登录次数',
  `phone` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '手机名字：ios，android',
  `phone_type` varchar(256) CHARACTER SET utf8 DEFAULT NULL COMMENT '手机具体型号',
  `union_id` varchar(128) DEFAULT NULL COMMENT '微信unionid',
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
  `risk` tinyint(4) DEFAULT 0 COMMENT '危险等级0-9  9最危险',
  `inviter_guid` int(11) DEFAULT 0 COMMENT '邀请人的id',
  `invite_code` varchar(32) CHARACTER SET utf8 DEFAULT '0' COMMENT '邀请码',
  `platform_id` varchar(256) CHARACTER SET utf8 DEFAULT '0' COMMENT '平台id',
  `seniorpromoter` int(11) DEFAULT 0 COMMENT '所属推广员guid',
  `type` tinyint(1) DEFAULT 0 COMMENT '默认值：0,1:线上推广员,2:线下推广员',
  `level` tinyint(1) DEFAULT 0 COMMENT '默认值:0,待激活:99,1-5一到五级推广员',
  `promoter_time` timestamp NULL DEFAULT NULL COMMENT '成为推广员时间',
  `shared_id` varchar(255) CHARACTER SET utf8 DEFAULT NULL COMMENT '共享设备码',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9999605 DEFAULT CHARSET=utf8mb4 COMMENT='账号表';

-- ----------------------------
-- Table structure for t_agent
-- ----------------------------
DROP TABLE IF EXISTS `t_agent`;
CREATE TABLE `t_agent` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '代理ID',
  `mobile` char(12) DEFAULT '' COMMENT '代理手机号码',
  `password` varchar(64) DEFAULT '' COMMENT '代理密码',
  `guid` int(10) DEFAULT 0 COMMENT '游戏ID',
  `nickname` char(15) CHARACTER SET utf8mb4 DEFAULT '' COMMENT '昵称',
  `desc` varchar(255) DEFAULT '' COMMENT '备注',
  `type` tinyint(1) DEFAULT 1 COMMENT '类型 1代理员 2推广员',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态  1启用 2删除',
  `created_at` int(10) DEFAULT 0 COMMENT '添加时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1 COMMENT='代理表';

-- ----------------------------
-- Table structure for t_channel
-- ----------------------------
DROP TABLE IF EXISTS `t_channel`;
CREATE TABLE `t_channel` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` varchar(1024) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_channel_conf
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_conf`;
CREATE TABLE `t_channel_conf` (
  `id` int(8) NOT NULL,
  `channel` int(8) NOT NULL,
  `price` float(8,2) NOT NULL,
  `discount_rate` float(8,2) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_channel_invite
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite`;
CREATE TABLE `t_channel_invite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` varchar(255) DEFAULT NULL COMMENT '渠道号',
  `channel_lock` tinyint(3) DEFAULT 0 COMMENT '1开启 0关闭',
  `big_lock` tinyint(3) DEFAULT 1 COMMENT '1开启 0关闭',
  `tax_rate` int(11) unsigned NOT NULL DEFAULT 1 COMMENT '税率 百分比',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_coin_price
-- ----------------------------
DROP TABLE IF EXISTS `t_coin_price`;
CREATE TABLE `t_coin_price` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `money_id` int(4) NOT NULL DEFAULT 0,
  `count` int(4) NOT NULL,
  `money` int(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf16;

-- ----------------------------
-- Table structure for t_feedback
-- ----------------------------
DROP TABLE IF EXISTS `t_feedback`;
CREATE TABLE `t_feedback` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `processing_status` int(11) DEFAULT NULL,
  `guid` int(11) DEFAULT NULL,
  `reply_id` int(11) DEFAULT NULL,
  `account` int(11) DEFAULT NULL,
  `content` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `is_readme` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `author` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `processing_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
