/*
 Navicat Premium Data Transfer

 Source Server         : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com
 Source Server Type    : MySQL
 Source Server Version : 50726
 Source Host           : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com:3306
 Source Schema         : log

 Target Server Type    : MySQL
 Target Server Version : 50726
 File Encoding         : 65001

 Date: 02/06/2020 15:13:18
*/

CREATE DATABASE IF NOT EXISTS log;
USE log;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_admin_money_log
-- ----------------------------
DROP TABLE IF EXISTS `t_admin_money_log`;
CREATE TABLE `t_admin_money_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(10) DEFAULT '0' COMMENT '玩家ID',
  `money` mediumint(8) DEFAULT '0' COMMENT '充值金额',
  `money_number` mediumint(8) DEFAULT '0' COMMENT '充值数量',
  `type` tinyint(1) DEFAULT '0' COMMENT '0房卡',
  `desc` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT '' COMMENT '备注',
  `admin_id` mediumint(5) DEFAULT '0' COMMENT '管理员ID',
  `top_up_type` tinyint(1) DEFAULT '1' COMMENT '充值类型 1购卡  2 转移',
  `created_at` int(10) DEFAULT '0' COMMENT '添加时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=latin1 COMMENT='管理员充值记录表';

-- ----------------------------
-- Table structure for t_agentstransfer_tj
-- ----------------------------
DROP TABLE IF EXISTS `t_agentstransfer_tj`;
CREATE TABLE `t_agentstransfer_tj` (
  `agents_guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `player_guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `transfer_id` varchar(64) NOT NULL COMMENT '交易id',
  `transfer_type` int(11) NOT NULL COMMENT '1进货 2出售 3回收',
  `transfer_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '交易金额',
  `agents_old_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的银行存款',
  `agents_new_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的银行存款',
  `player_old_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的银行存款',
  `player_new_bank` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的银行存款',
  `transfer_status` int(4) NOT NULL COMMENT '处理结果',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`transfer_id`,`created_time`) USING BTREE,
  KEY `agents_guid` (`agents_guid`) USING BTREE,
  KEY `player_guid` (`player_guid`) USING BTREE,
  KEY `type_s` (`transfer_type`,`transfer_status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='代理商转账表';

-- ----------------------------
-- Table structure for t_day_log
-- ----------------------------
DROP TABLE IF EXISTS `t_day_log`;
CREATE TABLE `t_day_log` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `new_users` mediumint(8) DEFAULT '0' COMMENT '新增用户',
  `new_agent` mediumint(8) DEFAULT '0' COMMENT '新增代理',
  `new_money` mediumint(8) DEFAULT '0' COMMENT '房卡充值',
  `money_expend` mediumint(8) DEFAULT '0' COMMENT '房卡消耗',
  `mj_money_expend` mediumint(8) DEFAULT '0' COMMENT '贵州麻将 房卡消耗',
  `created_at` int(10) DEFAULT '0' COMMENT '添加时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=latin1 COMMENT='每日人数房卡日志';

