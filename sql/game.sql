/*
 Navicat Premium Data Transfer

 Source Server         : 8.135.114.94-youyu
 Source Server Type    : MariaDB
 Source Server Version : 100508
 Source Host           : 172.16.5.58:3306
 Source Schema         : game

 Target Server Type    : MariaDB
 Target Server Version : 100508
 File Encoding         : 65001

 Date: 04/05/2021 15:22:49
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_club
-- ----------------------------
DROP TABLE IF EXISTS `t_club`;
CREATE TABLE `t_club` (
  `id` int(4) NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `owner` int(4) NOT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `type` smallint(1) DEFAULT 0 COMMENT '0是群 1联盟',
  `parent` int(4) DEFAULT NULL,
  `status` smallint(1) NOT NULL DEFAULT 0 COMMENT '营业状态 0正常 1打烊',
  `creator` int(4) DEFAULT NULL,
  `created_at` int(11) DEFAULT 0,
  `updated_at` int(11) DEFAULT 0,
  PRIMARY KEY (`id`,`owner`) USING BTREE,
  KEY `idx_club` (`id`) USING BTREE,
  KEY `idx_type` (`type`) USING BTREE,
  KEY `idx_club_type` (`id`,`type`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲友群或联盟表';

-- ----------------------------
-- Table structure for t_club_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_club_commission`;
CREATE TABLE `t_club_commission` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `club` int(4) NOT NULL,
  `commission` bigint(8) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`,`club`) USING BTREE,
  KEY `idx_club` (`club`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_club_gaming_blacklist
-- ----------------------------
DROP TABLE IF EXISTS `t_club_gaming_blacklist`;
CREATE TABLE `t_club_gaming_blacklist` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club_id` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_idx` (`club_id`,`guid`)
) ENGINE=InnoDB AUTO_INCREMENT=6628 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_club_member
-- ----------------------------
DROP TABLE IF EXISTS `t_club_member`;
CREATE TABLE `t_club_member` (
  `club` int(8) NOT NULL COMMENT 'club id',
  `guid` int(8) NOT NULL COMMENT '玩家id',
  `status` smallint(2) NOT NULL DEFAULT 0 COMMENT '成员状态 0：正常 1：已移除',
  PRIMARY KEY (`club`,`guid`) USING BTREE,
  UNIQUE KEY `idx_club_id` (`club`,`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲友群或联盟成员';

-- ----------------------------
-- Table structure for t_club_money
-- ----------------------------
DROP TABLE IF EXISTS `t_club_money`;
CREATE TABLE `t_club_money` (
  `club` int(11) NOT NULL,
  `money_id` int(4) NOT NULL,
  `money` bigint(8) NOT NULL,
  PRIMARY KEY (`club`,`money_id`) USING BTREE,
  KEY `index_club_money_id` (`club`,`money_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲友群或联盟金钱';

-- ----------------------------
-- Table structure for t_club_money_type
-- ----------------------------
DROP TABLE IF EXISTS `t_club_money_type`;
CREATE TABLE `t_club_money_type` (
  `money_id` int(4) NOT NULL,
  `club` int(4) NOT NULL,
  PRIMARY KEY (`money_id`,`club`) USING BTREE,
  KEY `index_club_money_type` (`club`,`money_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_club_role
-- ----------------------------
DROP TABLE IF EXISTS `t_club_role`;
CREATE TABLE `t_club_role` (
  `id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(4) NOT NULL,
  `role` tinyint(2) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_idx` (`club`,`guid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2414 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_notice
-- ----------------------------
DROP TABLE IF EXISTS `t_notice`;
CREATE TABLE `t_notice` (
  `id` varchar(64) NOT NULL,
  `club` int(11) DEFAULT NULL,
  `where` int(11) DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `content` text DEFAULT NULL,
  `start_time` text DEFAULT NULL,
  `end_time` text DEFAULT NULL,
  `update_time` bigint(20) DEFAULT NULL,
  `create_time` bigint(20) DEFAULT NULL,
  `play_count` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_t_notice_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_partner_member
-- ----------------------------
DROP TABLE IF EXISTS `t_partner_member`;
CREATE TABLE `t_partner_member` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  `partner` int(8) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_partner_mem` (`club`,`partner`,`guid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18694 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_player
-- ----------------------------
DROP TABLE IF EXISTS `t_player`;
CREATE TABLE `t_player` (
  `guid` int(8) NOT NULL COMMENT '全局唯一标识符',
  `is_android` int(1) NOT NULL DEFAULT 0 COMMENT '是机器人',
  `account` varchar(64) NOT NULL DEFAULT '' COMMENT '账号',
  `nickname` varchar(128) DEFAULT NULL COMMENT '昵称',
  `level` int(1) NOT NULL DEFAULT 0 COMMENT '玩家等级',
  `bank` bigint(8) NOT NULL DEFAULT 0 COMMENT '银行存款',
  `head_url` varchar(256) NOT NULL DEFAULT '0' COMMENT '头像',
  `phone` char(11) DEFAULT NULL COMMENT '手机号',
  `phone_type` varchar(255) DEFAULT NULL COMMENT '手机类型',
  `union_id` varchar(128) DEFAULT NULL COMMENT '微信union_id',
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  `is_collapse` tinyint(1) DEFAULT 0 COMMENT '是否破产，1破产，0不破产',
  `vip` tinyint(1) DEFAULT NULL,
  `status` tinyint(1) DEFAULT 1 COMMENT '是否可用 1可用 0封号',
  `promoter` int(8) DEFAULT NULL,
  `channel_id` varchar(128) DEFAULT NULL,
  `created_time` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`guid`) USING BTREE,
  KEY `idx_guid_createtime` (`guid`,`created_time`,`promoter`,`channel_id`) USING BTREE,
  KEY `idx_guid` (`guid`) USING BTREE,
  KEY `idx_time` (`created_time`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='玩家表';

-- ----------------------------
-- Table structure for t_player_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_player_commission`;
CREATE TABLE `t_player_commission` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  `money_id` int(4) NOT NULL,
  `commission` int(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_cgm` (`club`,`money_id`,`guid`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=319 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_player_money
-- ----------------------------
DROP TABLE IF EXISTS `t_player_money`;
CREATE TABLE `t_player_money` (
  `guid` int(8) NOT NULL COMMENT '玩家id',
  `money_id` int(4) NOT NULL DEFAULT 0 COMMENT '金钱类型 0金币 1房卡 2钻石',
  `money` bigint(8) NOT NULL DEFAULT 0 COMMENT '数量',
  `where` smallint(2) NOT NULL DEFAULT 0 COMMENT '存在哪儿 0玩家身上 1保险箱',
  PRIMARY KEY (`guid`,`money_id`,`where`) USING BTREE,
  KEY `idx_player_money` (`guid`,`money_id`,`where`) USING BTREE,
  KEY `idx_guid_money_id` (`guid`,`money_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='玩家金钱';

-- ----------------------------
-- Table structure for t_team_money
-- ----------------------------
DROP TABLE IF EXISTS `t_team_money`;
CREATE TABLE `t_team_money` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `money` bigint(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `guid` (`guid`,`club`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=129175 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_team_player_count
-- ----------------------------
DROP TABLE IF EXISTS `t_team_player_count`;
CREATE TABLE `t_team_player_count` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `count` int(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `guid` (`guid`,`club`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=129175 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_template
-- ----------------------------
DROP TABLE IF EXISTS `t_template`;
CREATE TABLE `t_template` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `description` varchar(1024) NOT NULL,
  `club` int(4) NOT NULL,
  `rule` varchar(1024) NOT NULL,
  `game_id` int(4) NOT NULL,
  `status` int(1) NOT NULL DEFAULT 0,
  `created_time` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_club` (`club`,`game_id`,`created_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3803 DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
