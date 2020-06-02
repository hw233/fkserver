/*
 Navicat Premium Data Transfer

 Source Server         : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com
 Source Server Type    : MySQL
 Source Server Version : 50726
 Source Host           : rm-wz94y9xl0w2t60i92.mysql.rds.aliyuncs.com:3306
 Source Schema         : game

 Target Server Type    : MySQL
 Target Server Version : 50726
 File Encoding         : 65001

 Date: 02/06/2020 15:12:30
*/

CREATE DATABASE IF NOT EXISTS game;
USE game;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_bag
-- ----------------------------
DROP TABLE IF EXISTS `t_bag`;
CREATE TABLE `t_bag` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `pb_items` blob COMMENT '所有物品',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='背包表';

-- ----------------------------
-- Table structure for t_bank_save_back
-- ----------------------------
DROP TABLE IF EXISTS `t_bank_save_back`;
CREATE TABLE `t_bank_save_back` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `save_back_money` bigint(20) NOT NULL DEFAULT '0' COMMENT '回存银行存款',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '状态:0 待回存  1 回存成功 ',
  `before_bank` bigint(20) DEFAULT NULL COMMENT '回存前银行金钱',
  `after_bank` bigint(20) DEFAULT NULL COMMENT '回存后银行金钱',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `guid_status` (`guid`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_bank_statement
-- ----------------------------
DROP TABLE IF EXISTS `t_bank_statement`;
CREATE TABLE `t_bank_statement` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '银行流水ID',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `time` timestamp NULL DEFAULT NULL COMMENT '记录时间',
  `opt` int(11) NOT NULL DEFAULT '0' COMMENT '操作类型',
  `target` varchar(64) DEFAULT NULL COMMENT '目标',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '改变的钱',
  `bank_balance` int(11) NOT NULL DEFAULT '0' COMMENT '当前剩余的钱',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_guid` (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='银行流水表';

-- ----------------------------
-- Table structure for t_bonus_activity
-- ----------------------------
DROP TABLE IF EXISTS `t_bonus_activity`;
CREATE TABLE `t_bonus_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '红包活动id',
  `start_time` datetime DEFAULT NULL COMMENT '红包活动开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '红包活动结束时间',
  `cfg` text COMMENT '红包配置',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `platform_id` int(11) DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_start_time` (`start_time`) USING BTREE,
  KEY `index_end_time` (`end_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='红包活动表';

-- ----------------------------
-- Table structure for t_bonus_game_statistics
-- ----------------------------
DROP TABLE IF EXISTS `t_bonus_game_statistics`;
CREATE TABLE `t_bonus_game_statistics` (
  `guid` int(11) NOT NULL COMMENT '玩家guid',
  `bonus_activity_id` int(11) NOT NULL COMMENT '红包活动id',
  `money` bigint(20) NOT NULL DEFAULT '0' COMMENT '输赢金钱情况',
  `times` int(11) NOT NULL DEFAULT '0' COMMENT '玩游戏局数',
  `first_game_type` int(11) NOT NULL COMMENT '游戏first_game_type',
  `platform_id` int(11) DEFAULT '0',
  PRIMARY KEY (`guid`,`bonus_activity_id`,`first_game_type`) USING BTREE,
  KEY `guid_index` (`guid`) USING BTREE,
  KEY `bonus_activity_index` (`bonus_activity_id`) USING BTREE,
  KEY `game_name_index` (`first_game_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家红包法动期间玩游戏情况统计';

-- ----------------------------
-- Table structure for t_bonus_pool
-- ----------------------------
DROP TABLE IF EXISTS `t_bonus_pool`;
CREATE TABLE `t_bonus_pool` (
  `bonus_pool_name` varchar(255) NOT NULL COMMENT '奖池的名字',
  `money` bigint(20) DEFAULT '0' COMMENT '奖池的钱',
  PRIMARY KEY (`bonus_pool_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_channel_invite_tax
-- ----------------------------
DROP TABLE IF EXISTS `t_channel_invite_tax`;
CREATE TABLE `t_channel_invite_tax` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `guid` int(11) NOT NULL COMMENT 'guid',
  `val` int(11) NOT NULL DEFAULT '0' COMMENT '获得的收益',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_club
-- ----------------------------
DROP TABLE IF EXISTS `t_club`;
CREATE TABLE `t_club` (
  `id` int(4) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `owner` int(4) NOT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `type` smallint(1) DEFAULT '0' COMMENT '0是群 1联盟',
  `parent` int(4) DEFAULT NULL,
  `status` smallint(1) NOT NULL DEFAULT '0' COMMENT '营业状态 0正常 1打烊',
  `created_at` int(11) DEFAULT '0',
  `updated_at` int(11) DEFAULT '0',
  PRIMARY KEY (`id`,`owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲友群或联盟表';

-- ----------------------------
-- Table structure for t_club_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_club_commission`;
CREATE TABLE `t_club_commission` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `club` int(4) NOT NULL,
  `commission` bigint(8) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`,`club`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_club_member
-- ----------------------------
DROP TABLE IF EXISTS `t_club_member`;
CREATE TABLE `t_club_member` (
  `club` int(8) NOT NULL COMMENT 'club id',
  `guid` int(8) NOT NULL COMMENT '玩家id',
  `status` smallint(2) NOT NULL DEFAULT '0' COMMENT '成员状态 0：正常 1：已移除',
  PRIMARY KEY (`club`,`guid`) USING BTREE,
  KEY `idx_club_id` (`club`,`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲友群或联盟成员';

-- ----------------------------
-- Table structure for t_club_money
-- ----------------------------
DROP TABLE IF EXISTS `t_club_money`;
CREATE TABLE `t_club_money` (
  `club` int(11) NOT NULL,
  `money_id` smallint(2) NOT NULL,
  `money` int(4) NOT NULL,
  PRIMARY KEY (`club`,`money_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲友群或联盟金钱';

-- ----------------------------
-- Table structure for t_club_money_type
-- ----------------------------
DROP TABLE IF EXISTS `t_club_money_type`;
CREATE TABLE `t_club_money_type` (
  `money_id` int(4) NOT NULL,
  `club` int(4) NOT NULL,
  PRIMARY KEY (`money_id`,`club`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_daily_earnings_rank
-- ----------------------------
DROP TABLE IF EXISTS `t_daily_earnings_rank`;
CREATE TABLE `t_daily_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='日盈利榜表';

-- ----------------------------
-- Table structure for t_earnings
-- ----------------------------
DROP TABLE IF EXISTS `t_earnings`;
CREATE TABLE `t_earnings` (
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `daily_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '日盈利',
  `weekly_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '周盈利',
  `monthly_earnings` bigint(20) NOT NULL DEFAULT '0' COMMENT '月盈利',
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='盈利榜表';

-- ----------------------------
-- Table structure for t_fortune_rank
-- ----------------------------
DROP TABLE IF EXISTS `t_fortune_rank`;
CREATE TABLE `t_fortune_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='总财富榜表';

-- ----------------------------
-- Table structure for t_mail
-- ----------------------------
DROP TABLE IF EXISTS `t_mail`;
CREATE TABLE `t_mail` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '邮件ID',
  `expiration_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '过期时间',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `send_guid` int(11) NOT NULL DEFAULT '0' COMMENT '发件人的全局唯一标识符',
  `send_name` varchar(32) NOT NULL DEFAULT '' COMMENT '发件人的名字',
  `title` varchar(32) NOT NULL COMMENT '标题',
  `content` varchar(128) NOT NULL DEFAULT '' COMMENT '内容',
  `pb_attachment` blob COMMENT '附件',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_expiration_time_guid` (`expiration_time`,`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='邮件表';

-- ----------------------------
-- Table structure for t_many_ox_server_config
-- ----------------------------
DROP TABLE IF EXISTS `t_many_ox_server_config`;
CREATE TABLE `t_many_ox_server_config` (
  `id` int(11) NOT NULL,
  `FreeTime` int(11) NOT NULL COMMENT '空闲时间',
  `BetTime` int(11) NOT NULL COMMENT '下注时间',
  `EndTime` int(11) NOT NULL COMMENT '结束时间',
  `MustWinCoeff` int(11) NOT NULL COMMENT '系统必赢系数',
  `BankerMoneyLimit` int(11) NOT NULL COMMENT '上庄条件限制',
  `SystemBankerSwitch` int(11) NOT NULL COMMENT '系统当庄开关',
  `BankerCount` int(11) NOT NULL COMMENT '连庄次数',
  `RobotBankerInitUid` int(11) NOT NULL COMMENT '系统庄家初始UID',
  `RobotBankerInitMoney` bigint(20) NOT NULL COMMENT '系统庄家初始金币',
  `BetRobotSwitch` int(11) NOT NULL COMMENT '下注机器人开关',
  `BetRobotInitUid` int(11) NOT NULL COMMENT '下注机器人初始UID',
  `BetRobotInitMoney` bigint(20) NOT NULL COMMENT '下注机器人初始金币',
  `BetRobotNumControl` int(11) NOT NULL COMMENT '下注机器人个数限制',
  `BetRobotTimesControl` int(11) NOT NULL COMMENT '机器人下注次数限制',
  `RobotBetMoneyControl` int(11) NOT NULL COMMENT '机器人下注金币限制',
  `BasicChip` varchar(64) NOT NULL COMMENT '筹码信息',
  `ExtendA` int(11) NOT NULL COMMENT '预留字段A',
  `ExtendB` int(11) NOT NULL COMMENT '预留字段B',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='百人牛牛基础配置表';

-- ----------------------------
-- Table structure for t_monthly_earnings_rank
-- ----------------------------
DROP TABLE IF EXISTS `t_monthly_earnings_rank`;
CREATE TABLE `t_monthly_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='月盈利榜表';

-- ----------------------------
-- Table structure for t_notice
-- ----------------------------
DROP TABLE IF EXISTS `t_notice`;
CREATE TABLE `t_notice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number` int(11) DEFAULT '0' COMMENT '轮播次数',
  `interval_time` int(11) DEFAULT '0' COMMENT '轮播时间间隔（秒）',
  `type` varchar(32) CHARACTER SET utf8 DEFAULT NULL COMMENT '通知类型 1：消息通知 2：公告通知 3跑马灯',
  `send_range` tinyint(1) DEFAULT '0' COMMENT '发送范围 0：全部',
  `name` varchar(1024) CHARACTER SET utf8 DEFAULT NULL COMMENT '标题',
  `content` text CHARACTER SET utf8 COMMENT '内容',
  `author` varchar(20) CHARACTER SET utf8 DEFAULT NULL COMMENT '发布者',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '发送时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `platform_ids` varchar(256) CHARACTER SET utf8 DEFAULT ',0,' COMMENT '消息对应平台id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_name` (`name`(255)) USING BTREE,
  KEY `index_time_type` (`end_time`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通知表';

-- ----------------------------
-- Table structure for t_notice_platform
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_platform`;
CREATE TABLE `t_notice_platform` (
  `notice_id` int(11) NOT NULL COMMENT '通知id',
  `platform_id` varchar(256) NOT NULL COMMENT '消息对应的平台id',
  KEY `index_notice_id` (`notice_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_notice_private
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_private`;
CREATE TABLE `t_notice_private` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` int(11) DEFAULT NULL COMMENT '用户ID,与account.t_account',
  `account` varchar(64) DEFAULT NULL COMMENT '用户账号',
  `nickname` varchar(32) DEFAULT NULL COMMENT '用户昵称',
  `type` varchar(20) DEFAULT NULL COMMENT '通知类型 1：消息通知',
  `name` varchar(64) DEFAULT NULL COMMENT '标题',
  `content` text COMMENT '内容',
  `author` varchar(20) DEFAULT NULL COMMENT '发布者',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '开始时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `is_read` tinyint(1) DEFAULT '0' COMMENT '是否阅读 1:已读 0:未读',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_name` (`name`) USING BTREE,
  KEY `index_guid` (`guid`) USING BTREE,
  KEY `index_guid_time_type` (`guid`,`end_time`,`type`) USING BTREE,
  KEY `index_guid_id` (`guid`,`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='私信通知表';

-- ----------------------------
-- Table structure for t_notice_read
-- ----------------------------
DROP TABLE IF EXISTS `t_notice_read`;
CREATE TABLE `t_notice_read` (
  `guid` int(11) NOT NULL COMMENT '用户ID,与account.t_account',
  `n_id` int(11) NOT NULL COMMENT '通知ID',
  `is_read` tinyint(1) DEFAULT '1' COMMENT '是否阅读 1：已读， 0：未读',
  `read_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '阅读时间',
  PRIMARY KEY (`guid`,`n_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='通知阅读明细表';

-- ----------------------------
-- Table structure for t_ox_player_info
-- ----------------------------
DROP TABLE IF EXISTS `t_ox_player_info`;
CREATE TABLE `t_ox_player_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '全局唯一标识符',
  `guid` int(11) NOT NULL COMMENT '用户ID',
  `is_android` int(11) NOT NULL COMMENT '是否机器人',
  `table_id` int(11) NOT NULL COMMENT '桌子ID',
  `banker_id` int(11) NOT NULL COMMENT '庄家ID',
  `nickname` varchar(64) NOT NULL COMMENT '昵称',
  `money` bigint(20) NOT NULL COMMENT '金币数',
  `win_money` bigint(20) NOT NULL COMMENT '该局输赢',
  `bet_money` int(11) NOT NULL COMMENT '玩家下注金币',
  `tax` int(11) NOT NULL COMMENT '玩家台费',
  `curtime` int(11) NOT NULL COMMENT '当前时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='百人牛牛收益表';

-- ----------------------------
-- Table structure for t_player
-- ----------------------------
DROP TABLE IF EXISTS `t_player`;
CREATE TABLE `t_player` (
  `guid` int(8) NOT NULL COMMENT '全局唯一标识符',
  `is_android` int(1) NOT NULL DEFAULT '0' COMMENT '是机器人',
  `account` varchar(64) NOT NULL DEFAULT '' COMMENT '账号',
  `nickname` varchar(128) DEFAULT NULL COMMENT '昵称',
  `level` int(1) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `bank` bigint(8) NOT NULL DEFAULT '0' COMMENT '银行存款',
  `head_url` varchar(256) NOT NULL DEFAULT '0' COMMENT '头像',
  `phone` char(11) DEFAULT NULL COMMENT '手机号',
  `platform_id` varchar(256) DEFAULT '0' COMMENT '平台id',
  `is_collapse` tinyint(1) DEFAULT '0' COMMENT '是否破产，1破产，0不破产',
  `status` tinyint(1) DEFAULT '1' COMMENT '是否可用 1可用 0封号',
  `created_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='玩家表';

-- ----------------------------
-- Table structure for t_player_award
-- ----------------------------
DROP TABLE IF EXISTS `t_player_award`;
CREATE TABLE `t_player_award` (
  `guid` int(4) NOT NULL,
  `login_award_day` int(8) DEFAULT NULL,
  `login_award_receive_day` int(8) DEFAULT NULL,
  `online_award_time` int(8) DEFAULT NULL,
  `online_award_num` int(8) DEFAULT NULL,
  `relief_payment_count` int(8) DEFAULT NULL,
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='玩家奖励';

-- ----------------------------
-- Table structure for t_player_binding
-- ----------------------------
DROP TABLE IF EXISTS `t_player_binding`;
CREATE TABLE `t_player_binding` (
  `guid` int(4) NOT NULL,
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='玩家绑定银行卡或支付宝等';

-- ----------------------------
-- Table structure for t_player_bonus
-- ----------------------------
DROP TABLE IF EXISTS `t_player_bonus`;
CREATE TABLE `t_player_bonus` (
  `guid` int(11) NOT NULL COMMENT '玩家guid',
  `bonus_activity_id` int(11) NOT NULL COMMENT '红包活动id',
  `bonus_index` int(11) NOT NULL DEFAULT '1' COMMENT '红包索引(本次红包活动中第几个红包）',
  `money` int(11) NOT NULL COMMENT '红包中的钱',
  `get_in_game_id` int(11) DEFAULT NULL COMMENT '在哪个frist_game_type中获得的红包',
  `get_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '获得红包时间',
  `valid_time_until` datetime DEFAULT NULL COMMENT '红包有效期至',
  `is_pick` int(11) NOT NULL DEFAULT '0' COMMENT '是否领取',
  KEY `index_guid` (`guid`) USING BTREE,
  KEY `index_bonus_activity` (`bonus_activity_id`) USING BTREE,
  KEY `index_get_time` (`get_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家获得红包记录表';

-- ----------------------------
-- Table structure for t_player_bonus_activity_limit
-- ----------------------------
DROP TABLE IF EXISTS `t_player_bonus_activity_limit`;
CREATE TABLE `t_player_bonus_activity_limit` (
  `guid` int(11) NOT NULL,
  `activity_id` int(11) NOT NULL,
  `bonus_index` int(11) NOT NULL,
  `play_count_min` int(11) NOT NULL DEFAULT '0',
  `play_count_max` int(11) NOT NULL,
  `money` bigint(20) NOT NULL,
  PRIMARY KEY (`guid`,`activity_id`) USING BTREE,
  KEY `guid_index` (`guid`) USING BTREE,
  KEY `activity_index` (`activity_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_player_game_conf
-- ----------------------------
DROP TABLE IF EXISTS `t_player_game_conf`;
CREATE TABLE `t_player_game_conf` (
  `guid` int(11) NOT NULL,
  `slotma_addition` int(8) DEFAULT NULL,
  PRIMARY KEY (`guid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_player_money
-- ----------------------------
DROP TABLE IF EXISTS `t_player_money`;
CREATE TABLE `t_player_money` (
  `guid` int(8) NOT NULL COMMENT '玩家id',
  `money_id` int(4) NOT NULL DEFAULT '0' COMMENT '金钱类型 0金币 1房卡 2钻石',
  `money` int(4) NOT NULL DEFAULT '0' COMMENT '数量',
  `where` smallint(2) NOT NULL DEFAULT '0' COMMENT '存在哪儿 0玩家身上 1保险箱',
  PRIMARY KEY (`guid`,`money_id`,`where`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='玩家金钱';

-- ----------------------------
-- Table structure for t_pool_activity
-- ----------------------------
DROP TABLE IF EXISTS `t_pool_activity`;
CREATE TABLE `t_pool_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `game_id` int(11) DEFAULT NULL COMMENT '游戏ID config.t_game_server_cfg表 game_id',
  `game_name` varchar(100) DEFAULT NULL COMMENT '游戏名称config.t_game_server_cfg表 game_name',
  `opt_type` int(11) DEFAULT NULL COMMENT '对应log.t_log_game_tj表opt_type',
  `name` varchar(100) DEFAULT NULL COMMENT '奖池名称',
  `is_show` tinyint(2) DEFAULT '1' COMMENT '是否显示在游戏大厅：1显示 0不显示',
  `is_open` tinyint(2) DEFAULT '1' COMMENT '奖池是否开启',
  `time_start` timestamp NULL DEFAULT NULL COMMENT '开始时间',
  `time_end` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `pool_money` bigint(20) DEFAULT '0' COMMENT '奖池余额',
  `pool_lucky` int(11) DEFAULT '0' COMMENT '中奖率',
  `bet_add` int(11) DEFAULT NULL COMMENT '下注加权中奖',
  `cfg` text,
  `created_at` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT NULL COMMENT '奖池配置',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_time_start_end` (`time_start`,`time_end`) USING BTREE,
  KEY `index_time_crated_updated` (`created_at`,`updated_at`) USING BTREE,
  KEY `index_game_id` (`game_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_rank_update_time
-- ----------------------------
DROP TABLE IF EXISTS `t_rank_update_time`;
CREATE TABLE `t_rank_update_time` (
  `rank_type` int(11) NOT NULL COMMENT '排行榜类型',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '上次更新时间',
  PRIMARY KEY (`rank_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='排行榜更新时间表';

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
  `status` int(1) NOT NULL DEFAULT '0',
  `created_time` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Table structure for t_weekly_earnings_rank
-- ----------------------------
DROP TABLE IF EXISTS `t_weekly_earnings_rank`;
CREATE TABLE `t_weekly_earnings_rank` (
  `rank` int(11) NOT NULL AUTO_INCREMENT COMMENT '排行榜',
  `guid` int(11) NOT NULL COMMENT '全局唯一标识符',
  `nickname` varchar(32) DEFAULT NULL COMMENT '昵称',
  `money` int(11) NOT NULL DEFAULT '0' COMMENT '钱',
  PRIMARY KEY (`rank`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='周盈利榜表';

SET FOREIGN_KEY_CHECKS = 1;
