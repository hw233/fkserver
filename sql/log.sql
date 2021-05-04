/*
 Navicat Premium Data Transfer

 Source Server         : 8.135.114.94-youyu
 Source Server Type    : MariaDB
 Source Server Version : 100508
 Source Host           : 172.16.5.58:3306
 Source Schema         : log

 Target Server Type    : MariaDB
 Target Server Version : 100508
 File Encoding         : 65001

 Date: 04/05/2021 15:19:56
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_log_bug_report
-- ----------------------------
DROP TABLE IF EXISTS `t_log_bug_report`;
CREATE TABLE `t_log_bug_report` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(8) NOT NULL,
  `content` text NOT NULL,
  `create_time` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_guid_create_time` (`guid`,`create_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=434191 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_club_coin_hour_change
-- ----------------------------
DROP TABLE IF EXISTS `t_log_club_coin_hour_change`;
CREATE TABLE `t_log_club_coin_hour_change` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `money_id` int(4) NOT NULL,
  `reason` int(4) NOT NULL,
  `club` int(4) DEFAULT NULL,
  `game_id` int(4) DEFAULT NULL,
  `amount` int(4) NOT NULL,
  `time` int(8) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_money` (`money_id`,`reason`,`game_id`,`club`,`time`)
) ENGINE=InnoDB AUTO_INCREMENT=13769498 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_club_commission_contribute
-- ----------------------------
DROP TABLE IF EXISTS `t_log_club_commission_contribute`;
CREATE TABLE `t_log_club_commission_contribute` (
  `club_parent` int(4) NOT NULL,
  `club_son` int(4) NOT NULL,
  `commission` int(4) NOT NULL DEFAULT 0,
  `template` int(4) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`date`,`club_parent`,`club_son`,`template`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_log_club_commission_daily_contribute
-- ----------------------------
DROP TABLE IF EXISTS `t_log_club_commission_daily_contribute`;
CREATE TABLE `t_log_club_commission_daily_contribute` (
  `club_parent` int(4) NOT NULL,
  `club_son` int(4) NOT NULL,
  `commission` int(4) NOT NULL DEFAULT 0,
  `template` int(4) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`date`,`club_parent`,`club_son`,`template`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_log_club_msg
-- ----------------------------
DROP TABLE IF EXISTS `t_log_club_msg`;
CREATE TABLE `t_log_club_msg` (
  `id` bigint(8) NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `type` tinyint(2) NOT NULL,
  `operator` int(4) NOT NULL,
  `content` varchar(512) DEFAULT NULL,
  `created_time` bigint(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_club_oper_crated_tim` (`club`,`operator`,`created_time`,`type`) USING BTREE,
  KEY `idx_club` (`club`) USING BTREE,
  KEY `idx_type` (`type`) USING BTREE,
  KEY `idx_club_type` (`club`,`type`) USING BTREE,
  KEY `idx_club_type_create_time` (`club`,`type`,`created_time`) USING BTREE,
  KEY `idx_created_time` (`created_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=24254 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_coin_hour_change
-- ----------------------------
DROP TABLE IF EXISTS `t_log_coin_hour_change`;
CREATE TABLE `t_log_coin_hour_change` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `money_id` int(4) DEFAULT NULL,
  `reason` int(4) NOT NULL,
  `amount` int(4) NOT NULL,
  `time` int(8) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `money_id` (`money_id`,`time`,`reason`)
) ENGINE=InnoDB AUTO_INCREMENT=13763585 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_log_commission`;
CREATE TABLE `t_log_commission` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `club` int(4) NOT NULL,
  `money_id` int(4) NOT NULL,
  `commission` int(4) NOT NULL DEFAULT 0,
  `round_id` varchar(128) NOT NULL,
  `created_time` datetime NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_club` (`club`) USING BTREE,
  KEY `idx_round_id` (`round_id`) USING BTREE,
  KEY `idx_time` (`created_time`) USING BTREE,
  KEY `idx_club_time` (`club`,`created_time`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_game
-- ----------------------------
DROP TABLE IF EXISTS `t_log_game`;
CREATE TABLE `t_log_game` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `round_id` varchar(64) NOT NULL COMMENT '牌局id',
  `ext_round_id` varchar(64) NOT NULL COMMENT '整局id',
  `game_id` int(4) NOT NULL,
  `game_name` varchar(64) NOT NULL COMMENT '游戏类型 斗地主 炸金花 等',
  `log` mediumtext NOT NULL COMMENT '日志',
  `start_time` int(8) NOT NULL DEFAULT 0 COMMENT '开始时间',
  `end_time` int(8) NOT NULL DEFAULT 0 COMMENT '结束时间',
  `created_time` int(8) NOT NULL DEFAULT 0 COMMENT '创建时间',
  PRIMARY KEY (`id`,`round_id`,`ext_round_id`) USING BTREE,
  KEY `index_created_time` (`created_time`) USING BTREE,
  KEY `index_start_time` (`start_time`) USING BTREE,
  KEY `index_end_time` (`end_time`) USING BTREE,
  KEY `index_id_ext_id` (`round_id`,`ext_round_id`) USING BTREE,
  KEY `index_round_id` (`round_id`) USING BTREE,
  KEY `index_ext_id` (`ext_round_id`) USING BTREE,
  KEY `index_id_full` (`round_id`,`ext_round_id`,`start_time`,`end_time`,`created_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=9919677 DEFAULT CHARSET=utf8mb4 COMMENT='牌局日志记录'
 PARTITION BY KEY (`ext_round_id`)
PARTITIONS 60;

-- ----------------------------
-- Table structure for t_log_install_trace
-- ----------------------------
DROP TABLE IF EXISTS `t_log_install_trace`;
CREATE TABLE `t_log_install_trace` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `traceId` varchar(64) NOT NULL,
  `shareId` varchar(64) NOT NULL,
  `createtime` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `trace_sid_idx` (`traceId`,`shareId`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=28195 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_login
-- ----------------------------
DROP TABLE IF EXISTS `t_log_login`;
CREATE TABLE `t_log_login` (
  `id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `login_phone` varchar(256) DEFAULT NULL COMMENT '登录手机名字：ios，android',
  `login_phone_type` varchar(256) DEFAULT NULL COMMENT '登录手机具体型号',
  `login_version` varchar(256) DEFAULT NULL COMMENT '登录版本号',
  `login_channel_id` varchar(256) DEFAULT NULL COMMENT '登录渠道号',
  `login_package_name` varchar(256) DEFAULT NULL COMMENT '登录安装包名字',
  `login_ip` varchar(256) DEFAULT NULL COMMENT '登录IP',
  `channel_id` varchar(256) DEFAULT NULL COMMENT '渠道号',
  `login_time` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '登陆时间',
  `create_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '创建时间',
  `register_time` timestamp NULL DEFAULT NULL COMMENT '注册时间',
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  PRIMARY KEY (`id`,`create_time`) USING BTREE,
  KEY `index_logintime_channelid` (`login_time`,`channel_id`(191)) USING BTREE,
  KEY `index_time_id_seniorpromoter` (`login_time`,`platform_id`(191)) USING BTREE,
  KEY `index_guid_logintime` (`guid`,`login_time`,`create_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=5112214 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='玩家登录日志表'
 PARTITION BY HASH (unix_timestamp(`create_time`) DIV (60 * 60 * 24) MOD 60)
PARTITIONS 60;

-- ----------------------------
-- Table structure for t_log_money
-- ----------------------------
DROP TABLE IF EXISTS `t_log_money`;
CREATE TABLE `t_log_money` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `guid` int(11) NOT NULL DEFAULT 0 COMMENT '全局唯一标识符',
  `money_id` int(4) NOT NULL COMMENT '钱类型 0、金币 1、房卡 2、钻石',
  `old_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '操作前的钱',
  `new_money` bigint(20) NOT NULL DEFAULT 0 COMMENT '操作后的钱',
  `where` smallint(2) NOT NULL DEFAULT 0 COMMENT '哪的钱',
  `reason` int(11) NOT NULL DEFAULT 0 COMMENT '操作原因',
  `reason_ext` varchar(128) DEFAULT NULL COMMENT '操作原因附加数据',
  `created_time` bigint(8) NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`,`created_time`) USING BTREE,
  KEY `index_guid_time` (`guid`,`created_time`,`money_id`,`reason`) USING BTREE,
  KEY `index_time_mid` (`created_time`,`money_id`) USING BTREE,
  KEY `index_time` (`created_time`) USING BTREE,
  KEY `index_reason` (`reason`) USING BTREE,
  KEY `index_money_id` (`money_id`) USING BTREE,
  KEY `index_reason_ext` (`reason_ext`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=56576725 DEFAULT CHARSET=utf8mb4 COMMENT='金钱变动日志表'
 PARTITION BY HASH (`created_time` DIV (60 * 60 * 24 * 1000) MOD 120)
PARTITIONS 120;

-- ----------------------------
-- Table structure for t_log_money_club
-- ----------------------------
DROP TABLE IF EXISTS `t_log_money_club`;
CREATE TABLE `t_log_money_club` (
  `id` bigint(8) NOT NULL AUTO_INCREMENT,
  `club` int(4) NOT NULL,
  `money_id` int(4) DEFAULT NULL,
  `old_money` int(4) NOT NULL,
  `new_money` int(4) NOT NULL,
  `opt_type` int(2) NOT NULL,
  `opt_ext` varchar(1024) DEFAULT NULL,
  `created_time` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_partner_statistics_daily
-- ----------------------------
DROP TABLE IF EXISTS `t_log_partner_statistics_daily`;
CREATE TABLE `t_log_partner_statistics_daily` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `gaming_count` int(4) NOT NULL DEFAULT 0,
  `commission` int(4) NOT NULL,
  `club` int(4) DEFAULT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_idx` (`guid`,`club`,`date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_log_player_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_commission`;
CREATE TABLE `t_log_player_commission` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  `money_id` int(4) NOT NULL,
  `commission` int(4) NOT NULL,
  `round_id` varchar(128) DEFAULT NULL,
  `create_time` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_club_guid_money_id,round` (`club`,`guid`,`money_id`,`round_id`) USING BTREE,
  KEY `idx_time` (`create_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=449 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_log_player_commission_contribute
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_commission_contribute`;
CREATE TABLE `t_log_player_commission_contribute` (
  `id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `parent` int(4) NOT NULL,
  `son` int(4) NOT NULL,
  `commission` int(4) NOT NULL,
  `template` int(4) DEFAULT NULL,
  `club` int(4) NOT NULL,
  `create_time` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `unique_idx` (`parent`,`son`,`template`,`create_time`,`club`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1891 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_player_daily_big_win_count
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_daily_big_win_count`;
CREATE TABLE `t_log_player_daily_big_win_count` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `game_id` int(4) NOT NULL,
  `count` int(4) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `guid` (`guid`,`club`,`date`,`game_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1378402 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_player_daily_commission_contribute
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_daily_commission_contribute`;
CREATE TABLE `t_log_player_daily_commission_contribute` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `parent` int(4) NOT NULL,
  `son` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `template` int(4) DEFAULT NULL,
  `commission` int(8) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `parent` (`parent`,`son`,`club`,`date`,`template`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=79651 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_player_daily_play_count
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_daily_play_count`;
CREATE TABLE `t_log_player_daily_play_count` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `game_id` int(4) NOT NULL,
  `count` int(4) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `guid` (`guid`,`club`,`date`,`game_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3387544 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_player_daily_win_lose
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_daily_win_lose`;
CREATE TABLE `t_log_player_daily_win_lose` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `game_id` int(4) NOT NULL,
  `money` bigint(8) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `guid` (`guid`,`club`,`date`,`game_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3221299 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_log_player_game
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_game`;
CREATE TABLE `t_log_player_game` (
  `id` bigint(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `chair_id` int(11) NOT NULL,
  `round_id` varchar(128) CHARACTER SET utf16 NOT NULL,
  `created_time` int(8) NOT NULL,
  PRIMARY KEY (`id`,`guid`,`round_id`,`chair_id`),
  UNIQUE KEY `idx_guid_chair_round` (`guid`,`chair_id`,`round_id`) USING BTREE,
  KEY `idx_time` (`created_time`) USING BTREE,
  KEY `idx_guid_round` (`guid`,`round_id`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1904 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1
 PARTITION BY KEY (`guid`)
PARTITIONS 60;

-- ----------------------------
-- Table structure for t_log_player_round
-- ----------------------------
DROP TABLE IF EXISTS `t_log_player_round`;
CREATE TABLE `t_log_player_round` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `round` varchar(128) NOT NULL,
  `create_time` int(8) NOT NULL,
  PRIMARY KEY (`id`,`guid`,`round`) USING BTREE,
  UNIQUE KEY `guid` (`guid`,`round`) USING BTREE,
  KEY `idx_full` (`guid`,`round`,`create_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=4156320 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC
 PARTITION BY KEY (`guid`)
PARTITIONS 60;

-- ----------------------------
-- Table structure for t_log_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_log_recharge`;
CREATE TABLE `t_log_recharge` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `source_id` int(4) NOT NULL DEFAULT 1 COMMENT '源id',
  `target_id` int(4) NOT NULL COMMENT '目标id',
  `type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '交互：1 club-player 2player-club 3club-club',
  `operator` int(4) NOT NULL COMMENT '操作者',
  `money` int(4) DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `created_time` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idex_id_ct_type` (`type`,`created_time`,`source_id`,`target_id`) USING BTREE,
  KEY `index_type` (`type`) USING BTREE,
  KEY `idx_s_t` (`source_id`,`target_id`) USING BTREE,
  KEY `idx_time` (`created_time`) USING BTREE,
  KEY `idx_oper` (`operator`) USING BTREE,
  KEY `idx_oper_s_t` (`source_id`,`target_id`,`created_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=4257 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1 COMMENT='充值日志表';

-- ----------------------------
-- Table structure for t_log_round
-- ----------------------------
DROP TABLE IF EXISTS `t_log_round`;
CREATE TABLE `t_log_round` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `round` varchar(128) NOT NULL COMMENT '局id',
  `game_id` int(4) DEFAULT NULL,
  `game_name` varchar(255) DEFAULT NULL,
  `table_id` int(8) NOT NULL COMMENT '桌子id',
  `club` int(8) DEFAULT NULL COMMENT '群id',
  `template` int(8) DEFAULT NULL COMMENT '模板id',
  `rule` text DEFAULT NULL,
  `log` text DEFAULT NULL,
  `start_time` int(8) NOT NULL,
  `end_time` int(8) NOT NULL,
  `create_time` int(8) NOT NULL,
  PRIMARY KEY (`id`,`round`) USING BTREE,
  UNIQUE KEY `uniq_round` (`round`) USING BTREE,
  KEY `idx_time` (`start_time`,`end_time`,`create_time`) USING BTREE,
  KEY `idx_round_club_table` (`round`,`game_id`,`table_id`,`club`,`template`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=717176 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='玩家游戏回合记录'
 PARTITION BY KEY (`round`)
PARTITIONS 60;

-- ----------------------------
-- Table structure for t_log_round_money
-- ----------------------------
DROP TABLE IF EXISTS `t_log_round_money`;
CREATE TABLE `t_log_round_money` (
  `id` bigint(8) NOT NULL AUTO_INCREMENT,
  `round` varchar(128) CHARACTER SET utf16 NOT NULL,
  `guid` int(4) NOT NULL,
  `money` int(4) NOT NULL,
  `create_time` int(8) NOT NULL,
  PRIMARY KEY (`id`,`guid`,`round`),
  KEY `idx_round_guid` (`round`,`guid`) USING HASH
) ENGINE=MyISAM AUTO_INCREMENT=4004972 DEFAULT CHARSET=utf8
 PARTITION BY KEY (`round`)
PARTITIONS 60;

-- ----------------------------
-- Table structure for t_log_share_code
-- ----------------------------
DROP TABLE IF EXISTS `t_log_share_code`;
CREATE TABLE `t_log_share_code` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `sid` varchar(128) NOT NULL,
  `param` varchar(512) NOT NULL,
  `createtime` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `sid_idx` (`sid`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=1529 DEFAULT CHARSET=utf8mb4 PAGE_CHECKSUM=1;

-- ----------------------------
-- Table structure for t_log_team_daily_play_count
-- ----------------------------
DROP TABLE IF EXISTS `t_log_team_daily_play_count`;
CREATE TABLE `t_log_team_daily_play_count` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) DEFAULT NULL,
  `count` int(4) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `guid` (`guid`,`club`,`date`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20502364 DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;
