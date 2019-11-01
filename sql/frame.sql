/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : frame

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:31:55
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS frame;
CREATE DATABASE frame;
USE frame;

-- ----------------------------
-- Table structure for account_statistics
-- ----------------------------
DROP TABLE IF EXISTS `account_statistics`;
CREATE TABLE `account_statistics` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NULL DEFAULT NULL COMMENT '唯一标识，对照account库t_account表' ,
`recharge_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值成功金额' ,
`recharge_fail_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值失败金额' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数' ,
`recharge_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数' ,
`cash_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功金额' ,
`cash_fail_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功笔数' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败笔数' ,
`lose_money`  bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）' ,
`win_money`  bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '扣税' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
UNIQUE INDEX `index_guid` (`guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='用户统计信息表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of account_statistics
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for account_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `account_statistics_detail`;
CREATE TABLE `account_statistics_detail` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NULL DEFAULT NULL COMMENT '唯一标识，对照account库t_account表' ,
`recharge_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值成功金额' ,
`recharge_fail_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值失败金额' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数' ,
`recharge_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数' ,
`cash_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功金额' ,
`cash_fail_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功笔数' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败笔数' ,
`lose_money`  bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）' ,
`win_money`  bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '税收' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='用户统计信息明细表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of account_statistics_detail
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for action_log
-- ----------------------------
DROP TABLE IF EXISTS `action_log`;
CREATE TABLE `action_log` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`table`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '表名字' ,
`table_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '记录的主键' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`old_json`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '修改之前的数据' ,
`new_json`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '修改之后的数据' ,
`username`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '审核人' ,
`account`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '审核人账号' ,
`ip`  char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'IP' ,
`url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '操作的url' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='后台操作日志表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of action_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for cash_ali_account
-- ----------------------------
DROP TABLE IF EXISTS `cash_ali_account`;
CREATE TABLE `cash_ali_account` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`ali_account`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '支付宝账号' ,
`admin_account`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '添加该支付宝的管理员' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '修改时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_ali_account` (`ali_account`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='提现支付宝黑名单'
AUTO_INCREMENT=9

;

-- ----------------------------
-- Records of cash_ali_account
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for channel_statistics
-- ----------------------------
DROP TABLE IF EXISTS `channel_statistics`;
CREATE TABLE `channel_statistics` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`c_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道ID' ,
`recharge_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值成功金额' ,
`recharge_fail_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值失败金额' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数' ,
`recharge_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数' ,
`agent_money`  bigint(20) NULL DEFAULT NULL COMMENT '代理充值' ,
`agent_cash`  bigint(20) NULL DEFAULT NULL COMMENT '代理提现' ,
`cash_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功金额' ,
`cash_fail_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功笔数' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败笔数' ,
`lose_money`  bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）' ,
`win_money`  bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '税收' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
UNIQUE INDEX `index_guid` (`c_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道统计信息表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of channel_statistics
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for channel_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `channel_statistics_detail`;
CREATE TABLE `channel_statistics_detail` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`c_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道ID' ,
`recharge_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值成功金额' ,
`recharge_fail_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值失败金额' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数' ,
`recharge_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数' ,
`agent_money`  bigint(20) NULL DEFAULT NULL COMMENT '代理充值' ,
`agent_cash`  bigint(20) NULL DEFAULT NULL COMMENT '代理提现' ,
`cash_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功金额' ,
`cash_fail_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功笔数' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败笔数' ,
`lose_money`  bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）' ,
`win_money`  bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '税收' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道统计信息明细表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of channel_statistics_detail
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for counts
-- ----------------------------
DROP TABLE IF EXISTS `counts`;
CREATE TABLE `counts` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '字段名称' ,
`number`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '数量' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
UNIQUE INDEX `feedback_name_unique` (`name`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='统计表'
AUTO_INCREMENT=9

;

-- ----------------------------
-- Records of counts
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`reply_id`  int(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT '回复id' ,
`processing_id`  int(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT '处理id' ,
`guid`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '玩家guid' ,
`account`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '玩家账号' ,
`content`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '反馈的内容' ,
`is_readme`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未读 1已读' ,
`processing_status`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '0未处理 1已查看 2处理中 3已解决 4已忽略' ,
`type`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '反馈的类型：99=客服处理类型' ,
`author`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '处理人' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`processing_at`  timestamp NULL DEFAULT NULL COMMENT '处理时间' ,
`nfk_ip`  varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '新反馈:玩家ip' ,
`nfk_area`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '新反馈:玩家ip地域' ,
`nfk_plat_id`  int(11) NULL DEFAULT NULL COMMENT '新反馈:玩家隶属平台' ,
`nfk_group`  tinyint(1) NULL DEFAULT 0 COMMENT '新反馈:0无,1全部用户客服组,2普通用户客服组,3RVIP用户客服组' ,
`nfk_sys_u`  int(11) NULL DEFAULT NULL COMMENT '新反馈:系统分配用户(自动分配把单子给此客服)' ,
`nfk_sys_t`  timestamp NULL DEFAULT NULL COMMENT '新反馈:系统分配时间' ,
`nfk_mv_u`  int(11) NULL DEFAULT NULL COMMENT '新反馈:手动分配用户(该客服将单子转给了他人)' ,
`nfk_mv_t`  timestamp NULL DEFAULT NULL COMMENT '新反馈:手动分配时间' ,
`nfk_cur_u`  int(11) NULL DEFAULT NULL COMMENT '新反馈:当前分配用户(该单子目前由哪个客服处理)' ,
`nfk_cur_t`  timestamp NULL DEFAULT NULL COMMENT '新反馈:当前分配时间' ,
`nfk_delete`  timestamp NULL DEFAULT NULL COMMENT '新反馈:软删除时间，为null的没删除' ,
PRIMARY KEY (`id`),
INDEX `index_guid` (`guid`) USING BTREE ,
INDEX `IDX_crated_at` (`created_at`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='反馈表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_ban_say
-- ----------------------------
DROP TABLE IF EXISTS `feedback_ban_say`;
CREATE TABLE `feedback_ban_say` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID' ,
`status`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:未处理,1:禁言,2:解禁' ,
`author`  char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '发起请求的操作员' ,
`c_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '申请时间' ,
`msg`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '申请理由' ,
`handle`  char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核的操作员' ,
`u_time`  timestamp NULL DEFAULT NULL COMMENT '审核时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_guid` (`guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback_ban_say
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_ban_say_log
-- ----------------------------
DROP TABLE IF EXISTS `feedback_ban_say_log`;
CREATE TABLE `feedback_ban_say_log` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID' ,
`status`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:未处理,1:禁言,2:解禁' ,
`author`  char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '发起请求的操作员' ,
`c_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '申请时间' ,
`msg`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '申请理由' ,
`handle`  char(15) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核的操作员' ,
`u_time`  timestamp NULL DEFAULT NULL COMMENT '审核时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback_ban_say_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_card_record
-- ----------------------------
DROP TABLE IF EXISTS `feedback_card_record`;
CREATE TABLE `feedback_card_record` (
`id`  int(10) NOT NULL AUTO_INCREMENT ,
`service_id`  int(10) NOT NULL DEFAULT 0 COMMENT '客服id' ,
`start_time`  int(10) NOT NULL DEFAULT 0 COMMENT '打卡时间' ,
`end_time`  int(10) NULL DEFAULT 0 COMMENT '结束时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='客服打卡记录表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback_card_record
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_handle_order_record
-- ----------------------------
DROP TABLE IF EXISTS `feedback_handle_order_record`;
CREATE TABLE `feedback_handle_order_record` (
`id`  int(10) NOT NULL AUTO_INCREMENT ,
`day`  int(10) NOT NULL DEFAULT 0 COMMENT '天:20180325' ,
`month`  int(10) NOT NULL DEFAULT 0 COMMENT '月份:201803' ,
`service_id`  int(10) NOT NULL DEFAULT 0 COMMENT '客服id' ,
`user_id`  int(10) NOT NULL DEFAULT 0 COMMENT '消息id' ,
`add_time`  int(10) NOT NULL DEFAULT 0 COMMENT '添加时间戳' ,
`status`  int(1) NULL DEFAULT 1 COMMENT '状态,1_生效,0_失效' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='客服处理单子记录表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback_handle_order_record
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_order_queue
-- ----------------------------
DROP TABLE IF EXISTS `feedback_order_queue`;
CREATE TABLE `feedback_order_queue` (
`service_id`  int(11) NOT NULL COMMENT '客服id' ,
`user_id`  int(11) NULL DEFAULT NULL COMMENT '用户id' ,
`add_time`  int(10) NULL DEFAULT 0 COMMENT '添加时间' 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='客服接单队列表'

;

-- ----------------------------
-- Records of feedback_order_queue
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_out_time_order_record
-- ----------------------------
DROP TABLE IF EXISTS `feedback_out_time_order_record`;
CREATE TABLE `feedback_out_time_order_record` (
`id`  int(10) NOT NULL AUTO_INCREMENT ,
`day`  int(10) NOT NULL DEFAULT 0 COMMENT '天:20180325' ,
`month`  int(10) NOT NULL DEFAULT 0 COMMENT '月份:201803' ,
`service_id`  int(10) NOT NULL DEFAULT 0 COMMENT '客服id' ,
`user_id`  int(10) NOT NULL DEFAULT 0 COMMENT '用户id' ,
`add_time`  int(10) NOT NULL DEFAULT 0 COMMENT '添加时间戳' ,
`status`  int(1) NULL DEFAULT 1 COMMENT '状态,1_生效,0_失效' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='客服处理单子超时记录表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of feedback_out_time_order_record
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_time_last
-- ----------------------------
DROP TABLE IF EXISTS `feedback_time_last`;
CREATE TABLE `feedback_time_last` (
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`time`  timestamp NOT NULL DEFAULT '2018-01-01 00:00:00' COMMENT '最后反馈时间（用来防止刷反馈）' ,
PRIMARY KEY (`guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of feedback_time_last
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for feedback_user_tag
-- ----------------------------
DROP TABLE IF EXISTS `feedback_user_tag`;
CREATE TABLE `feedback_user_tag` (
`guid`  int(11) NULL DEFAULT NULL COMMENT '用户id,与游服玩家id一致' ,
`tag`  varchar(8192) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家标记(新反馈使用)，多个标记\",\"分割' ,
`created_at`  timestamp NULL DEFAULT NULL COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
UNIQUE INDEX `index_guid` (`guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of feedback_user_tag
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for menus
-- ----------------------------
DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`pid`  int(11) NOT NULL DEFAULT 0 COMMENT '菜单关系' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单名称' ,
`icon`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '图标' ,
`slug`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单对应的权限' ,
`url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单链接地址' ,
`active`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '菜单高亮地址' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`sort`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '排序' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=124

;

-- ----------------------------
-- Records of menus
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for migrations
-- ----------------------------
DROP TABLE IF EXISTS `migrations`;
CREATE TABLE `migrations` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`migration`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`batch`  int(11) NOT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=9

;

-- ----------------------------
-- Records of migrations
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for notice_type
-- ----------------------------
DROP TABLE IF EXISTS `notice_type`;
CREATE TABLE `notice_type` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`name`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '类型名称' ,
`developer`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '开发者' ,
`is_online`  tinyint(4) NULL DEFAULT 0 COMMENT '是否上线：0下线 1上线' ,
`desc`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='通知类型表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of notice_type
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for operator_count_statistics
-- ----------------------------
DROP TABLE IF EXISTS `operator_count_statistics`;
CREATE TABLE `operator_count_statistics` (
`day`  date NOT NULL COMMENT '日期（平台及渠道包下用户每天注册数及每天最高在线数）' ,
`channel_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道号（渠道号为--all--的是全部渠道号即平台）' ,
`create_sum`  int(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该日create的guid数' ,
`online_max`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '该日最高同时在线guid数（每天获取多次只保留最大的那个在线数）' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`day`, `channel_id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of operator_count_statistics
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for password_resets
-- ----------------------------
DROP TABLE IF EXISTS `password_resets`;
CREATE TABLE `password_resets` (
`email`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`token`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
INDEX `password_resets_email_index` (`email`) USING BTREE ,
INDEX `password_resets_token_index` (`token`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of password_resets
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for permission_role
-- ----------------------------
DROP TABLE IF EXISTS `permission_role`;
CREATE TABLE `permission_role` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`permission_id`  int(10) UNSIGNED NOT NULL ,
`role_id`  int(10) UNSIGNED NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
INDEX `permission_role_permission_id_index` (`permission_id`) USING BTREE ,
INDEX `permission_role_role_id_index` (`role_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=288

;

-- ----------------------------
-- Records of permission_role
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for permission_user
-- ----------------------------
DROP TABLE IF EXISTS `permission_user`;
CREATE TABLE `permission_user` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`permission_id`  int(10) UNSIGNED NOT NULL ,
`user_id`  int(10) UNSIGNED NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
INDEX `permission_user_permission_id_index` (`permission_id`) USING BTREE ,
INDEX `permission_user_user_id_index` (`user_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of permission_user
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for permissions
-- ----------------------------
DROP TABLE IF EXISTS `permissions`;
CREATE TABLE `permissions` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`slug`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`model`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `permissions_slug_unique` (`slug`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=155

;

-- ----------------------------
-- Records of permissions
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for phone_statistics
-- ----------------------------
DROP TABLE IF EXISTS `phone_statistics`;
CREATE TABLE `phone_statistics` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`type`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '机型标识 0-IOS 1-Android' ,
`recharge_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值成功金额' ,
`recharge_fail_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值失败金额' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数' ,
`recharge_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数' ,
`agent_money`  bigint(20) NULL DEFAULT NULL COMMENT '代理充值' ,
`agent_cash`  bigint(20) NULL DEFAULT NULL COMMENT '代理提现' ,
`cash_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功金额' ,
`cash_fail_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功笔数' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败笔数' ,
`lose_money`  bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）' ,
`win_money`  bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '税收' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
UNIQUE INDEX `index_guid` (`type`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='手机机型统计信息表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of phone_statistics
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for phone_statistics_detail
-- ----------------------------
DROP TABLE IF EXISTS `phone_statistics_detail`;
CREATE TABLE `phone_statistics_detail` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`type`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '机型标识 0-IOS 1-Android' ,
`recharge_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值成功金额' ,
`recharge_fail_money`  double(11,2) NULL DEFAULT 0.00 COMMENT '充值失败金额' ,
`recharge_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功笔数' ,
`recharge_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '充值失败笔数' ,
`agent_money`  bigint(20) NULL DEFAULT NULL COMMENT '代理充值' ,
`agent_cash`  bigint(20) NULL DEFAULT NULL COMMENT '代理提现' ,
`cash_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功金额' ,
`cash_fail_money`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败金额' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现成功笔数' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现失败笔数' ,
`lose_money`  bigint(20) NULL DEFAULT 0 COMMENT '输金币数（到目前为止输的）' ,
`win_money`  bigint(20) NULL DEFAULT 0 COMMENT '赢金币数（到目前为止赢得）' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '税收' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='手机机型统计信息明细表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of phone_statistics_detail
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for plant_statistics
-- ----------------------------
DROP TABLE IF EXISTS `plant_statistics`;
CREATE TABLE `plant_statistics` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`order_count`  bigint(20) NULL DEFAULT 0 COMMENT '总订单数' ,
`order_sum`  double(11,2) NULL DEFAULT 0.00 COMMENT '总订单金额' ,
`order_success_count`  bigint(20) NULL DEFAULT 0 COMMENT '成功的订单数' ,
`order_success_sum`  double(11,2) NULL DEFAULT 0.00 COMMENT '成功订单总金额' ,
`order_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '失败订单数' ,
`order_fail_sum`  double(11,2) NULL DEFAULT 0.00 COMMENT '失败订单总金额' ,
`order_success_user`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功人数' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现总条数' ,
`cash_sum`  bigint(20) NULL DEFAULT 0 COMMENT '提现总金额' ,
`cash_success_count`  bigint(20) NULL DEFAULT 0 COMMENT '总提现成功条数' ,
`cash_success_sum`  bigint(20) NULL DEFAULT 0 COMMENT '总提现成功金额' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '总提现失败条数' ,
`cash_fail_sum`  bigint(20) NULL DEFAULT 0 COMMENT '总提现失败金额' ,
`cash_success_user`  bigint(20) NULL DEFAULT 0 COMMENT '总提现成功人数' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '平台税收' ,
`bank`  bigint(20) NULL DEFAULT 0 COMMENT '银行存款统计' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='平台信息综合统计表'
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
`order_count`  bigint(20) NULL DEFAULT 0 COMMENT '总订单数' ,
`order_sum`  double(11,2) NULL DEFAULT 0.00 COMMENT '总订单金额' ,
`order_success_count`  bigint(20) NULL DEFAULT 0 COMMENT '成功的订单数' ,
`order_success_sum`  double(11,2) NULL DEFAULT 0.00 COMMENT '成功订单总金额' ,
`order_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '失败订单数' ,
`order_fail_sum`  double(11,2) NULL DEFAULT 0.00 COMMENT '失败订单总金额' ,
`order_success_user`  bigint(20) NULL DEFAULT 0 COMMENT '充值成功人数' ,
`cash_count`  bigint(20) NULL DEFAULT 0 COMMENT '提现总条数' ,
`cash_sum`  bigint(20) NULL DEFAULT 0 COMMENT '提现总金额' ,
`cash_success_count`  bigint(20) NULL DEFAULT 0 COMMENT '总提现成功条数' ,
`cash_success_sum`  bigint(20) NULL DEFAULT 0 COMMENT '总提现成功金额' ,
`cash_fail_count`  bigint(20) NULL DEFAULT 0 COMMENT '总提现失败条数' ,
`cash_fail_sum`  bigint(20) NULL DEFAULT 0 COMMENT '总提现失败金额' ,
`cash_success_user`  bigint(20) NULL DEFAULT 0 COMMENT '总提现成功人数' ,
`tax`  bigint(20) NULL DEFAULT 0 COMMENT '平台税收' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='平台信息综合统计明细表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of plant_statistics_detail
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for quick_reply
-- ----------------------------
DROP TABLE IF EXISTS `quick_reply`;
CREATE TABLE `quick_reply` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '问题类型比如 提bug,提建议' ,
`location`  tinyint(1) NULL DEFAULT NULL COMMENT '显示位置1 按钮 2下拉' ,
`title`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '快捷回复内容' ,
`content`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '快捷回复内容' ,
`status`  tinyint(1) NULL DEFAULT 0 COMMENT '0 - 启用  1 - 禁用' ,
`weight`  int(11) NOT NULL DEFAULT 1 COMMENT '权重 默认1  值越大 权重越高' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '修改时间' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='反馈的快捷回复表'
AUTO_INCREMENT=150

;

-- ----------------------------
-- Records of quick_reply
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for quick_reply_type
-- ----------------------------
DROP TABLE IF EXISTS `quick_reply_type`;
CREATE TABLE `quick_reply_type` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '自增ID。关联quick_reply type字段' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '消息回复类型' ,
`status`  int(1) NOT NULL DEFAULT 1 COMMENT '状态 默认1（开启）0 禁用' ,
PRIMARY KEY (`id`),
INDEX `status` (`status`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of quick_reply_type
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for risk_star
-- ----------------------------
DROP TABLE IF EXISTS `risk_star`;
CREATE TABLE `risk_star` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NULL DEFAULT NULL ,
`risk_star`  tinyint(2) NULL DEFAULT 0 COMMENT '关注(高危)星级' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '原因' ,
`handler`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`status`  tinyint(2) NULL DEFAULT 1 COMMENT '状态：1=加入关注 0=解除关注' ,
`time`  timestamp NULL DEFAULT NULL COMMENT '时间' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of risk_star
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for role_user
-- ----------------------------
DROP TABLE IF EXISTS `role_user`;
CREATE TABLE `role_user` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`role_id`  int(10) UNSIGNED NOT NULL ,
`user_id`  int(10) UNSIGNED NOT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
INDEX `role_user_role_id_index` (`role_id`) USING BTREE ,
INDEX `role_user_user_id_index` (`user_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=45

;

-- ----------------------------
-- Records of role_user
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`slug`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`level`  int(11) NOT NULL DEFAULT 1 ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `roles_slug_unique` (`slug`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=9

;

-- ----------------------------
-- Records of roles
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for sms
-- ----------------------------
DROP TABLE IF EXISTS `sms`;
CREATE TABLE `sms` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID' ,
`phone`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '手机号' ,
`code`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '验证码' ,
`status`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0默认 1成功 2失败' ,
`return`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '短信第三方返回值' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='短信验证码记录表'
AUTO_INCREMENT=23269

;

-- ----------------------------
-- Records of sms
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`email`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`password`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`remember_token`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`kefu_level`  int(11) NOT NULL DEFAULT 0 COMMENT '0:不是客服，1:普通客服，2:客服组长，3:客服负责人' ,
`kefu_nickname`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '客服昵称' ,
`kefu_upper`  int(11) NOT NULL DEFAULT 0 COMMENT '0:没有上级，其他：上级的客服ID' ,
`kefu_group`  tinyint(1) NULL DEFAULT 0 COMMENT '0无,1全部用户客服组,2普通用户客服组,3RVIP用户客服组' ,
`kefu_platids`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '平台ID，多个以逗号隔开' ,
`kefu_is_deled`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '该客服是否已被删除' ,
`kefu_working`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '该客服(普通客服)是否在上班' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `users_email_unique` (`email`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=37

;

-- ----------------------------
-- Records of users
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Auto increment value for account_statistics
-- ----------------------------
ALTER TABLE `account_statistics` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for account_statistics_detail
-- ----------------------------
ALTER TABLE `account_statistics_detail` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for action_log
-- ----------------------------
ALTER TABLE `action_log` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for cash_ali_account
-- ----------------------------
ALTER TABLE `cash_ali_account` AUTO_INCREMENT=9;

-- ----------------------------
-- Auto increment value for channel_statistics
-- ----------------------------
ALTER TABLE `channel_statistics` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for channel_statistics_detail
-- ----------------------------
ALTER TABLE `channel_statistics_detail` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for counts
-- ----------------------------
ALTER TABLE `counts` AUTO_INCREMENT=9;

-- ----------------------------
-- Auto increment value for feedback
-- ----------------------------
ALTER TABLE `feedback` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for feedback_ban_say
-- ----------------------------
ALTER TABLE `feedback_ban_say` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for feedback_ban_say_log
-- ----------------------------
ALTER TABLE `feedback_ban_say_log` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for feedback_card_record
-- ----------------------------
ALTER TABLE `feedback_card_record` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for feedback_handle_order_record
-- ----------------------------
ALTER TABLE `feedback_handle_order_record` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for feedback_out_time_order_record
-- ----------------------------
ALTER TABLE `feedback_out_time_order_record` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for menus
-- ----------------------------
ALTER TABLE `menus` AUTO_INCREMENT=124;

-- ----------------------------
-- Auto increment value for migrations
-- ----------------------------
ALTER TABLE `migrations` AUTO_INCREMENT=9;

-- ----------------------------
-- Auto increment value for notice_type
-- ----------------------------
ALTER TABLE `notice_type` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permission_role
-- ----------------------------
ALTER TABLE `permission_role` AUTO_INCREMENT=288;

-- ----------------------------
-- Auto increment value for permission_user
-- ----------------------------
ALTER TABLE `permission_user` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permissions
-- ----------------------------
ALTER TABLE `permissions` AUTO_INCREMENT=155;

-- ----------------------------
-- Auto increment value for phone_statistics
-- ----------------------------
ALTER TABLE `phone_statistics` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for phone_statistics_detail
-- ----------------------------
ALTER TABLE `phone_statistics_detail` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for plant_statistics
-- ----------------------------
ALTER TABLE `plant_statistics` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for plant_statistics_detail
-- ----------------------------
ALTER TABLE `plant_statistics_detail` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for quick_reply
-- ----------------------------
ALTER TABLE `quick_reply` AUTO_INCREMENT=150;

-- ----------------------------
-- Auto increment value for quick_reply_type
-- ----------------------------
ALTER TABLE `quick_reply_type` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for risk_star
-- ----------------------------
ALTER TABLE `risk_star` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for role_user
-- ----------------------------
ALTER TABLE `role_user` AUTO_INCREMENT=45;

-- ----------------------------
-- Auto increment value for roles
-- ----------------------------
ALTER TABLE `roles` AUTO_INCREMENT=9;

-- ----------------------------
-- Auto increment value for sms
-- ----------------------------
ALTER TABLE `sms` AUTO_INCREMENT=23269;

-- ----------------------------
-- Auto increment value for users
-- ----------------------------
ALTER TABLE `users` AUTO_INCREMENT=37;
