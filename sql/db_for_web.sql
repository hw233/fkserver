/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : db_for_web

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:30:43
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS db_for_web;
CREATE DATABASE db_for_web;
USE db_for_web;

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
AUTO_INCREMENT=18

;

-- ----------------------------
-- Records of menus
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for message_board
-- ----------------------------
DROP TABLE IF EXISTS `message_board`;
CREATE TABLE `message_board` (
`serial`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增序号' ,
`key`  varchar(5) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '平台类型' ,
`ctime`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间' ,
`guid`  int(11) NULL DEFAULT NULL COMMENT '玩家ID' ,
`account`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '玩家账号' ,
`content`  varchar(8192) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '留言内容(需要检测长度大于10)' ,
`ruser`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '已读用户(一般是客服)' ,
`rtime`  timestamp NULL DEFAULT NULL COMMENT '已读时间' ,
PRIMARY KEY (`serial`),
INDEX `idx_ctime` (`ctime`) USING BTREE ,
INDEX `idx_rtime_ruser` (`rtime`, `ruser`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of message_board
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_application
-- ----------------------------
DROP TABLE IF EXISTS `p_application`;
CREATE TABLE `p_application` (
`serial`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '申请序号' ,
`guid`  int(11) UNSIGNED NOT NULL COMMENT '玩家Id' ,
`plat_id`  int(11) NOT NULL COMMENT '玩家平台' ,
`account`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '玩家账号' ,
`q_way`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '申请:申请方法，0:玩家自己申请发起，1:上级添加下级发起' ,
`q_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '申请:名称必填' ,
`q_qq`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '申请:QQ必填' ,
`q_wx`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '申请:WX必填' ,
`q_phone`  varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '申请:手机必填' ,
`q_plan`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '申请:推广方案' ,
`q_type`  tinyint(1) NOT NULL COMMENT '申请:线上线下(1:线上,2:线下)' ,
`q_upper`  int(11) NOT NULL DEFAULT 0 COMMENT '申请:上级推广员ID(该玩家是谁推广的，谁就是申请时候的上级)' ,
`q_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '申请:请求时间' ,
`d_upper`  int(11) NULL DEFAULT NULL COMMENT '审核:指定的上级推广员ID' ,
`d_upper1`  int(11) NULL DEFAULT NULL COMMENT '审核:指定的顶层1级推广员ID' ,
`d_level`  tinyint(1) NULL DEFAULT 1 COMMENT '审核:给予的等级(上级加一级)' ,
`d_ratio`  decimal(2,2) NULL DEFAULT 0.00 COMMENT '审核:给予的税收分成比例' ,
`d_user`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核:操作人员' ,
`d_mssg`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核:回复信息(最近一次回复或拒绝或回复的私信信息)' ,
`d_time`  timestamp NULL DEFAULT NULL COMMENT '审核:处理时间' ,
`d_flag`  int(11) NOT NULL DEFAULT 0 COMMENT '审核:处理结果(0:待处理,1:已回复,2:已通过,3:已拒绝,4:已删除)' ,
PRIMARY KEY (`serial`),
INDEX `idx_guid_flag` (`guid`, `d_flag`) USING BTREE ,
INDEX `idx_upper_flag` (`d_upper`, `d_flag`) USING BTREE ,
INDEX `idx_q_time` (`q_time`) USING BTREE ,
INDEX `idx_d_time` (`d_time`) USING BTREE ,
INDEX `idx_d_user` (`d_user`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_application
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_backpic
-- ----------------------------
DROP TABLE IF EXISTS `p_backpic`;
CREATE TABLE `p_backpic` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '图片名字' ,
`img`  mediumblob NULL COMMENT '图片二进制' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_name` (`name`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_backpic
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_cash_order
-- ----------------------------
DROP TABLE IF EXISTS `p_cash_order`;
CREATE TABLE `p_cash_order` (
`serial`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单:序号' ,
`see_order`  bigint(16) NULL DEFAULT NULL COMMENT '订单:订单号(由15位精确的10微秒的时间戳+1位游戏区域[王者0,博众1,等]固定标识构成)' ,
`see_time`  timestamp NULL DEFAULT NULL COMMENT '订单:成功时间，没成功就保持null' ,
`see_statu`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '订单:订单状态，0等待审核，11审核通过，12审核驳回(回退库存)，21请求打款，22请求打款失败，23请求打款成功，31执行打款异常(通知成功但是金额不对)，32执行打款失败(回退库存)，33执行打款成功' ,
`cash_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '兑换:时间' ,
`cash_guid`  int(11) NOT NULL COMMENT '兑换:推广员ID' ,
`cash_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '兑换:推广员名称' ,
`cash_money`  decimal(16,2) NOT NULL COMMENT '兑换:金额(元)' ,
`cash_sname`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '兑换:实名' ,
`cash_alipay`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '兑换:支付宝' ,
`join_plat_id`  tinyint(1) NOT NULL COMMENT '关联:平台ID' ,
`join_ip`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '关联:未抓到准确IP(HTTP_X_FORWARDED_FOR)时，填unknow' ,
`join_area`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '关联:未解析到准确地址，填unknow' ,
`risk_succ`  tinyint(1) NULL DEFAULT 0 COMMENT '风控:是否通过' ,
`risk_rule`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '风控:规则名称' ,
`risk_mssg`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '风控:细节信息' ,
`check_statu`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '审核:状态，0正在审核，11审核通过，12审核驳回' ,
`check_user`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核:用户' ,
`check_mssg`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核:备注(自动审核和驳回必填理由)' ,
`check_time`  timestamp NULL DEFAULT NULL COMMENT '审核:时间' ,
`use_channel`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '打款:通道类名作为通道标识' ,
`call_statu`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '同步调用:状态，0正在审核，21请求打款，22请求打款失败，23请求打款成功' ,
`call_req_time`  timestamp NULL DEFAULT NULL COMMENT '同步调用:请求开始时间' ,
`call_err_curl`  tinyint(1) NULL DEFAULT NULL COMMENT '同步调用:是否发生的是curl错误' ,
`call_err_code`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '同步调用:错误码' ,
`call_err_mssg`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '同步调用:错误内容' ,
`call_res_time`  timestamp NULL DEFAULT NULL COMMENT '同步调用:请求完成时间' ,
`call_res_pack`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '同步调用:返回数据(可能多次返回，需要将数据打包保存)' ,
`back_statu`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '异步调用:状态，0正在审核(无有效回调)，31执行打款异常(通知成功但是金额不对)，32执行打款失败(回退库存)，33执行打款成功' ,
`back_err_code`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '异步调用:错误码' ,
`back_err_mssg`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '异步调用:错误内容' ,
`back_res_time`  timestamp NULL DEFAULT NULL COMMENT '异步调用:完成时间' ,
`back_res_pack`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '异步调用:返回数据(可能多次返回，需要将数据打包保存)' ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `unq_see_order` (`see_order`) USING BTREE ,
INDEX `idx_time_deal_statu` (`cash_time`, `check_statu`) USING BTREE ,
INDEX `idx_guid_deal_statu` (`cash_guid`, `check_statu`) USING BTREE ,
INDEX `idx_see_time` (`see_time`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_cash_order
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_data_group
-- ----------------------------
DROP TABLE IF EXISTS `p_data_group`;
CREATE TABLE `p_data_group` (
`group_id`  smallint(1) NOT NULL AUTO_INCREMENT COMMENT '数据组合的ID' ,
`group_name`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '数据组合的名称' ,
`func_id_s`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '数据组合的具体功能ID，多个以‘,’分割' ,
PRIMARY KEY (`group_id`),
UNIQUE INDEX `unq_name` (`group_name`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_data_group
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_domain_floor
-- ----------------------------
DROP TABLE IF EXISTS `p_domain_floor`;
CREATE TABLE `p_domain_floor` (
`guid`  int(11) NOT NULL COMMENT '1级推广员ID' ,
`floor`  tinyint(1) NOT NULL DEFAULT 1 COMMENT '1:其他通用域名,2:2级通用域名,3:3级通用域名,...' ,
`domain`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '域名' ,
`ctime`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`guid`, `floor`, `domain`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of p_domain_floor
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_domain_guid
-- ----------------------------
DROP TABLE IF EXISTS `p_domain_guid`;
CREATE TABLE `p_domain_guid` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '推广员ID' ,
`domain`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '域名' ,
`level`  tinyint(1) NOT NULL COMMENT '推广员等级' ,
`upper1`  int(11) NOT NULL COMMENT '顶层1级推广员ID' ,
`ctime`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `idx_domain` (`domain`) USING BTREE ,
INDEX `unq_guid_domin` (`guid`, `domain`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_domain_guid
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_domain_pool
-- ----------------------------
DROP TABLE IF EXISTS `p_domain_pool`;
CREATE TABLE `p_domain_pool` (
`serial`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '序号' ,
`type`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0:默认,1:后台,2:推广,3:申请' ,
`domain`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '域名' ,
`statu`  tinyint(1) NOT NULL DEFAULT 1 COMMENT '0:异常（检测脚本更新此状态）,1:正常' ,
`handle`  tinyint(1) NOT NULL DEFAULT 1 COMMENT '0:禁用,1:启用,2:删除' ,
`time_new`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`time_upd`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' ,
`time_del`  timestamp NULL DEFAULT NULL COMMENT '删除时间' ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `idx_domain` (`domain`) USING BTREE ,
INDEX `idx_type` (`type`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_domain_pool
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_kvs_data
-- ----------------------------
DROP TABLE IF EXISTS `p_kvs_data`;
CREATE TABLE `p_kvs_data` (
`key`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`value`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '暂存的配置数据等' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`key`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of p_kvs_data
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_profit_cache
-- ----------------------------
DROP TABLE IF EXISTS `p_profit_cache`;
CREATE TABLE `p_profit_cache` (
`guid`  int(11) NOT NULL COMMENT '(该表仅用于计算推广员分成利润的中间层)' ,
`day`  date NOT NULL ,
`money`  decimal(16,2) NOT NULL ,
`plat_id`  tinyint(1) NOT NULL ,
PRIMARY KEY (`guid`, `day`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of p_profit_cache
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_promoters
-- ----------------------------
DROP TABLE IF EXISTS `p_promoters`;
CREATE TABLE `p_promoters` (
`guid`  int(11) UNSIGNED NOT NULL COMMENT '推广员ID' ,
`upper`  int(11) NOT NULL DEFAULT 0 COMMENT '上级推广员ID' ,
`upper1`  int(11) NOT NULL DEFAULT 0 COMMENT '顶层1级推广员ID' ,
`ratio`  decimal(2,2) NOT NULL DEFAULT 0.00 COMMENT '税收分成比例' ,
`type`  tinyint(1) NOT NULL DEFAULT 1 COMMENT '-1未知,0系统,线上1,线下2' ,
`level`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '推广员级别' ,
`enable`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '0禁用,1启用(默认不启用因为创建推广员跨服操作可能失败，创建成功就立刻标记启用)' ,
`plat_id`  tinyint(1) NOT NULL DEFAULT '-1' COMMENT '平台ID' ,
`name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '推广员名称' ,
`qq`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT 'QQ' ,
`wx`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '微信' ,
`phone`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '手机号' ,
`ok_time`  timestamp NULL DEFAULT NULL COMMENT '审核通过:通过时间' ,
`ok_user`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核通过:操作用户' ,
`ok_desc`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '审核通过:备注信息' ,
`lg_user`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '后台登陆账号(务必和users表同步)' ,
`lg_pass`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '后台登陆密码(务必和users表同步)' ,
`kl_line`  int(11) UNSIGNED NOT NULL DEFAULT 100 COMMENT '一级线上推广员的税收扣量起始点(单位元)' ,
`kl_ratio`  decimal(2,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '一级线上推广员的扣量比例(0指不扣量单位元)' ,
`kl_time`  timestamp NULL DEFAULT NULL COMMENT '自动扣量变更时间(如果不是今天,统计脚本就将系统总推的扣量设置复制给所有线上推广员)' ,
`rmb_divided`  decimal(16,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '库存:历史总分成金额' ,
`rmb_cashed`  decimal(16,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '库存:历史已兑换金额' ,
`rmb_handled`  decimal(16,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '库存:历史正反补金额(出错后的手动调整)' ,
`rmb_can_get`  decimal(16,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '库存:当前可兑换金额' ,
`cash_pass`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '兑换:密码' ,
`cash_try_day`  date NULL DEFAULT NULL COMMENT '兑换:最后的密码输入日期' ,
`cash_e_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换:密码连续出错次数' ,
`data_group`  smallint(1) NOT NULL DEFAULT 0 COMMENT '数据:可查看的数据分组(下级数据权限以1级为准)' ,
`data_time`  timestamp NULL DEFAULT NULL COMMENT '数据:数据修改时间' ,
`data_user`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '数据:数据修改管理员' ,
`num_lowers_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:所有后代数量(所有推广员)' ,
`num_lowers_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日后代增加数量' ,
`num_direct_all`  int(11) NULL DEFAULT 0 COMMENT '下级:子代增加数量(直推推广员)' ,
`num_direct_today`  int(11) NULL DEFAULT 0 COMMENT '下级:今日子代增加数量' ,
`num_today_date`  date NULL DEFAULT NULL COMMENT '下级:统计后代子代数据后保存的’今日‘' ,
PRIMARY KEY (`guid`),
INDEX `idx_upper` (`upper`) USING BTREE ,
INDEX `idx_type_level` (`type`, `level`) USING BTREE ,
INDEX `idx_ok_time` (`ok_time`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of p_promoters
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for p_settle_log
-- ----------------------------
DROP TABLE IF EXISTS `p_settle_log`;
CREATE TABLE `p_settle_log` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL COMMENT '推广员Id' ,
`type`  tinyint(1) NOT NULL COMMENT '变动类型(0:系统差补,1:分成收入,2:兑换申请,3:兑换失败)' ,
`join`  varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '关联参数(与类型对应,0:手动操作,1:分成日期,2:兑换订单ID,3:兑换订单ID)' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '变动时间' ,
`m_old`  decimal(16,2) NOT NULL COMMENT '金额:变动前' ,
`money`  decimal(16,2) NOT NULL COMMENT '金额:变动值' ,
`m_new`  decimal(16,2) NOT NULL COMMENT '金额:变动后' ,
`plat_id`  tinyint(4) NOT NULL COMMENT '隶属平台' ,
`req_ip`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '仅抓取参数HTTP_X_FORWARDED_FOR的IP' ,
PRIMARY KEY (`id`),
INDEX `idx_time_guid` (`time`, `guid`) USING BTREE ,
INDEX `idx_time_plat_id` (`time`, `plat_id`) USING BTREE ,
INDEX `idx_guid_time` (`guid`, `join`, `type`) USING BTREE ,
INDEX `idx_type_join` (`type`, `join`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of p_settle_log
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
UNIQUE INDEX `unq_role_permission` (`role_id`, `permission_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=309

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
AUTO_INCREMENT=2203

;

-- ----------------------------
-- Records of permissions
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
UNIQUE INDEX `index_user_role` (`user_id`, `role_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=64

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
AUTO_INCREMENT=13

;

-- ----------------------------
-- Records of roles
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`guid`  int(11) NOT NULL DEFAULT 0 COMMENT '推广员guid>0' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`email`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`password`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`remember_token`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `uni_name` (`name`) USING BTREE ,
UNIQUE INDEX `uni_email` (`email`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=66

;

-- ----------------------------
-- Records of users
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wt_day_guid_create
-- ----------------------------
DROP TABLE IF EXISTS `wt_day_guid_create`;
CREATE TABLE `wt_day_guid_create` (
`guid`  int(11) NOT NULL ,
`day`  date NOT NULL ,
`pro_id`  int(1) NOT NULL ,
PRIMARY KEY (`guid`),
INDEX `idx_day` (`day`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wt_day_guid_create
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wt_day_guid_login
-- ----------------------------
DROP TABLE IF EXISTS `wt_day_guid_login`;
CREATE TABLE `wt_day_guid_login` (
`day`  date NOT NULL ,
`pro_id`  int(1) NOT NULL COMMENT '推广员ID' ,
`guid`  int(11) NOT NULL ,
PRIMARY KEY (`day`, `pro_id`, `guid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wt_day_guid_login
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wt_pro_day_sheet_base
-- ----------------------------
DROP TABLE IF EXISTS `wt_pro_day_sheet_base`;
CREATE TABLE `wt_pro_day_sheet_base` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`pro_id`  int(11) NOT NULL COMMENT '推广员ID' ,
`join_is_ok`  tinyint(1) NULL DEFAULT 0 COMMENT '关联是否正常' ,
`join_ratio`  decimal(3,2) NULL DEFAULT NULL COMMENT '关联:税收分成比例' ,
`join_upper`  int(11) NULL DEFAULT NULL COMMENT '关联:上级推广员ID' ,
`join_upper1`  int(11) NULL DEFAULT NULL COMMENT '关联:1级推广员ID' ,
`join_type`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:线上1,线下2' ,
`join_level`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:推广员级别' ,
`join_enable`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:启用或者禁用' ,
`join_plat_id`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:平台ID' ,
`join_kl_line`  int(11) NULL DEFAULT NULL COMMENT '关联:扣量线' ,
`join_kl_ratio`  decimal(2,2) NULL DEFAULT NULL COMMENT '关联:扣量比例' ,
`join_ok_day`  date NULL DEFAULT NULL COMMENT '关联:创建日期' ,
`user_register`  int(11) NOT NULL DEFAULT 0 COMMENT '注册玩家' ,
`user_reg_bind`  int(11) NOT NULL DEFAULT 0 COMMENT '注册绑定用户数(注册当日绑定)' ,
`user_reg_ubind`  int(11) NOT NULL DEFAULT 0 COMMENT '注册未绑定用户数(注册当日绑定)' ,
`user_bindPhone`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定手机' ,
`user_bindAlipay`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定支付宝' ,
`user_login`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆玩家数' ,
`user_active`  int(11) NOT NULL DEFAULT 0 COMMENT '活跃玩家数' ,
`user_register_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册玩家' ,
`user_reg_bind_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册绑定用户数(注册当日绑定)' ,
`user_reg_ubind_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册未绑定用户数(注册当日绑定)' ,
`pay_times_total`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数' ,
`pay_times_new`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数(新)' ,
`pay_times_old`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数(老)' ,
`pay_people_total`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数' ,
`pay_people_new`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数(新)' ,
`pay_people_old`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数(老)' ,
`pay_rmb_react`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(无费)' ,
`pay_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(含费)' ,
`pay_rmb_new`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(新)' ,
`pay_rmb_old`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(老)' ,
`first_people`  int(11) NOT NULL DEFAULT 0 COMMENT '首充人数(新增充值人数)' ,
`first_time_pay`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '首充金额' ,
`first_day_pay`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新增充值金额' ,
`cash_people`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换人数' ,
`cash_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换次数' ,
`cash_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额' ,
`tax_reg`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册用户税收' ,
`tax_reg_bind`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册绑定用户税收(注册当日绑定)' ,
`tax_reg_ubind`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册未绑定用户税收(注册当日绑定)' ,
`tax_reg_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册用户税收' ,
`tax_reg_bind_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册绑定用户税收(注册当日绑定)' ,
`tax_reg_ubind_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册未绑定用户税收(注册当日绑定)' ,
`back_1_login`  int(11) NOT NULL DEFAULT 0 COMMENT '昨日回头登陆' ,
`back_1_create`  int(11) NOT NULL DEFAULT 0 COMMENT '昨日回头创建' ,
`back_3_login`  int(11) NOT NULL DEFAULT 0 COMMENT '3日回头登陆' ,
`back_3_create`  int(11) NOT NULL DEFAULT 0 COMMENT '3日回头创建' ,
`back_7_login`  int(11) NOT NULL DEFAULT 0 COMMENT '7日回头登陆' ,
`back_7_create`  int(11) NOT NULL DEFAULT 0 COMMENT '7日回头创建' ,
`back_15_login`  int(11) NOT NULL DEFAULT 0 COMMENT '15日回头登陆' ,
`back_15_create`  int(11) NOT NULL DEFAULT 0 COMMENT '15日回头创建' ,
`back_1_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '1日回头率' ,
`back_3_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_7_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_15_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`tax_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额' ,
`tax_direct`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推税收' ,
`res_prifit`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '结果:所得利润' ,
`res_detail`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '结果:计算细节' ,
`tax_rmb_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额(已扣量)' ,
`tax_direct_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推税收(已扣量)' ,
`res_prifit_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '结果:所得利润(已扣量)' ,
`res_detail_kled`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '结果:计算细节(已扣量)' ,
`num_lowers_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:所有后代数量(所有推广员)' ,
`num_lowers_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日后代增加数量' ,
`num_direct_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:子代增加数量(直推推广员)' ,
`num_direct_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日子代增加数量' ,
PRIMARY KEY (`day`, `pro_id`),
INDEX `idx_plat_id_pro_id` (`pro_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wt_pro_day_sheet_base
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wt_pro_day_sheet_cache
-- ----------------------------
DROP TABLE IF EXISTS `wt_pro_day_sheet_cache`;
CREATE TABLE `wt_pro_day_sheet_cache` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`pro_id`  int(11) NOT NULL COMMENT '推广员ID' ,
`join_is_ok`  tinyint(1) NULL DEFAULT 0 COMMENT '关联是否正常' ,
`join_ratio`  decimal(3,2) NULL DEFAULT NULL COMMENT '关联:税收分成比例' ,
`join_upper`  int(11) NULL DEFAULT NULL COMMENT '关联:上级推广员ID' ,
`join_upper1`  int(11) NULL DEFAULT NULL COMMENT '关联:1级推广员ID' ,
`join_type`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:线上1,线下2' ,
`join_level`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:推广员级别' ,
`join_enable`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:启用或者禁用' ,
`join_plat_id`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:平台ID' ,
`join_kl_line`  int(11) NULL DEFAULT NULL COMMENT '关联:扣量线' ,
`join_kl_ratio`  decimal(2,2) NULL DEFAULT NULL COMMENT '关联:扣量比例' ,
`join_ok_day`  date NULL DEFAULT NULL COMMENT '关联:创建日期' ,
`user_register`  int(11) NOT NULL DEFAULT 0 COMMENT '注册玩家' ,
`user_reg_bind`  int(11) NOT NULL DEFAULT 0 COMMENT '注册绑定用户数(注册当日绑定)' ,
`user_reg_ubind`  int(11) NOT NULL DEFAULT 0 COMMENT '注册未绑定用户数(注册当日绑定)' ,
`user_bindPhone`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定手机' ,
`user_bindAlipay`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定支付宝' ,
`user_login`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆玩家数' ,
`user_active`  int(11) NOT NULL DEFAULT 0 COMMENT '活跃玩家数' ,
`user_register_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册玩家' ,
`user_reg_bind_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册绑定用户数(注册当日绑定)' ,
`user_reg_ubind_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册未绑定用户数(注册当日绑定)' ,
`pay_times_total`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数' ,
`pay_times_new`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数(新)' ,
`pay_times_old`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数(老)' ,
`pay_people_total`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数' ,
`pay_people_new`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数(新)' ,
`pay_people_old`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数(老)' ,
`pay_rmb_react`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(无费)' ,
`pay_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(含费)' ,
`pay_rmb_new`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(新)' ,
`pay_rmb_old`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(老)' ,
`first_people`  int(11) NOT NULL DEFAULT 0 COMMENT '首充人数(新增充值人数)' ,
`first_time_pay`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '首充金额' ,
`first_day_pay`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新增充值金额' ,
`cash_people`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换人数' ,
`cash_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换次数' ,
`cash_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额' ,
`tax_reg`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册用户税收' ,
`tax_reg_bind`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册绑定用户税收(注册当日绑定)' ,
`tax_reg_ubind`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册未绑定用户税收(注册当日绑定)' ,
`tax_reg_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册用户税收' ,
`tax_reg_bind_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册绑定用户税收(注册当日绑定)' ,
`tax_reg_ubind_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册未绑定用户税收(注册当日绑定)' ,
`back_1_login`  int(11) NOT NULL DEFAULT 0 COMMENT '昨日回头登陆' ,
`back_1_create`  int(11) NOT NULL DEFAULT 0 COMMENT '昨日回头创建' ,
`back_3_login`  int(11) NOT NULL DEFAULT 0 COMMENT '3日回头登陆' ,
`back_3_create`  int(11) NOT NULL DEFAULT 0 COMMENT '3日回头创建' ,
`back_7_login`  int(11) NOT NULL DEFAULT 0 COMMENT '7日回头登陆' ,
`back_7_create`  int(11) NOT NULL DEFAULT 0 COMMENT '7日回头创建' ,
`back_15_login`  int(11) NOT NULL DEFAULT 0 COMMENT '15日回头登陆' ,
`back_15_create`  int(11) NOT NULL DEFAULT 0 COMMENT '15日回头创建' ,
`back_1_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '1日回头率' ,
`back_3_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_7_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_15_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`tax_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额' ,
`tax_direct`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推税收' ,
`res_prifit`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '结果:所得利润' ,
`res_detail`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '结果:计算细节' ,
`tax_rmb_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额(已扣量)' ,
`tax_direct_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推税收(已扣量)' ,
`res_prifit_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '结果:所得利润(已扣量)' ,
`res_detail_kled`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '结果:计算细节(已扣量)' ,
`num_lowers_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:所有后代数量(所有推广员)' ,
`num_lowers_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日后代增加数量' ,
`num_direct_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:子代增加数量(直推推广员)' ,
`num_direct_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日子代增加数量' ,
PRIMARY KEY (`day`, `pro_id`),
INDEX `idx_plat_id_pro_id` (`pro_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wt_pro_day_sheet_cache
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wt_pro_day_sheet_show
-- ----------------------------
DROP TABLE IF EXISTS `wt_pro_day_sheet_show`;
CREATE TABLE `wt_pro_day_sheet_show` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`pro_id`  int(11) NOT NULL COMMENT '推广员ID' ,
`join_is_ok`  tinyint(1) NULL DEFAULT 0 COMMENT '关联是否正常' ,
`join_ratio`  decimal(3,2) NULL DEFAULT NULL COMMENT '关联:税收分成比例' ,
`join_upper`  int(11) NULL DEFAULT NULL COMMENT '关联:上级推广员ID' ,
`join_upper1`  int(11) NULL DEFAULT NULL COMMENT '关联:1级推广员ID' ,
`join_type`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:线上1,线下2' ,
`join_level`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:推广员级别' ,
`join_enable`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:启用或者禁用' ,
`join_plat_id`  tinyint(1) NULL DEFAULT NULL COMMENT '关联:平台ID' ,
`join_kl_line`  int(11) NULL DEFAULT NULL COMMENT '关联:扣量线' ,
`join_kl_ratio`  decimal(2,2) NULL DEFAULT NULL COMMENT '关联:扣量比例' ,
`join_ok_day`  date NULL DEFAULT NULL COMMENT '关联:创建日期' ,
`user_register`  int(11) NOT NULL DEFAULT 0 COMMENT '注册玩家' ,
`user_reg_bind`  int(11) NOT NULL DEFAULT 0 COMMENT '注册绑定用户数(注册当日绑定)' ,
`user_reg_ubind`  int(11) NOT NULL DEFAULT 0 COMMENT '注册未绑定用户数(注册当日绑定)' ,
`user_bindPhone`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定手机' ,
`user_bindAlipay`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定支付宝' ,
`user_login`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆玩家数' ,
`user_active`  int(11) NOT NULL DEFAULT 0 COMMENT '活跃玩家数' ,
`user_register_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册玩家' ,
`user_reg_bind_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册绑定用户数(注册当日绑定)' ,
`user_reg_ubind_d`  int(11) NOT NULL DEFAULT 0 COMMENT '直推注册未绑定用户数(注册当日绑定)' ,
`pay_times_total`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数' ,
`pay_times_new`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数(新)' ,
`pay_times_old`  int(11) NOT NULL DEFAULT 0 COMMENT '充值次数(老)' ,
`pay_people_total`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数' ,
`pay_people_new`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数(新)' ,
`pay_people_old`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数(老)' ,
`pay_rmb_react`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(无费)' ,
`pay_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(含费)' ,
`pay_rmb_new`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(新)' ,
`pay_rmb_old`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值钱数(老)' ,
`first_people`  int(11) NOT NULL DEFAULT 0 COMMENT '首充人数(新增充值人数)' ,
`first_time_pay`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '首充金额' ,
`first_day_pay`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新增充值金额' ,
`cash_people`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换人数' ,
`cash_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换次数' ,
`cash_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额' ,
`tax_reg`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册用户税收' ,
`tax_reg_bind`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册绑定用户税收(注册当日绑定)' ,
`tax_reg_ubind`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '注册未绑定用户税收(注册当日绑定)' ,
`tax_reg_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册用户税收' ,
`tax_reg_bind_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册绑定用户税收(注册当日绑定)' ,
`tax_reg_ubind_d`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推注册未绑定用户税收(注册当日绑定)' ,
`back_1_login`  int(11) NOT NULL DEFAULT 0 COMMENT '昨日回头登陆' ,
`back_1_create`  int(11) NOT NULL DEFAULT 0 COMMENT '昨日回头创建' ,
`back_3_login`  int(11) NOT NULL DEFAULT 0 COMMENT '3日回头登陆' ,
`back_3_create`  int(11) NOT NULL DEFAULT 0 COMMENT '3日回头创建' ,
`back_7_login`  int(11) NOT NULL DEFAULT 0 COMMENT '7日回头登陆' ,
`back_7_create`  int(11) NOT NULL DEFAULT 0 COMMENT '7日回头创建' ,
`back_15_login`  int(11) NOT NULL DEFAULT 0 COMMENT '15日回头登陆' ,
`back_15_create`  int(11) NOT NULL DEFAULT 0 COMMENT '15日回头创建' ,
`back_1_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '1日回头率' ,
`back_3_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_7_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_15_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`tax_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额' ,
`tax_direct`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推税收' ,
`res_prifit`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '结果:所得利润' ,
`res_detail`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '结果:计算细节' ,
`tax_rmb_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额(已扣量)' ,
`tax_direct_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '直推税收(已扣量)' ,
`res_prifit_kled`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '结果:所得利润(已扣量)' ,
`res_detail_kled`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '结果:计算细节(已扣量)' ,
`num_lowers_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:所有后代数量(所有推广员)' ,
`num_lowers_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日后代增加数量' ,
`num_direct_all`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:子代增加数量(直推推广员)' ,
`num_direct_today`  int(11) NOT NULL DEFAULT 0 COMMENT '下级:今日子代增加数量' ,
PRIMARY KEY (`day`, `pro_id`),
INDEX `idx_plat_id_pro_id` (`pro_id`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wt_pro_day_sheet_show
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Auto increment value for menus
-- ----------------------------
ALTER TABLE `menus` AUTO_INCREMENT=18;

-- ----------------------------
-- Auto increment value for message_board
-- ----------------------------
ALTER TABLE `message_board` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_application
-- ----------------------------
ALTER TABLE `p_application` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_backpic
-- ----------------------------
ALTER TABLE `p_backpic` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_cash_order
-- ----------------------------
ALTER TABLE `p_cash_order` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_data_group
-- ----------------------------
ALTER TABLE `p_data_group` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_domain_guid
-- ----------------------------
ALTER TABLE `p_domain_guid` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_domain_pool
-- ----------------------------
ALTER TABLE `p_domain_pool` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for p_settle_log
-- ----------------------------
ALTER TABLE `p_settle_log` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permission_role
-- ----------------------------
ALTER TABLE `permission_role` AUTO_INCREMENT=309;

-- ----------------------------
-- Auto increment value for permission_user
-- ----------------------------
ALTER TABLE `permission_user` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permissions
-- ----------------------------
ALTER TABLE `permissions` AUTO_INCREMENT=2203;

-- ----------------------------
-- Auto increment value for role_user
-- ----------------------------
ALTER TABLE `role_user` AUTO_INCREMENT=64;

-- ----------------------------
-- Auto increment value for roles
-- ----------------------------
ALTER TABLE `roles` AUTO_INCREMENT=13;

-- ----------------------------
-- Auto increment value for users
-- ----------------------------
ALTER TABLE `users` AUTO_INCREMENT=66;