-- ----------------------------
-- Table structure for t_log_bank
-- ----------------------------
DROP TABLE IF EXISTS `t_log_bank`;
CREATE TABLE `t_log_bank` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `time` timestamp NULL DEFAULT NULL COMMENT '记录发生时间',
  `guid` int(11) NOT NULL DEFAULT '0' COMMENT '全局唯一标识符',
  `nickname` varchar(64) DEFAULT NULL COMMENT '昵称',
  `phone` varchar(256) DEFAULT NULL COMMENT '手机名字：ios，android',
  `opt_type` int(11) NOT NULL DEFAULT '0' COMMENT '交易类型：0存入，1取出',
  `money` int(11) DEFAULT NULL COMMENT '变动金币',
  `old_money` int(11) DEFAULT NULL COMMENT '开始金币',
  `new_money` int(11) DEFAULT NULL COMMENT '结束金币',
  `old_bank` int(11) DEFAULT NULL COMMENT '开始银行金币',
  `new_bank` int(11) DEFAULT NULL COMMENT '结束银行金币',
  `ip` varchar(256) DEFAULT NULL COMMENT 'IP地址',
  `gameid` int(11) NOT NULL COMMENT '游戏id',
  KEY `index_time` (`time`) USING BTREE,
  KEY `index_guid` (`guid`) USING BTREE,
  KEY `index_opt_type` (`opt_type`) USING BTREE,
  KEY `index_id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8 COMMENT='银行日志表';

-- ----------------------------
-- Table structure for t_log_bankrupt
-- ----------------------------
DROP TABLE IF EXISTS `t_log_bankrupt`;
CREATE TABLE `t_log_bankrupt` (
  `day` date NOT NULL COMMENT '日期',
  `guid` int(11) NOT NULL COMMENT '玩家ID',
  `times_bkt` int(11) NOT NULL DEFAULT '0' COMMENT '破产次数',
  `times_pay` int(11) NOT NULL DEFAULT '0' COMMENT '破产后充值次数',
  `bag_id` varchar(255) NOT NULL COMMENT '渠道包Id',
  `plat_id` varchar(255) NOT NULL COMMENT '分发平台ID',
  PRIMARY KEY (`day`,`guid`) USING BTREE,
  KEY `idx_guid` (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家破产统计表';

-- ----------------------------
-- Table structure for t_log_bet_flow
-- ----------------------------
DROP TABLE IF EXISTS `t_log_bet_flow`;
CREATE TABLE `t_log_bet_flow` (
  `pid` int(11) NOT NULL COMMENT '玩家id',
  `id` bigint(255) NOT NULL,
  `ppid` int(11) NOT NULL COMMENT '玩家父id',
  `self_flow` bigint(255) NOT NULL COMMENT '自己下注流水',
  `team_flow` bigint(255) NOT NULL COMMENT '团队下注流水',
  `date` date NOT NULL COMMENT '日期'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='玩家下注流水表';

-- ----------------------------
-- Table structure for t_log_club_commission_daily_contribute
-- ----------------------------
DROP TABLE IF EXISTS `t_log_club_commission_daily_contribute`;
CREATE TABLE `t_log_club_commission_daily_contribute` (
  `club_parent` int(4) NOT NULL,
  `club_son` int(4) NOT NULL,
  `commission` int(4) NOT NULL DEFAULT '0',
  `template` int(4) NOT NULL,
  `date` int(8) NOT NULL,
  PRIMARY KEY (`date`,`club_parent`,`club_son`,`template`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for t_log_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_log_commission`;
CREATE TABLE `t_log_commission` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `club` int(4) NOT NULL,
  `money_id` int(4) NOT NULL,
  `commission` int(4) NOT NULL DEFAULT '0',
  `round_id` varchar(255) NOT NULL,
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=153 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_log_game
-- ----------------------------
DROP TABLE IF EXISTS `t_log_game`;
CREATE TABLE `t_log_game` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `round_id` varchar(64) NOT NULL COMMENT '牌局id',
  `ext_round_id` varchar(64) DEFAULT NULL COMMENT '整局id',
  `game_id` int(4) NOT NULL,
  `game_name` varchar(64) NOT NULL COMMENT '游戏类型 斗地主 炸金花 等',
  `log` text NOT NULL COMMENT '日志',
  `start_time` int(8) NOT NULL DEFAULT '0' COMMENT '开始时间',
  `end_time` int(8) NOT NULL DEFAULT '0' COMMENT '结束时间',
  `created_time` int(8) NOT NULL DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_id` (`round_id`) USING BTREE,
  KEY `index_created_time` (`created_time`) USING BTREE,
  KEY `index_start_time` (`start_time`) USING BTREE,
  KEY `index_end_time` (`end_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=422 DEFAULT CHARSET=utf8mb4 COMMENT='牌局日志记录';

