/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : proxy

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:33:12
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS proxy;
CREATE DATABASE proxy;
USE proxy;

-- ----------------------------
-- Table structure for player_bet_coin_flow
-- ----------------------------
DROP TABLE IF EXISTS `player_bet_coin_flow`;
CREATE TABLE `player_bet_coin_flow` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`player_id`  int(11) NULL DEFAULT NULL COMMENT '用户ID' ,
`date`  datetime NULL DEFAULT NULL COMMENT '日期' ,
`parent_id`  int(255) NULL DEFAULT NULL COMMENT '用户账号' ,
`parent_account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '上级账号' ,
`self_flow`  int(11) NOT NULL DEFAULT 0 COMMENT '自己有效下注' ,
`team_flow`  int(11) NOT NULL DEFAULT 0 COMMENT '团队有效下注' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='代理用户有效下注流水表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of player_bet_coin_flow
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for player_dayinfo
-- ----------------------------
DROP TABLE IF EXISTS `player_dayinfo`;
CREATE TABLE `player_dayinfo` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`date`  datetime NULL DEFAULT NULL COMMENT '时间' ,
`account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '用户账号' ,
`dayregedit`  int(11) NULL DEFAULT NULL COMMENT '注册量' ,
`dayactive`  int(11) NULL DEFAULT NULL COMMENT '活跃量' ,
`player_id`  int(11) NULL DEFAULT NULL COMMENT '玩家ID' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='代理用户每天的注册量活跃量'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of player_dayinfo
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for player_extract_cash
-- ----------------------------
DROP TABLE IF EXISTS `player_extract_cash`;
CREATE TABLE `player_extract_cash` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`player_id`  int(11) NULL DEFAULT NULL COMMENT '用户ID' ,
`account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '用户账号' ,
`order`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '订单号' ,
`amount`  decimal(11,2) NULL DEFAULT NULL COMMENT '提现金额' ,
`type`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '提现类型（支付宝、银行卡）' ,
`real_name`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '真实姓名' ,
`card`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '卡号' ,
`date`  datetime NULL DEFAULT NULL COMMENT '时间' ,
`status`  int(11) NULL DEFAULT NULL COMMENT '状态 0：申请中 1：提现成功 2：提现失败' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='代理用户提现表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of player_extract_cash
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_balance_statices
-- ----------------------------
DROP TABLE IF EXISTS `proxy_balance_statices`;
CREATE TABLE `proxy_balance_statices` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`player_id`  int(11) NULL DEFAULT NULL COMMENT '用户ID' ,
`account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '用户账号' ,
`coin`  decimal(11,2) NULL DEFAULT NULL COMMENT '可领取金额' ,
`total_coin`  decimal(11,0) NULL DEFAULT NULL COMMENT '总金额' ,
`extract_coin`  decimal(11,0) NULL DEFAULT NULL COMMENT '已领取金额' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='代理用户结算表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of proxy_balance_statices
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_commission_rate
-- ----------------------------
DROP TABLE IF EXISTS `proxy_commission_rate`;
CREATE TABLE `proxy_commission_rate` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`player_id`  int(11) NULL DEFAULT NULL COMMENT '用户ID' ,
`commission_rate`  int(11) NULL DEFAULT NULL COMMENT '用户佣金比例' ,
`account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '用户账号' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='用户佣金比例表'
AUTO_INCREMENT=3

;

-- ----------------------------
-- Records of proxy_commission_rate
-- ----------------------------
BEGIN;
INSERT INTO `proxy_commission_rate` VALUES ('2', '1', '20', 'guest_1');
COMMIT;

-- ----------------------------
-- Table structure for proxy_daily_balance
-- ----------------------------
DROP TABLE IF EXISTS `proxy_daily_balance`;
CREATE TABLE `proxy_daily_balance` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`player_id`  int(11) NULL DEFAULT NULL COMMENT '用户ID' ,
`account`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL COMMENT '用户账号' ,
`date`  datetime NULL DEFAULT NULL COMMENT '时间' ,
`commission`  decimal(11,2) NULL DEFAULT NULL COMMENT '总返佣金额' ,
`self_flow`  int(11) NULL DEFAULT NULL COMMENT '自己有效下注' ,
`self_commission`  decimal(11,2) NULL DEFAULT NULL COMMENT '自己返佣金额' ,
`team_flow`  int(11) NULL DEFAULT NULL COMMENT '团队有效下注' ,
`team_commission`  decimal(11,2) NULL DEFAULT NULL COMMENT '团队返佣金额' ,
`comission_rate`  decimal(11,2) NULL DEFAULT NULL COMMENT '返佣比例' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='代理每日流水'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of proxy_daily_balance
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for proxy_user_info
-- ----------------------------
DROP TABLE IF EXISTS `proxy_user_info`;
CREATE TABLE `proxy_user_info` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`player_id`  int(11) NOT NULL COMMENT '玩家guid' ,
`parent_id`  int(11) NULL DEFAULT NULL COMMENT '上级guid' ,
`team_number`  int(11) NULL DEFAULT 0 COMMENT '团队人数' ,
`child_number`  int(11) NULL DEFAULT 0 COMMENT '下级人数' ,
`mobile`  varchar(11) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='代理用户信息表'
AUTO_INCREMENT=2

;

-- ----------------------------
-- Records of proxy_user_info
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Procedure structure for update_bet_flow
-- ----------------------------
DROP PROCEDURE IF EXISTS `update_bet_flow`;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `update_bet_flow`(IN `player_guid` int,IN `money` int)
BEGIN
	DECLARE self_guid INT DEFAULT 0;
	DECLARE pid INT DEFAULT 0;
	DECLARE paccount VARCHAR(120) DEFAULT "";

	SET self_guid = player_guid;

	SELECT pid = inviter_guid FROM account.t_account WHERE guid = player_guid;
	INSERT INTO player_bet_coin_flow(guid,date,parent_id,self_flow,team_flow) 
			VALUES(self_guid,CURDATE(),pid,money,0) 
			ON DUPLICATE KEY UPDATE self_flow = self_flow + money;
	
	SET self_guid = pid;
	SELECT pid = inviter_guid FROM account.t_account WHERE guid = pid;
	WHILE FOUND_ROWS() > 0 DO
		INSERT INTO player_bet_coin_flow(guid,date,parent_id,self_flow,team_flow) 
				VALUES(self_guid,CURDATE(),pid,0,money) 
				ON DUPLICATE KEY UPDATE team_flow = team_flow + money;
		
		SET self_guid = pid;
		SELECT pid = parent FROM player_proxy WHERE guid = pid;
	END WHILE;
END
;;
DELIMITER ;

-- ----------------------------
-- Auto increment value for player_bet_coin_flow
-- ----------------------------
ALTER TABLE `player_bet_coin_flow` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for player_dayinfo
-- ----------------------------
ALTER TABLE `player_dayinfo` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for player_extract_cash
-- ----------------------------
ALTER TABLE `player_extract_cash` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for proxy_balance_statices
-- ----------------------------
ALTER TABLE `proxy_balance_statices` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for proxy_commission_rate
-- ----------------------------
ALTER TABLE `proxy_commission_rate` AUTO_INCREMENT=3;

-- ----------------------------
-- Auto increment value for proxy_daily_balance
-- ----------------------------
ALTER TABLE `proxy_daily_balance` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for proxy_user_info
-- ----------------------------
ALTER TABLE `proxy_user_info` AUTO_INCREMENT=2;