-- ----------------------------
-- Table structure for t_log_game_money
-- ----------------------------
DROP TABLE IF EXISTS `t_log_game_money`;
CREATE TABLE `t_log_game_money` (
  `guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `type` int(11) NOT NULL COMMENT '1 loss 2 win',
  `gameid` int(11) NOT NULL COMMENT 'gameid',
  `game_name` varchar(64) DEFAULT NULL COMMENT '游戏名字',
  `money_id` int(4) NOT NULL COMMENT '钱类型 0、金币 1、房卡 2、钻石',
  `old_money` int(8) NOT NULL DEFAULT '0' COMMENT '游戏前的钱',
  `new_money` int(8) NOT NULL DEFAULT '0' COMMENT '游戏后的钱',
  `tax` int(8) DEFAULT NULL COMMENT '游戏扣税',
  `change_money` int(8) NOT NULL DEFAULT '0' COMMENT '变动金币',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `round_id` varchar(64) NOT NULL COMMENT '牌局id',
  KEY `index_guid` (`guid`) USING BTREE,
  KEY `index_created_time` (`created_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='游戏金钱日志表';

-- ----------------------------
-- Table structure for t_log_game_money_robot
-- ----------------------------
DROP TABLE IF EXISTS `t_log_game_money_robot`;
CREATE TABLE `t_log_game_money_robot` (
  `guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `type` int(11) NOT NULL COMMENT '1 loss 2 win',
  `gameid` int(11) NOT NULL COMMENT 'gameid',
  `game_name` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '游戏名字',
  `phone_type` varchar(64) CHARACTER SET utf8 DEFAULT NULL COMMENT '终端类型',
  `money_id` smallint(2) NOT NULL COMMENT '钱类型 0、金币 1、房卡 2、钻石',
  `old_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '游戏前的钱',
  `new_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '游戏后的钱',
  `tax` bigint(20) DEFAULT NULL COMMENT '游戏扣税',
  `change_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动金币',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `id` varchar(64) CHARACTER SET utf8 NOT NULL COMMENT '牌局id',
  `platform_id` varchar(256) CHARACTER SET utf8 DEFAULT '0' COMMENT '平台id',
  KEY `index_guid` (`guid`) USING BTREE,
  KEY `index_created_time` (`created_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='机器人游戏金钱日志表';

-- ----------------------------
-- Table structure for t_log_gamestatistics
-- ----------------------------
DROP TABLE IF EXISTS `t_log_gamestatistics`;
CREATE TABLE `t_log_gamestatistics` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `winTimes` int(16) NOT NULL DEFAULT '0' COMMENT '赢钱次数',
  `winMoney` bigint(20) NOT NULL DEFAULT '0' COMMENT '所有赢的钱',
  `lossTimes` int(16) NOT NULL DEFAULT '0' COMMENT '输钱次数',
  `lossMoney` bigint(20) NOT NULL DEFAULT '0' COMMENT '所有输的钱',
  `tax` bigint(20) NOT NULL DEFAULT '0' COMMENT '所产生的税收',
  `type` varchar(64) CHARACTER SET utf8 NOT NULL COMMENT '类型 total 总共, land 斗地主,ox 百人牛牛,slotma 老虎机,zhajinhua 炸金花',
  `TJTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '统计时间',
  PRIMARY KEY (`guid`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='游戏数据统计表';

-- ----------------------------
-- Table structure for t_log_login
-- ----------------------------
DROP TABLE IF EXISTS `t_log_login`;
CREATE TABLE `t_log_login` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `login_phone` varchar(256) DEFAULT NULL COMMENT '登录手机名字：ios，android',
  `login_phone_type` varchar(256) DEFAULT NULL COMMENT '登录手机具体型号',
  `login_version` varchar(256) DEFAULT NULL COMMENT '登录版本号',
  `login_channel_id` varchar(256) DEFAULT NULL COMMENT '登录渠道号',
  `login_package_name` varchar(256) DEFAULT NULL COMMENT '登录安装包名字',
  `login_imei` varchar(256) DEFAULT NULL COMMENT '登录设备唯一码',
  `login_ip` varchar(256) DEFAULT NULL COMMENT '登录IP',
  `channel_id` varchar(256) DEFAULT NULL COMMENT '渠道号',
  `login_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登陆时间',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `register_time` timestamp NULL DEFAULT NULL COMMENT '注册时间',
  `is_guest` int(11) NOT NULL DEFAULT '0' COMMENT '是否是游客 1是游客',
  `deprecated_imei` varchar(256) DEFAULT NULL COMMENT '旧登录设备唯一\n码',
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  `seniorpromoter` int(11) NOT NULL DEFAULT '0' COMMENT '所属推广员guid',
  KEY `index_guid_logintime` (`guid`,`login_time`) USING BTREE,
  KEY `index_logintime_channelid` (`login_time`,`channel_id`(191)) USING BTREE,
  KEY `index_time_id_seniorpromoter` (`login_time`,`platform_id`(191),`seniorpromoter`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='玩家登录日志表';

-- ----------------------------
-- Table structure for t_log_money
-- ----------------------------
DROP TABLE IF EXISTS `t_log_money`;
CREATE TABLE `t_log_money` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `guid` int(11) NOT NULL DEFAULT '0' COMMENT '全局唯一标识符',
  `money_id` int(4) NOT NULL COMMENT '钱类型 0、金币 1、房卡 2、钻石',
  `old_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作前的钱',
  `new_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '操作后的钱',
  `where` smallint(2) NOT NULL DEFAULT '0' COMMENT '哪的钱',
  `reason` int(11) NOT NULL DEFAULT '0' COMMENT '操作原因',
  `reason_ext` varchar(1024) DEFAULT NULL COMMENT '操作原因附加数据',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  KEY `index_id` (`id`) USING BTREE,
  KEY `index_guid_time` (`guid`,`created_time`) USING BTREE,
  KEY `index_time` (`created_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2222 DEFAULT CHARSET=utf8mb4 COMMENT='金钱变动日志表';

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
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=680 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_log_recharge
-- ----------------------------
DROP TABLE IF EXISTS `t_log_recharge`;
CREATE TABLE `t_log_recharge` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `source_id` int(4) NOT NULL DEFAULT '1' COMMENT '源id',
  `target_id` int(4) NOT NULL COMMENT '目标id',
  `type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '交互：1 club-player 2player-club 3club-club',
  `operator` int(4) NOT NULL COMMENT '操作者',
  `created_time` int(8) NOT NULL,
  KEY `index_id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=94 DEFAULT CHARSET=utf8mb4 COMMENT='充值日志表';

-- ----------------------------
-- Table structure for t_log_robot_money_tj
-- ----------------------------
DROP TABLE IF EXISTS `t_log_robot_money_tj`;
CREATE TABLE `t_log_robot_money_tj` (
  `guid` int(20) NOT NULL COMMENT '用户ID',
  `is_banker` int(11) NOT NULL COMMENT '是否庄家1是,0不是',
  `winorlose` int(11) NOT NULL COMMENT '1 loss 2 win',
  `gameid` int(11) NOT NULL,
  `game_name` varchar(64) DEFAULT NULL COMMENT '游戏名字',
  `old_money` bigint(20) NOT NULL COMMENT '游戏前的钱',
  `new_money` bigint(20) NOT NULL COMMENT '游戏后的钱',
  `tax` bigint(20) DEFAULT '0' COMMENT '游戏扣税',
  `money_change` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动金币',
  `id` varchar(64) NOT NULL COMMENT '牌局id',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  KEY `index_guid` (`guid`) USING BTREE,
  KEY `index_created_time` (`created_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='机器人金币变动日志表';

-- ----------------------------
-- Table structure for t_log_round
-- ----------------------------
DROP TABLE IF EXISTS `t_log_round`;
CREATE TABLE `t_log_round` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `round` varchar(128) NOT NULL COMMENT '局id',
  `table_id` int(11) DEFAULT NULL COMMENT '桌子id',
  `guid` int(11) NOT NULL COMMENT '玩家id',
  `club` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_unique_round_guid` (`round`,`guid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1225 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='玩家游戏回合记录';

SET FOREIGN_KEY_CHECKS = 1;
