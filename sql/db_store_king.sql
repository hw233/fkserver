/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : db_store_king

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:31:30
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS db_store_king;
CREATE DATABASE db_store_king;
USE db_store_king;

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
-- Table structure for channel_business
-- ----------------------------
DROP TABLE IF EXISTS `channel_business`;
CREATE TABLE `channel_business` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`business_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道商名字' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`tax`  decimal(5,4) NOT NULL DEFAULT 0.0000 COMMENT '提成比，单位：%，max=1' ,
`d_tax`  decimal(5,4) NULL DEFAULT NULL ,
`line_recharge`  int(11) NULL DEFAULT 30000 COMMENT '充值扣量起征点，单位：元' ,
`line_cash`  int(11) NULL DEFAULT 24000 COMMENT '提现扣量起征点，单位:元' ,
`line_tax`  int(11) NULL DEFAULT 6000 COMMENT '税收扣量起征点，单位:元' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_business_name` (`business_name`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道商表'
AUTO_INCREMENT=22

;

-- ----------------------------
-- Records of channel_business
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for channel_plat
-- ----------------------------
DROP TABLE IF EXISTS `channel_plat`;
CREATE TABLE `channel_plat` (
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分包平台ID（0是默认平台王者游戏）' ,
`name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '分包平台名' ,
PRIMARY KEY (`plat_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of channel_plat
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for channel_tax
-- ----------------------------
DROP TABLE IF EXISTS `channel_tax`;
CREATE TABLE `channel_tax` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`channel`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`business`  int(10) NOT NULL DEFAULT 0 COMMENT '渠道商户' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '该渠道包隶属的平台ID' ,
`tax`  decimal(5,4) NOT NULL DEFAULT 0.0000 COMMENT '扣量比，单位：%，max=1' ,
`is_auto_kouliang`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否启动自动扣量' ,
`auto_day_start`  date NULL DEFAULT NULL COMMENT '自动扣量的起始日期（如一号由0.20开始，每天递增0.01，十天后到0.30）' ,
`auto_kouliang_min`  decimal(5,4) UNSIGNED NULL DEFAULT NULL COMMENT '自动扣量的起始扣量（如起始：0.20）' ,
`auto_kouliang_add`  decimal(5,4) UNSIGNED NULL DEFAULT NULL COMMENT '自动扣量每天的递增量（如递增：0.01）' ,
`auto_koulinag_max`  decimal(5,4) UNSIGNED NULL DEFAULT NULL COMMENT '自动扣量的最终扣量（如最终：0.30）' ,
`bag_account_pwd`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '包账号密码(明文)' ,
`line_recharge`  int(11) NULL DEFAULT 30000 COMMENT '充值扣量起征点，单位元' ,
`line_cash`  int(11) NULL DEFAULT 24000 COMMENT '提现扣量起征点，单位元' ,
`line_tax`  int(11) NULL DEFAULT 6000 COMMENT '税收扣量起征点，单位元' ,
`phone_type`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '终端型号ios android' ,
`show_channel`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '对外渠道号' ,
`drop_versions`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '要废弃的版本号(全部废弃，填***)，该版本号需要强制升级到指定的version字段的版本，必须是json数组格式，如:[\"1.2.0\",\"1.2.1\"]' ,
`version`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包的版本号' ,
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '包名' ,
`url`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '安装包地址' ,
`is_pro_bag`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '推广:是否是推广专用包(1:是,0:否),推广员专用包不能关联渠道商、不能设置扣量比例' ,
`is_on_pro`  tinyint(1) NULL DEFAULT 0 COMMENT '推广:该推广员是否正在使用，每个平台的IOS和安卓仅启用一个包' ,
`ext_cfg`  varchar(8192) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '推广包额外配置参数（支付策略中使用，API缓存）' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL COMMENT '更新时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `channel_index` (`channel`) USING BTREE COMMENT '渠道号索引',
INDEX `is_on_pro` (`is_on_pro`, `plat_id`, `phone_type`) USING BTREE ,
INDEX `is_pro_bag` (`is_pro_bag`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='渠道商户和安装包关联表'
AUTO_INCREMENT=2174

;

-- ----------------------------
-- Records of channel_tax
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for ds_deamon_record
-- ----------------------------
DROP TABLE IF EXISTS `ds_deamon_record`;
CREATE TABLE `ds_deamon_record` (
`time`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '格式化时间' ,
`type`  char(4) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '执行行为类型:init,exec,kill' ,
`path`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '执行脚本的路径' 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of ds_deamon_record
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for ds_errors_record
-- ----------------------------
DROP TABLE IF EXISTS `ds_errors_record`;
CREATE TABLE `ds_errors_record` (
`serial`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`time`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`level`  tinyint(1) NULL DEFAULT NULL COMMENT '1:Bebug,2:Warn,3:Notic,4:Delay,5:Excep,6:Error,7:Fatal' ,
`moudle`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '模块名' ,
`model`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '模型名' ,
`file`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '文件行号' ,
`message`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '错误原因' ,
`trace`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '调用信息' ,
PRIMARY KEY (`serial`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of ds_errors_record
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for ds_progress_kvs
-- ----------------------------
DROP TABLE IF EXISTS `ds_progress_kvs`;
CREATE TABLE `ds_progress_kvs` (
`k`  char(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '一般格式model|anchorDb|...可保证该脚本有唯一的k' ,
`v`  char(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '脚本执行进度' ,
`t`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '进度保存时间' ,
PRIMARY KEY (`k`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of ds_progress_kvs
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for ds_select_cycle
-- ----------------------------
DROP TABLE IF EXISTS `ds_select_cycle`;
CREATE TABLE `ds_select_cycle` (
`serial`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增用以查找更新' ,
`model`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '任务类的类名' ,
`anchorKv`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '补充参数,只能是一维的、Key不为数字的、不含特殊字符的JSON格式' ,
`runType`  varchar(8) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '运行类型: hourly,daily,weekly,monthly' ,
`runTime`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '多组以\",\"连接,月日期不能大于28,单组格式:hourly(%i%s),daily(%H%i%s),weekly(%w%H%i%s),monthly(%d%H%i%s)' ,
`isUseful`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Unknow' COMMENT '参数是否可用的检测结果' ,
`manualEnable`  char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '手动设定继续运行或者关闭' ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `unique` (`model`, `anchorKv`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=14

;

-- ----------------------------
-- Records of ds_select_cycle
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for ds_select_forever
-- ----------------------------
DROP TABLE IF EXISTS `ds_select_forever`;
CREATE TABLE `ds_select_forever` (
`serial`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`model`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '任务类的类名' ,
`anchorKv`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '补充参数,只能是一维的、Key不为数字的、不含特殊字符的JSON格式' ,
`isUseful`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'Unknow' COMMENT '参数是否可用的检测结果' ,
`manualEnable`  char(1) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '手动设定继续运行或者关闭' ,
PRIMARY KEY (`serial`),
UNIQUE INDEX `unique` (`model`, `anchorKv`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=10

;

-- ----------------------------
-- Records of ds_select_forever
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
AUTO_INCREMENT=19

;

-- ----------------------------
-- Records of menus
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
AUTO_INCREMENT=54

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
AUTO_INCREMENT=91

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
INDEX `role_user_role_id_index` (`role_id`) USING BTREE ,
INDEX `role_user_user_id_index` (`user_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=56

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
AUTO_INCREMENT=4

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
`name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`email`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`password`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`remember_token`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`is_bag`  tinyint(2) NULL DEFAULT 0 COMMENT '是否是包账号' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `users_email_unique` (`email`) USING BTREE ,
UNIQUE INDEX `uni_name` (`name`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=60

;

-- ----------------------------
-- Records of users
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_a_data_business
-- ----------------------------
DROP TABLE IF EXISTS `wz_a_data_business`;
CREATE TABLE `wz_a_data_business` (
`buss_id`  int(11) NOT NULL COMMENT '渠道商ID,与channel_business的ID对应' ,
`group_id`  int(11) NOT NULL COMMENT '该渠道商可以查看的数据功能ID的集合，以“,”分割' ,
`update_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`buss_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_a_data_business
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_a_data_group
-- ----------------------------
DROP TABLE IF EXISTS `wz_a_data_group`;
CREATE TABLE `wz_a_data_group` (
`group_id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '数据组合的ID' ,
`group_name`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '数据组合的名称' ,
`func_id_s`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '数据组合的具体功能ID，多个以‘,’分割' ,
PRIMARY KEY (`group_id`),
UNIQUE INDEX `unq_name` (`group_name`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=18

;

-- ----------------------------
-- Records of wz_a_data_group
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_a_data_viewer
-- ----------------------------
DROP TABLE IF EXISTS `wz_a_data_viewer`;
CREATE TABLE `wz_a_data_viewer` (
`viewer_id`  int(11) UNSIGNED NOT NULL COMMENT '数据观察者的ID，关联users中的用户id' ,
`buss_id`  int(11) NULL DEFAULT NULL COMMENT '隶属于的上级渠道商，如果有上级，查看的包和数据权限就不能超出上级' ,
`bag_ids`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '数据观察者可用的渠道包ID串，以,分割' ,
`group_id`  int(11) NULL DEFAULT NULL COMMENT '指定的数据组合ID' ,
`update_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`viewer_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_a_data_viewer
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_calendar
-- ----------------------------
DROP TABLE IF EXISTS `wz_calendar`;
CREATE TABLE `wz_calendar` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '日期表，用于查询时关联' ,
PRIMARY KEY (`day`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_calendar
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_ch_day_sheet
-- ----------------------------
DROP TABLE IF EXISTS `wz_ch_day_sheet`;
CREATE TABLE `wz_ch_day_sheet` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID' ,
`buss_id`  int(11) NOT NULL DEFAULT '-1' COMMENT '关联渠道商ID' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID，默认是王者' ,
`register`  int(11) NOT NULL DEFAULT 0 COMMENT '注册玩家' ,
`bindPhone`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定手机' ,
`bindAlipay`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定支付宝' ,
`login`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆玩家数' ,
`active`  int(11) NOT NULL DEFAULT 0 COMMENT '活跃玩家数' ,
`pay_people`  int(11) NOT NULL DEFAULT 0 COMMENT '充值人数' ,
`fencheng_0`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收中产生的渠道分成' ,
`recharge_0`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值手续费后的充值金额' ,
`yingshou_0`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '更真实的平台营收（系统报表会使用），recharge_0 - cash_rmb_1 - fencheng_0' ,
`pay_rmb_avg_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '人均充值-平台可见' ,
`pay_rmb_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额-平台可见' ,
`cash_rmb_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额-平台可见' ,
`tax_rmb_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额-平台可见' ,
`yingshou_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '营收总额-平台可见（未扣除充值渠道手续费），pay_rmb_1 - cash_rmb_1 - fencheng_0' ,
`back_1`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_3`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_7`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_15`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户价值(LTV)-平台可见' ,
`pay_rmb_avg_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '人均充值-渠道可见' ,
`pay_rmb_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额-渠道可见' ,
`cash_rmb_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额-渠道可见' ,
`tax_rmb_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '税收总额-渠道可见' ,
`yingshou_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '营收总额-渠道可见（未扣除充值渠道手续费），pay_rmb_2 - cash_rmb_2 - fencheng_0' ,
`login_people_pay_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '登陆用户付费率：当天充值总人数/登天总登入的客户' ,
`new_people_pay_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '新增用户付费率：新增充值人数/当天总注册人数' ,
`new_people_pay_avg_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平台：新增用户平均充值：当天新增充值总额/当天新增客户人数' ,
`new_people_pay_avg_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道：新增用户平均充值：当天新增充值总额/当天新增客户人数' ,
`old_people_pay_avg_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平台：老用户平均充值：（充值总额-新增充值）/（总充值人数-当天新增充值人数）' ,
`old_people_pay_avg_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道：老用户平均充值：（充值总额-新增充值）/（总充值人数-当天新增充值人数）' ,
`yingshou_pay_people_avg_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平台：总用户人均盈利：总营收/总充值人数' ,
`yingshou_pay_people_avg_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道：总用户人均盈利：总营收/总充值人数' ,
`first_pay_people`  int(11) NOT NULL DEFAULT 0 COMMENT '该天该包首次充值的人数，也是新增充值人数' ,
`first_pay_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平台：该天该包首次充值的金额' ,
`first_pay_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道：该天该包首次充值的金额' ,
`first_day_pay_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平台：该天该包新增充值金额' ,
`first_day_pay_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道：该天该包新增充值金额' ,
`pay_people_z`  int(11) NOT NULL DEFAULT 0 COMMENT '在线充值人数' ,
`pay_rmb_z_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '在线充值金额' ,
`pay_rmb_z_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '在线充值金额(扣量后，渠道可见)' ,
`pay_people_d`  int(11) NOT NULL DEFAULT 0 COMMENT '代理充值人数' ,
`pay_rmb_d_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理充值金额' ,
`pay_rmb_d_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理充值金额(扣量后，渠道可见)' ,
`game_info_1`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '游戏税收及输赢详情(单位是元)' ,
`game_info_2`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '游戏税收及输赢详情(单位是元)(扣量后，渠道可见)' ,
PRIMARY KEY (`day`, `bag_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_ch_day_sheet
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_ch_day_sheet_cache
-- ----------------------------
DROP TABLE IF EXISTS `wz_ch_day_sheet_cache`;
CREATE TABLE `wz_ch_day_sheet_cache` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '生成wz_ch_day_sheet数据的脚本所使用的缓存表' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '包ID' ,
`buss_id`  int(11) NULL DEFAULT 0 COMMENT '渠道商ID' ,
`plat_id`  int(11) NULL DEFAULT NULL COMMENT '分发平台ID，默认是王者' 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_ch_day_sheet_cache
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_ch_hour_sheet
-- ----------------------------
DROP TABLE IF EXISTS `wz_ch_hour_sheet`;
CREATE TABLE `wz_ch_hour_sheet` (
`hour`  char(13) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '从wz_ch_day_sheet触发过来的每小时节点数据' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '渠道包ID' ,
`buss_id`  int(11) NOT NULL DEFAULT 0 COMMENT '关联渠道商ID' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID，默认是王者' ,
`pay_rmb_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额-平台可见' ,
`pay_rmb_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额-渠道可见' ,
`cash_rmb_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额-平台可见' ,
`cash_rmb_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总额-渠道可见' ,
`register`  int(11) NOT NULL DEFAULT 0 COMMENT '注册人数' ,
PRIMARY KEY (`hour`, `bag_id`),
INDEX `indx_bag_buss` (`bag_id`, `buss_id`) USING BTREE ,
INDEX `idx_buss_bag` (`buss_id`, `bag_id`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_ch_hour_sheet
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_bag_cash
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_bag_cash`;
CREATE TABLE `wz_day_bag_cash` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`bag_cash_line`  int(11) NULL DEFAULT 24000 COMMENT '该天该包关联到的提现扣量起点,单位是元' ,
`bag_kouliang_ratio`  decimal(5,4) NULL DEFAULT 0.0000 COMMENT '该天该包关联到的扣量比' ,
`buss_id`  int(11) NULL DEFAULT NULL COMMENT '该天该包关联的渠道商ID' ,
`cash_rmb`  bigint(20) NULL DEFAULT 0 COMMENT '该天该包的提现金额,单位是元' ,
`cash_kouliang_rmb`  bigint(20) NULL DEFAULT 0 COMMENT '该天该包的扣量后的提现总额，单位是元' ,
`cash_times`  int(11) NULL DEFAULT 0 COMMENT '该天该包的提现次数' ,
`cash_people`  int(11) NULL DEFAULT 0 COMMENT '该天该包的提现人数' ,
PRIMARY KEY (`day`, `bag_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_bag_cash
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_bag_recharge
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_bag_recharge`;
CREATE TABLE `wz_day_bag_recharge` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID' ,
`bag_pay_line`  int(11) NULL DEFAULT 30000 COMMENT '该日该包关联到的支付扣量起点，单位是元' ,
`bag_kouliang_ratio`  decimal(5,4) NULL DEFAULT 0.0000 COMMENT '该日该包的扣量比' ,
`buss_id`  int(11) NULL DEFAULT NULL COMMENT '该日该包可关联到的渠道商ID' ,
`pay_rmb`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包成功充值的钱数，单位元' ,
`act_rmb`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包扣除充值渠道收费后的钱数，单位元' ,
`pay_kouliang_rmb`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包扣量后的成功支付钱数，单位元' ,
`pay_times`  int(11) NULL DEFAULT 0 COMMENT '该日该包成功充值的次数' ,
`pay_people`  int(11) NULL DEFAULT 0 COMMENT '该日该包成功充值的人数' ,
`pay_people_new`  int(11) NULL DEFAULT 0 COMMENT '该日该包成功充值的新玩家数' ,
`pay_rmb_new`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包新玩家的支付钱数，单位元' ,
`pay_kouliang_rmb_new`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包新玩家的按扣量真实比例缩小后支付钱数，单位元' ,
`first_pay_people`  int(11) NULL DEFAULT 0 COMMENT '该日该包首次充值的人数' ,
`first_pay_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包首次充值的数额，单位元' ,
`first_pay_money_kouliang`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包首次充值的数额，已按扣量真实比例缩小，单位元' ,
`first_day_pay_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包首次充值玩家当天充值的总额，单位元' ,
`first_day_pay_money_kouliang`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日该包首次充值玩家当天充值的总额，已按扣量真实比例缩小，单位元' ,
`pay_people_z`  int(11) NULL DEFAULT 0 COMMENT '在线充值人数' ,
`pay_times_z`  int(11) NULL DEFAULT 0 COMMENT '在线充值次数' ,
`pay_rmb_z`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '在线充值金额，单位元' ,
`pay_kouliang_rmb_z`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '在线充值金额，单位元(扣量后)' ,
`pay_people_d`  int(11) NULL DEFAULT 0 COMMENT '代理充值人数' ,
`pay_times_d`  int(11) NULL DEFAULT 0 COMMENT '代理充值次数' ,
`pay_rmb_d`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理充值金额，单位元' ,
`pay_kouliang_rmb_d`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理充值金额，单位元(扣量后)' ,
PRIMARY KEY (`day`, `bag_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_bag_recharge
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_bag_reg_bind_active
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_bag_reg_bind_active`;
CREATE TABLE `wz_day_bag_reg_bind_active` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(该表记录每天每个包ID下的创建数，绑定手机数，登陆数)' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID' ,
`buss_id`  int(11) NULL DEFAULT '-1' COMMENT '该天该包可被关联上的渠道商ID' ,
`register`  int(11) NULL DEFAULT 0 COMMENT '该天该包注册人数' ,
`bindPhone`  int(11) NULL DEFAULT 0 COMMENT '该天该包绑定手机人数' ,
`bindAlipay`  int(11) NULL DEFAULT 0 COMMENT '该天该包绑定支付宝人数' ,
`login`  int(11) NULL DEFAULT 0 COMMENT '该天该包登陆人数' ,
`active`  int(11) NULL DEFAULT 0 COMMENT '该天该包活跃人数' ,
PRIMARY KEY (`day`, `bag_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_bag_reg_bind_active
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_bag_tax
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_bag_tax`;
CREATE TABLE `wz_day_bag_tax` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '日期' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '每天统计时查到的包ID,关联channel_tax里的channel' ,
`bag_id_ok`  tinyint(1) NULL DEFAULT 0 COMMENT '该天该包是否找到了对应的包ID' ,
`bag_sum_tax`  bigint(20) NOT NULL DEFAULT 0 COMMENT '该天该包的总税收,单位是金币' ,
`bag_tax_line`  int(11) NULL DEFAULT 600000 COMMENT '该天该包的扣量起始点，单位是分(与金币保持单位大小一致)' ,
`bag_kouliang_ratio`  decimal(5,4) NULL DEFAULT 0.0000 COMMENT '该天该包的扣量比，关联channel_tax里的tax' ,
`bag_kouliang_tax`  bigint(20) NULL DEFAULT 0 COMMENT '该天该包扣量后的总税收，单位是金币' ,
`buss_id`  int(11) NULL DEFAULT NULL COMMENT '该天该包可被关联上的渠道商ID' ,
`buss_fencheng_ratio`  decimal(5,4) NULL DEFAULT 0.0000 COMMENT '该天该包可被关联上的渠道商的分成比，对应channel_business里的tax' ,
`buss_real_tax`  bigint(20) NULL DEFAULT 0 COMMENT '该天该报未扣量时应得的税收，单位是金币' ,
`buss_get_tax`  bigint(20) NULL DEFAULT 0 COMMENT '该天该包渠道商可得的税收,单位是金币' ,
`we_get_tax`  bigint(20) NULL DEFAULT 0 COMMENT '该天该包平台可得的税收，单位是金币' ,
`bag_game_info`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '该天该包未扣量的游戏税收及输赢详情(单位是元)' ,
`bag_game_info_kled`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '该天该包已扣量的游戏税收及输赢详情(单位是元)' ,
PRIMARY KEY (`day`, `bag_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_bag_tax
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_fish_rank
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_fish_rank`;
CREATE TABLE `wz_day_fish_rank` (
`day`  date NOT NULL COMMENT '日期' ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`wincore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家赢得的分数,单位分' ,
`losecore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家发炮的分数，单位分' ,
`dead`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家打死几条鱼' ,
`shoot`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家发炮次数' ,
`core`  int(11) NOT NULL DEFAULT 0 COMMENT '该日玩家最终输赢分数' ,
PRIMARY KEY (`day`, `guid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_fish_rank
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_fish_tj
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_fish_tj`;
CREATE TABLE `wz_day_fish_tj` (
`day`  date NOT NULL COMMENT '日期' ,
`fid`  int(11) NOT NULL COMMENT '鱼类ID' ,
`room_id`  int(11) NOT NULL COMMENT '房间ID' ,
`bs`  int(11) NOT NULL COMMENT '该鱼倍数' ,
`wincore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼赢得的分数,单位分' ,
`losecore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼输掉的分数，单位分' ,
`dead`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼死亡次数' ,
`shoot`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼被击中的次数' ,
`core`  int(11) NOT NULL DEFAULT 0 COMMENT '该日鱼最终输赢分数' ,
PRIMARY KEY (`day`, `fid`, `room_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_fish_tj
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_game_room
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_game_room`;
CREATE TABLE `wz_day_game_room` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(该表记录每天每个游戏ID内的次数输赢等)' ,
`game_id`  int(11) NOT NULL COMMENT '游戏ID，与 config.t_game_server_cfg 中的game_id对应' ,
`play_people`  int(11) NULL DEFAULT 0 COMMENT '游戏人数' ,
`play_group`  int(11) NULL DEFAULT 0 COMMENT '游戏局数' ,
`play_person_time`  int(11) NULL DEFAULT 0 COMMENT '游戏人次（比如一局斗地主有3人次）' ,
`play_person_time_win`  int(11) NULL DEFAULT 0 COMMENT '赢局人次（比如斗地主农民赢了，就是赢2人次输1人次）' ,
`play_person_time_lose`  int(11) NULL DEFAULT 0 COMMENT '输局人次（比如斗地主农民赢了，就是赢2人次输1人次）' ,
`rmb_tax`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '税收，单位元' ,
`rmb_add`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '加钱（税收+加钱=玩家赢的钱），单位元' ,
`rmb_lose`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '减钱（玩家输的钱），单位元' ,
PRIMARY KEY (`day`, `game_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_game_room
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_game_room_plats
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_game_room_plats`;
CREATE TABLE `wz_day_game_room_plats` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(该表记录每天每个游戏ID内的次数输赢等)' ,
`plat_id`  int(11) NOT NULL COMMENT '分发平台Id' ,
`game_id`  int(11) NOT NULL COMMENT '游戏ID，与 config.t_game_server_cfg 中的game_id对应' ,
`play_people`  int(11) NULL DEFAULT 0 COMMENT '游戏人数' ,
`play_group`  int(11) NULL DEFAULT 0 COMMENT '游戏局数' ,
`play_person_time`  int(11) NULL DEFAULT 0 COMMENT '游戏人次（比如一局斗地主有3人次）' ,
`play_person_time_win`  int(11) NULL DEFAULT 0 COMMENT '赢局人次（比如斗地主农民赢了，就是赢2人次输1人次）' ,
`play_person_time_lose`  int(11) NULL DEFAULT 0 COMMENT '输局人次（比如斗地主农民赢了，就是赢2人次输1人次）' ,
`rmb_tax`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '税收，单位元' ,
`rmb_add`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '加钱（税收+加钱=玩家赢的钱），单位元' ,
`rmb_lose`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '减钱（玩家输的钱），单位元' ,
PRIMARY KEY (`day`, `plat_id`, `game_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_game_room_plats
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_game_time
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_game_time`;
CREATE TABLE `wz_day_game_time` (
`day`  date NOT NULL ,
`type`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '游戏类型，land、ox、等' ,
`play_turn_count`  int(11) UNSIGNED NOT NULL COMMENT '游戏局数' ,
`play_cost_time`  int(11) UNSIGNED NOT NULL COMMENT '游戏耗时' ,
`play_cost_time_avg`  decimal(16,2) NOT NULL COMMENT '游戏耗时均值' ,
PRIMARY KEY (`day`, `type`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_game_time
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_jcfish_rank
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_jcfish_rank`;
CREATE TABLE `wz_day_jcfish_rank` (
`day`  date NOT NULL COMMENT '日期' ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
`wincore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家赢得的分数,单位分' ,
`losecore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家发炮的分数，单位分' ,
`dead`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家打死几条鱼' ,
`shoot`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该玩家发炮次数' ,
`core`  int(11) NOT NULL DEFAULT 0 COMMENT '该日玩家最终输赢分数' ,
PRIMARY KEY (`day`, `guid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_jcfish_rank
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_jcfish_tj
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_jcfish_tj`;
CREATE TABLE `wz_day_jcfish_tj` (
`day`  date NOT NULL COMMENT '日期' ,
`fid`  int(11) NOT NULL COMMENT '鱼类ID' ,
`room_id`  int(11) NOT NULL COMMENT '房间ID' ,
`bs`  int(11) NOT NULL COMMENT '该鱼倍数' ,
`wincore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼赢得的分数,单位分' ,
`losecore`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼输掉的分数，单位分' ,
`dead`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼死亡次数' ,
`shoot`  int(11) NOT NULL DEFAULT 0 COMMENT '该日该鱼被击中的次数' ,
`core`  int(11) NOT NULL DEFAULT 0 COMMENT '该日鱼最终输赢分数' ,
PRIMARY KEY (`day`, `fid`, `room_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_jcfish_tj
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_player_yingshou
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_player_yingshou`;
CREATE TABLE `wz_day_player_yingshou` (
`day`  date NOT NULL ,
`guid`  int(11) NOT NULL ,
`plat_id`  int(11) NOT NULL COMMENT '分发平台ID' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID' ,
`recharge`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '该日充值总额，单位元' ,
`recharge_online`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '该日在线充值总额，单位元' ,
`recharge_daili`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '该日代理充值总额，单位元' ,
`cash`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '该日兑换总额，单位元' ,
`yingshou`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '该日营收总额，单位元' ,
PRIMARY KEY (`day`, `guid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_player_yingshou
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_day_redblack_tj
-- ----------------------------
DROP TABLE IF EXISTS `wz_day_redblack_tj`;
CREATE TABLE `wz_day_redblack_tj` (
`day`  date NOT NULL COMMENT '日期' ,
`room`  tinyint(10) NOT NULL COMMENT '房间' ,
`color`  tinyint(10) NOT NULL COMMENT '下注区域' ,
`pl`  tinyint(10) NOT NULL COMMENT '赔率' ,
`winlv`  int(11) NULL DEFAULT 0 COMMENT '胜率(该区开出几率)' ,
`mannum`  int(11) NULL DEFAULT 0 COMMENT '下注人数' ,
`totalmoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '下注总额' 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_day_redblack_tj
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_game_online_dots
-- ----------------------------
DROP TABLE IF EXISTS `wz_game_online_dots`;
CREATE TABLE `wz_game_online_dots` (
`time`  int(11) NOT NULL COMMENT '时间点' ,
`first_game_type`  int(11) NOT NULL COMMENT '5斗地主 6炸金花 8百人牛牛' ,
`second_game_type`  int(11) NOT NULL COMMENT '1新手场 2初级场 3 高级场 4富豪场' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID' ,
`online`  int(11) NULL DEFAULT 0 COMMENT '在线人数' ,
PRIMARY KEY (`time`, `first_game_type`, `second_game_type`, `plat_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_game_online_dots
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_game_online_dots_phone
-- ----------------------------
DROP TABLE IF EXISTS `wz_game_online_dots_phone`;
CREATE TABLE `wz_game_online_dots_phone` (
`time`  int(11) NOT NULL COMMENT '(该表是对 wz_game_online_dots 的补充，针对区分手机类型的在线人数查看)' ,
`plat_id`  int(11) NOT NULL COMMENT '分发平台ID' ,
`total`  int(11) NOT NULL DEFAULT 0 COMMENT '总在线' ,
`ios`  int(11) NOT NULL DEFAULT 0 COMMENT 'ios在线' ,
`android`  int(11) NOT NULL DEFAULT 0 COMMENT 'android在线' ,
PRIMARY KEY (`time`, `plat_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_game_online_dots_phone
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_guid_bag_back
-- ----------------------------
DROP TABLE IF EXISTS `wz_guid_bag_back`;
CREATE TABLE `wz_guid_bag_back` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`back_1`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '次日回头率' ,
`back_3`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '三日回头率' ,
`back_7`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '七日回头率' ,
`back_15`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '十五日回头率' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户价值统计' ,
PRIMARY KEY (`day`, `bag_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_guid_bag_back
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_guid_bag_cash
-- ----------------------------
DROP TABLE IF EXISTS `wz_guid_bag_cash`;
CREATE TABLE `wz_guid_bag_cash` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`guid`  int(11) NOT NULL ,
`cash_times`  int(11) NOT NULL DEFAULT 0 ,
`cash_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换金额(元)' ,
`get_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '实得金额(元)' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 ,
PRIMARY KEY (`day`, `guid`),
INDEX `idx_guid_day` (`guid`, `day`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_guid_bag_cash
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_guid_bag_create
-- ----------------------------
DROP TABLE IF EXISTS `wz_guid_bag_create`;
CREATE TABLE `wz_guid_bag_create` (
`guid`  int(11) NOT NULL COMMENT '该表是玩家创建日期记录' ,
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '日期' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '渠道包ID' ,
`plat_id`  int(11) NULL DEFAULT 0 COMMENT '分发平台ID' ,
PRIMARY KEY (`guid`),
INDEX `idx_day` (`day`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_guid_bag_create
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_guid_bag_login
-- ----------------------------
DROP TABLE IF EXISTS `wz_guid_bag_login`;
CREATE TABLE `wz_guid_bag_login` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(该表是每天每包玩家登陆记录)' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '渠道包ID' ,
`guid`  int(11) NOT NULL COMMENT '玩家ID' ,
PRIMARY KEY (`day`, `bag_id`, `guid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_guid_bag_login
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_guid_bag_play
-- ----------------------------
DROP TABLE IF EXISTS `wz_guid_bag_play`;
CREATE TABLE `wz_guid_bag_play` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`guid`  int(11) NOT NULL ,
`game_name`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '游戏名(同log.t_log_money_tj中的game_name)' ,
`play_count`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '该玩家总游戏局数' ,
`total_time`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '该玩家总游戏时长' ,
`total_tax`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '该玩家总游戏税收' ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' ,
`plat_id`  int(11) NULL DEFAULT 0 ,
PRIMARY KEY (`day`, `guid`, `game_name`),
INDEX `idx_guid_day` (`guid`, `day`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_guid_bag_play
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_guid_bag_recharge
-- ----------------------------
DROP TABLE IF EXISTS `wz_guid_bag_recharge`;
CREATE TABLE `wz_guid_bag_recharge` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`guid`  int(11) NOT NULL ,
`pay_times`  int(11) NOT NULL DEFAULT 0 ,
`pay_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 ,
`act_rmb`  decimal(16,2) NOT NULL DEFAULT 0.00 ,
`bag_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' ,
`plat_id`  int(111) NOT NULL DEFAULT 0 ,
PRIMARY KEY (`day`, `guid`),
INDEX `idx_guid` (`guid`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_guid_bag_recharge
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_kvs_data_cache
-- ----------------------------
DROP TABLE IF EXISTS `wz_kvs_data_cache`;
CREATE TABLE `wz_kvs_data_cache` (
`key`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`value`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '暂存的部分机器人最新消息' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`key`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_kvs_data_cache
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_player_group_dizhu
-- ----------------------------
DROP TABLE IF EXISTS `wz_player_group_dizhu`;
CREATE TABLE `wz_player_group_dizhu` (
`day`  date NOT NULL COMMENT '(该表查询玩家对局信息)' ,
`guid_a`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID，较小' ,
`guid_b`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID，较大' ,
`times`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '两人的对局次数' ,
`win_a`  decimal(16,2) NULL DEFAULT 0.00 ,
`win_b`  decimal(16,2) NULL DEFAULT 0.00 ,
PRIMARY KEY (`day`, `guid_a`, `guid_b`),
INDEX `idx_day_times` (`day`, `times`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_player_group_dizhu
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_player_group_jinhua
-- ----------------------------
DROP TABLE IF EXISTS `wz_player_group_jinhua`;
CREATE TABLE `wz_player_group_jinhua` (
`day`  date NOT NULL COMMENT '(该表查询玩家对局信息)' ,
`guid_a`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID，较小' ,
`guid_b`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID，较大' ,
`times`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '两人的对局次数' ,
`win_a`  decimal(16,2) NULL DEFAULT 0.00 ,
`win_b`  decimal(16,2) NULL DEFAULT 0.00 ,
PRIMARY KEY (`day`, `guid_a`, `guid_b`),
INDEX `idx_day_times` (`day`, `times`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_player_group_jinhua
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_player_group_suoha
-- ----------------------------
DROP TABLE IF EXISTS `wz_player_group_suoha`;
CREATE TABLE `wz_player_group_suoha` (
`day`  date NOT NULL COMMENT '(该表查询玩家对局信息)' ,
`guid_a`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID，较小' ,
`guid_b`  int(11) UNSIGNED NOT NULL COMMENT '玩家ID，较大' ,
`times`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '两人的对局次数' ,
`win_a`  decimal(16,2) NULL DEFAULT 0.00 ,
`win_b`  decimal(16,2) NULL DEFAULT 0.00 ,
PRIMARY KEY (`day`, `guid_a`, `guid_b`),
INDEX `idx_day_times` (`day`, `times`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_player_group_suoha
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_player_group_white
-- ----------------------------
DROP TABLE IF EXISTS `wz_player_group_white`;
CREATE TABLE `wz_player_group_white` (
`guid`  int(11) NOT NULL ,
`desc`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '备注' ,
`user`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`guid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_player_group_white
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_product_plat
-- ----------------------------
DROP TABLE IF EXISTS `wz_product_plat`;
CREATE TABLE `wz_product_plat` (
`day`  date NOT NULL COMMENT '(该表执行对象是ProductTotalDatasForCall,数据每10分钟会发布到potato上)' ,
`plat_id`  int(11) NOT NULL COMMENT '分发平台ID' ,
`countRegister`  int(11) NULL DEFAULT 0 COMMENT '该日注册人数' ,
`countBindPhone`  int(11) NULL DEFAULT 0 COMMENT '该日注册绑定手机人数' ,
`bind_count`  int(11) NULL DEFAULT 0 COMMENT '该日绑定手机总人数' ,
`countBindAlipay`  int(11) NULL DEFAULT 0 COMMENT '该日绑定支付宝人数' ,
`rechargeTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日下单人数' ,
`rechargePaidRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '该日充值订单付账百分比' ,
`rechargeTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日下单总笔数' ,
`ratioNewPayUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '新充值人数/注册人数 百分比例' ,
`ratioBindUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '绑定人数/注册人数 百分比例' ,
`ratioNewPayUser2BindUser`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '绑定人数/新充值人数 百分比例' ,
`reg_ip_count`  int(11) NULL DEFAULT 0 COMMENT '该日新进入IP（以注册IP计）' ,
`rechargeWillBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日预计充值金额，单位元，两位小数' ,
`rechargeHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '总计充值金额，单位元' ,
`pay_new_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_total_money_1`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '在线充值金额，单位元' ,
`pay_new_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`agentOutMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理充值金额，单位元' ,
`pay_new_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`rechargePaidPeople`  int(11) NULL DEFAULT 0 COMMENT '总计充值人数' ,
`pay_new_user_people`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people`  int(11) NULL DEFAULT 0 ,
`pay_total_people_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值人数' ,
`pay_new_user_people_1`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_1`  int(11) NULL DEFAULT 0 ,
`agentOutPeople`  int(11) NULL DEFAULT 0 COMMENT '代理充值人数' ,
`pay_new_user_people_2`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_2`  int(11) NULL DEFAULT 0 ,
`rechargePaidTimes`  int(11) NULL DEFAULT 0 COMMENT '总计充值笔数' ,
`pay_total_times_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值笔数' ,
`agentOutTimes`  int(11) NULL DEFAULT 0 COMMENT '代理充值笔数' ,
`rechargePeopleAvg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPPU（该日充值玩家的人均充值金额），单位元，两位小数' ,
`pay_arpu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPU（日总充值/日登录用户数），单位元，两位小数' ,
`rechargeRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '付费率（充值人数/登陆人数）' ,
`agentPayMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理支付金额，单位元' ,
`agentGetMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理进货金额，单位元' ,
`agentGetPeople`  int(11) NULL DEFAULT 0 COMMENT '代理进货人数' ,
`agentGetTimes`  int(11) NULL DEFAULT 0 COMMENT '代理进货次数' ,
`agentCurMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理余币，单位元' ,
`cashHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日提现金额，单位元' ,
`cashTotalTax`  int(11) NULL DEFAULT 0 COMMENT '该日兑换税费，单位元' ,
`cashTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日提现人数' ,
`cashTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日提现次数' ,
`taxHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日税收总额，单位元，两位小数' ,
`taxDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日斗地主税收总额，单位元，两位小数' ,
`taxJinHua`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日扎金花税收总额，单位元，两位小数' ,
`taxNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日百人牛牛税收总额，单位元，两位小数' ,
`taxLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日老虎机税收总额，单位元，两位小数' ,
`taxSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日梭哈税收总额，单位元，两位小数' ,
`taxQiangZhuang`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日抢庄牛牛税收总额，单位元，两位小数' ,
`taxJingDian66`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日经典牛牛税收总额，单位元，两位小数' ,
`taxMSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日多人梭哈税收总额，单位元，两位小数' ,
`taxFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日李逵捕鱼税收总额，单位元' ,
`taxJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日金蟾捕鱼税收总额，单位元' ,
`taxRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日红黑大战税收总额，单位元' ,
`tax3Shui`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日十三张(十三水)税收总额，单位元' ,
`taxShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日骰宝税收总额，单位元' ,
`taxTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日21点税收总额, 单位元' ,
`taxToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日龙虎斗税收总额, 单位元' ,
`taxFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日五星宏辉税收总额, 单位元' ,
`playPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日全部类型游戏活跃人数' ,
`playPeopleDiZhu`  int(11) NULL DEFAULT 0 COMMENT '该日斗地主活跃人数' ,
`playPeopleJinHua`  int(11) NULL DEFAULT 0 COMMENT '该日扎金花活跃人数' ,
`playPeopleNiuNiu`  int(11) NULL DEFAULT 0 COMMENT '该日百人牛牛活跃人数' ,
`playPeopleLaoHu`  int(11) NULL DEFAULT 0 COMMENT '该日老虎机活跃人数' ,
`playPeopleSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日梭哈活跃人数' ,
`playPeopleQiangZhuang`  int(11) NULL DEFAULT 0 COMMENT '该日抢庄牛牛活跃人数' ,
`playPeopleJingDian66`  int(11) NULL DEFAULT 0 COMMENT '该日经典牛牛活跃人数' ,
`playPeopleMSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日多人梭哈活跃人数' ,
`playPeopleFish`  int(11) NULL DEFAULT 0 COMMENT '该日李逵捕鱼活跃人数' ,
`playPeopleJcFish`  int(11) NULL DEFAULT 0 COMMENT '该日金蟾捕鱼活跃人数' ,
`playPeopleRed`  int(11) NULL DEFAULT 0 COMMENT '该日红黑大战活跃人数' ,
`playPeople3Shui`  int(11) NULL DEFAULT 0 COMMENT '该日十三张(十三水)活跃人数' ,
`playPeopleShaiZi`  int(11) NULL DEFAULT 0 COMMENT '该日骰宝活跃人数' ,
`playPeopleTwentyone`  int(11) NULL DEFAULT 0 COMMENT '该日21点活跃人数' ,
`playPeopleToradora`  int(11) NULL DEFAULT 0 COMMENT '该日龙虎斗活跃人数' ,
`playPeopleFivestar`  int(11) NULL DEFAULT 0 COMMENT '该日五星宏辉活跃人数' ,
`sys_100_is_banker_count`  int(11) NULL DEFAULT 0 COMMENT '牛牛系统当庄次数' ,
`sysWinLoseNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '牛牛系统输赢' ,
`sysWinLoseLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '老虎机系统输赢' ,
`sysWinLoseFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '李逵捕鱼系统输赢' ,
`sysWinLoseJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '金蟾捕鱼系统输赢' ,
`sysWinLoseRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '红黑大战系统输赢' ,
`sysWinLoseShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '骰宝系统输赢' ,
`sysWinLoseTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '21点系统输赢' ,
`sysWinLoseToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '龙虎斗系统输赢' ,
`sysWinLoseFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '五星宏辉系统输赢' ,
`sysWinLoseDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '斗地主系统输赢' ,
`loginPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日登陆人数' ,
`loginPeopleFormat`  int(11) NULL DEFAULT 0 COMMENT '该日登陆正式用户' ,
`loginPeopleIos`  int(11) NULL DEFAULT 0 COMMENT '该日IOS登陆人数' ,
`loginPeopleAndroid`  int(11) NULL DEFAULT 0 COMMENT '该日Android登陆人数' ,
`yunPianBalance`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '更新云片短信余额，单位元' ,
`back_1`  float(5,2) NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_2`  float(5,2) NULL DEFAULT 0.00 COMMENT '2日回头率' ,
`back_3`  float(5,2) NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_4`  float(5,2) NULL DEFAULT 0.00 COMMENT '4日回头率' ,
`back_5`  float(5,2) NULL DEFAULT 0.00 COMMENT '5日回头率' ,
`back_6`  float(5,2) NULL DEFAULT 0.00 COMMENT '6日回头率' ,
`back_7`  float(5,2) NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_8`  float(5,2) NULL DEFAULT 0.00 COMMENT '8日回头率' ,
`back_9`  float(5,2) NULL DEFAULT 0.00 COMMENT '9日回头率' ,
`back_10`  float(5,2) NULL DEFAULT 0.00 COMMENT '10日回头率' ,
`back_15`  float(5,2) NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户价值' ,
`gongxian_avg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '人均贡献' ,
`yingshou_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收' ,
`yingshou_ratio`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收比(因为可能测试数据直接加钱，所以允许大于100%)' ,
PRIMARY KEY (`day`, `plat_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_product_plat
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_product_plat_log
-- ----------------------------
DROP TABLE IF EXISTS `wz_product_plat_log`;
CREATE TABLE `wz_product_plat_log` (
`timestamp`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(该表执行对象是ProductTotalDatasForCall,数据每10分钟会发布到potato上)' ,
`plat_id`  int(11) NOT NULL COMMENT '分发平台ID' ,
`countRegister`  int(11) NULL DEFAULT 0 COMMENT '该日注册人数' ,
`countBindPhone`  int(11) NULL DEFAULT 0 COMMENT '该日注册绑定手机人数' ,
`bind_count`  int(11) NULL DEFAULT 0 COMMENT '该日绑定手机总人数' ,
`countBindAlipay`  int(11) NULL DEFAULT 0 COMMENT '该日绑定支付宝人数' ,
`rechargeTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日下单人数' ,
`rechargePaidRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '该日充值订单付账百分比' ,
`rechargeTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日下单总笔数' ,
`ratioNewPayUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '新充值人数/注册人数 百分比例' ,
`ratioBindUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '绑定人数/注册人数 百分比例' ,
`ratioNewPayUser2BindUser`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '绑定人数/新充值人数 百分比例' ,
`reg_ip_count`  int(11) NULL DEFAULT 0 COMMENT '该日新进入IP（以注册IP计）' ,
`rechargeWillBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日预计充值金额，单位元，两位小数' ,
`rechargeHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '总计充值金额，单位元' ,
`pay_new_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_total_money_1`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '在线充值金额，单位元' ,
`pay_new_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`agentOutMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理充值金额，单位元' ,
`pay_new_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`rechargePaidPeople`  int(11) NULL DEFAULT 0 COMMENT '总计充值人数' ,
`pay_new_user_people`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people`  int(11) NULL DEFAULT 0 ,
`pay_total_people_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值人数' ,
`pay_new_user_people_1`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_1`  int(11) NULL DEFAULT 0 ,
`agentOutPeople`  int(11) NULL DEFAULT 0 COMMENT '代理充值人数' ,
`pay_new_user_people_2`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_2`  int(11) NULL DEFAULT 0 ,
`rechargePaidTimes`  int(11) NULL DEFAULT 0 COMMENT '总计充值笔数' ,
`pay_total_times_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值笔数' ,
`agentOutTimes`  int(11) NULL DEFAULT 0 COMMENT '代理充值笔数' ,
`rechargePeopleAvg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPPU（该日充值玩家的人均充值金额），单位元，两位小数' ,
`pay_arpu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPU（日总充值/日登录用户数），单位元，两位小数' ,
`rechargeRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '付费率（充值人数/登陆人数）' ,
`agentPayMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理支付金额，单位元' ,
`agentGetMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理进货金额，单位元' ,
`agentGetPeople`  int(11) NULL DEFAULT 0 COMMENT '代理进货人数' ,
`agentGetTimes`  int(11) NULL DEFAULT 0 COMMENT '代理进货次数' ,
`agentCurMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理余币，单位元' ,
`cashHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日提现金额，单位元' ,
`cashTotalTax`  int(11) NULL DEFAULT 0 COMMENT '该日兑换税费，单位元' ,
`cashTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日提现人数' ,
`cashTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日提现次数' ,
`taxHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日税收总额，单位元，两位小数' ,
`taxDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日斗地主税收总额，单位元，两位小数' ,
`taxJinHua`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日扎金花税收总额，单位元，两位小数' ,
`taxNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日百人牛牛税收总额，单位元，两位小数' ,
`taxLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日老虎机税收总额，单位元，两位小数' ,
`taxSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日梭哈税收总额，单位元，两位小数' ,
`taxQiangZhuang`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日抢庄牛牛税收总额，单位元，两位小数' ,
`taxJingDian66`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日经典牛牛税收总额，单位元，两位小数' ,
`taxMSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日多人梭哈税收总额，单位元，两位小数' ,
`taxFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日李逵捕鱼税收总额，单位元' ,
`taxJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日金蟾捕鱼税收总额，单位元' ,
`taxRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日红黑大战税收总额，单位元' ,
`tax3Shui`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日十三张(十三水)税收总额，单位元' ,
`taxShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日骰宝税收总额，单位元' ,
`taxTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日21点税收总额, 单位元' ,
`taxToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日龙虎斗税收总额, 单位元' ,
`taxFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日五星宏辉税收总额, 单位元' ,
`playPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日全部类型游戏活跃人数' ,
`playPeopleDiZhu`  int(11) NULL DEFAULT 0 COMMENT '该日斗地主活跃人数' ,
`playPeopleJinHua`  int(11) NULL DEFAULT 0 COMMENT '该日扎金花活跃人数' ,
`playPeopleNiuNiu`  int(11) NULL DEFAULT 0 COMMENT '该日百人牛牛活跃人数' ,
`playPeopleLaoHu`  int(11) NULL DEFAULT 0 COMMENT '该日老虎机活跃人数' ,
`playPeopleSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日梭哈活跃人数' ,
`playPeopleQiangZhuang`  int(11) NULL DEFAULT 0 COMMENT '该日抢庄牛牛活跃人数' ,
`playPeopleJingDian66`  int(11) NULL DEFAULT 0 COMMENT '该日经典牛牛活跃人数' ,
`playPeopleMSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日多人梭哈活跃人数' ,
`playPeopleFish`  int(11) NULL DEFAULT 0 COMMENT '该日李逵捕鱼活跃人数' ,
`playPeopleJcFish`  int(11) NULL DEFAULT 0 COMMENT '该日金蟾捕鱼活跃人数' ,
`playPeopleRed`  int(11) NULL DEFAULT 0 COMMENT '该日红黑大战活跃人数' ,
`playPeople3Shui`  int(11) NULL DEFAULT 0 COMMENT '该日十三张(十三水)活跃人数' ,
`playPeopleShaiZi`  int(11) NULL DEFAULT 0 COMMENT '该日骰宝活跃人数' ,
`playPeopleTwentyone`  int(11) NULL DEFAULT 0 COMMENT '该日21点活跃人数' ,
`playPeopleToradora`  int(11) NULL DEFAULT 0 COMMENT '该日龙虎斗活跃人数' ,
`playPeopleFivestar`  int(11) NULL DEFAULT 0 COMMENT '该日五星宏辉活跃人数' ,
`sys_100_is_banker_count`  int(11) NULL DEFAULT 0 COMMENT '牛牛系统当庄次数' ,
`sysWinLoseNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '牛牛系统输赢' ,
`sysWinLoseLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '老虎机系统输赢' ,
`sysWinLoseFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '李逵捕鱼系统输赢' ,
`sysWinLoseJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '金蟾捕鱼系统输赢' ,
`sysWinLoseRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '红黑大战系统输赢' ,
`sysWinLoseShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '骰宝系统输赢' ,
`sysWinLoseTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '21点系统输赢' ,
`sysWinLoseToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '龙虎斗系统输赢' ,
`sysWinLoseFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '五星宏辉系统输赢' ,
`sysWinLoseDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '斗地主系统输赢' ,
`loginPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日登陆人数' ,
`loginPeopleFormat`  int(11) NULL DEFAULT 0 COMMENT '该日登陆正式用户' ,
`loginPeopleIos`  int(11) NULL DEFAULT 0 COMMENT '该日IOS登陆人数' ,
`loginPeopleAndroid`  int(11) NULL DEFAULT 0 COMMENT '该日Android登陆人数' ,
`yunPianBalance`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '更新云片短信余额，单位元' ,
`back_1`  float(5,2) NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_2`  float(5,2) NULL DEFAULT 0.00 COMMENT '2日回头率' ,
`back_3`  float(5,2) NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_4`  float(5,2) NULL DEFAULT 0.00 COMMENT '4日回头率' ,
`back_5`  float(5,2) NULL DEFAULT 0.00 COMMENT '5日回头率' ,
`back_6`  float(5,2) NULL DEFAULT 0.00 COMMENT '6日回头率' ,
`back_7`  float(5,2) NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_8`  float(5,2) NULL DEFAULT 0.00 COMMENT '8日回头率' ,
`back_9`  float(5,2) NULL DEFAULT 0.00 COMMENT '9日回头率' ,
`back_10`  float(5,2) NULL DEFAULT 0.00 COMMENT '10日回头率' ,
`back_15`  float(5,2) NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户价值' ,
`gongxian_avg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '人均贡献' ,
`yingshou_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收' ,
`yingshou_ratio`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收比(因为可能测试数据直接加钱，所以允许大于100%)' ,
PRIMARY KEY (`timestamp`, `plat_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_product_plat_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_product_total
-- ----------------------------
DROP TABLE IF EXISTS `wz_product_total`;
CREATE TABLE `wz_product_total` (
`day`  date NOT NULL COMMENT '(该表执行对象是ProductTotalDatasForCall,数据每10分钟会发布到potato上)' ,
`countRegister`  int(11) NULL DEFAULT 0 COMMENT '该日注册人数' ,
`countBindPhone`  int(11) NULL DEFAULT 0 COMMENT '该日注册绑定手机人数' ,
`bind_count`  int(11) NULL DEFAULT 0 COMMENT '该日绑定手机总人数' ,
`countBindAlipay`  int(11) NULL DEFAULT 0 COMMENT '该日绑定支付宝人数' ,
`rechargeTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日下单人数' ,
`rechargePaidRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '该日充值订单付账百分比' ,
`rechargeTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日下单总笔数' ,
`ratioNewPayUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '新充值人数/注册人数 百分比例' ,
`ratioBindUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '绑定人数/注册人数 百分比例' ,
`ratioNewPayUser2BindUser`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '绑定人数/新充值人数 百分比例' ,
`reg_ip_count`  int(11) NULL DEFAULT 0 COMMENT '该日新进入IP（以注册IP计）' ,
`rechargeWillBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日预计充值金额，单位元，两位小数' ,
`rechargeHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '总计充值金额，单位元' ,
`pay_new_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_total_money_1`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '在线充值金额，单位元' ,
`pay_new_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`agentOutMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理充值金额，单位元' ,
`pay_new_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`rechargePaidPeople`  int(11) NULL DEFAULT 0 COMMENT '总计充值人数' ,
`pay_new_user_people`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people`  int(11) NULL DEFAULT 0 ,
`pay_total_people_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值人数' ,
`pay_new_user_people_1`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_1`  int(11) NULL DEFAULT 0 ,
`agentOutPeople`  int(11) NULL DEFAULT 0 COMMENT '代理充值人数' ,
`pay_new_user_people_2`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_2`  int(11) NULL DEFAULT 0 ,
`rechargePaidTimes`  int(11) NULL DEFAULT 0 COMMENT '总计充值笔数' ,
`pay_total_times_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值笔数' ,
`agentOutTimes`  int(11) NULL DEFAULT 0 COMMENT '代理充值笔数' ,
`rechargePeopleAvg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPPU（该日充值玩家的人均充值金额），单位元，两位小数' ,
`pay_arpu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPU（日总充值/日登录用户数），单位元，两位小数' ,
`rechargeRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '付费率（充值人数/登陆人数）' ,
`agentPayMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理支付金额，单位元' ,
`agentGetMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理进货金额，单位元' ,
`agentGetPeople`  int(11) NULL DEFAULT 0 COMMENT '代理进货人数' ,
`agentGetTimes`  int(11) NULL DEFAULT 0 COMMENT '代理进货次数' ,
`agentCurMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理余币，单位元' ,
`cashHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日提现金额，单位元' ,
`cashTotalTax`  int(11) NULL DEFAULT 0 COMMENT '该日兑换税费，单位元' ,
`cashTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日提现人数' ,
`cashTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日提现次数' ,
`taxHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日税收总额，单位元，两位小数' ,
`taxDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日斗地主税收总额，单位元，两位小数' ,
`taxJinHua`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日扎金花税收总额，单位元，两位小数' ,
`taxNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日百人牛牛税收总额，单位元，两位小数' ,
`taxLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日老虎机税收总额，单位元，两位小数' ,
`taxSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日梭哈税收总额，单位元，两位小数' ,
`taxQiangZhuang`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日抢庄牛牛税收总额，单位元，两位小数' ,
`taxJingDian66`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日经典牛牛税收总额，单位元，两位小数' ,
`taxMSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日多人梭哈税收总额，单位元，两位小数' ,
`taxFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日李逵捕鱼税收总额，单位元' ,
`taxJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日金蟾捕鱼税收总额，单位元' ,
`taxRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日红黑大战税收总额，单位元' ,
`tax3Shui`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日十三张(十三水)税收总额，单位元' ,
`taxShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日骰宝税收总额，单位元' ,
`taxTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日21点税收总额, 单位元' ,
`taxToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日龙虎斗税收总额, 单位元' ,
`taxFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日五星宏辉税收总额, 单位元' ,
`playPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日全部类型游戏活跃人数' ,
`playPeopleDiZhu`  int(11) NULL DEFAULT 0 COMMENT '该日斗地主活跃人数' ,
`playPeopleJinHua`  int(11) NULL DEFAULT 0 COMMENT '该日扎金花活跃人数' ,
`playPeopleNiuNiu`  int(11) NULL DEFAULT 0 COMMENT '该日百人牛牛活跃人数' ,
`playPeopleLaoHu`  int(11) NULL DEFAULT 0 COMMENT '该日老虎机活跃人数' ,
`playPeopleSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日梭哈活跃人数' ,
`playPeopleQiangZhuang`  int(11) NULL DEFAULT 0 COMMENT '该日抢庄牛牛活跃人数' ,
`playPeopleJingDian66`  int(11) NULL DEFAULT 0 COMMENT '该日经典牛牛活跃人数' ,
`playPeopleMSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日多人梭哈活跃人数' ,
`playPeopleFish`  int(11) NULL DEFAULT 0 COMMENT '该日李逵捕鱼活跃人数' ,
`playPeopleJcFish`  int(11) NULL DEFAULT 0 COMMENT '该日金蟾捕鱼活跃人数' ,
`playPeopleRed`  int(11) NULL DEFAULT 0 COMMENT '该日红黑大战活跃人数' ,
`playPeople3Shui`  int(11) NULL DEFAULT 0 COMMENT '该日十三张(十三水)活跃人数' ,
`playPeopleShaiZi`  int(11) NULL DEFAULT 0 COMMENT '该日骰宝活跃人数' ,
`playPeopleTwentyone`  int(11) NULL DEFAULT 0 COMMENT '该日21点活跃人数' ,
`playPeopleToradora`  int(11) NULL DEFAULT 0 COMMENT '该日龙虎斗活跃人数' ,
`playPeopleFivestar`  int(11) NULL DEFAULT 0 COMMENT '该日五星宏辉活跃人数' ,
`sys_100_is_banker_count`  int(11) NULL DEFAULT 0 COMMENT '牛牛系统当庄次数' ,
`sysWinLoseNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '牛牛系统输赢' ,
`sysWinLoseLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '老虎机系统输赢' ,
`sysWinLoseFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '李逵捕鱼系统输赢' ,
`sysWinLoseJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '金蟾捕鱼系统输赢' ,
`sysWinLoseRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '红黑大战系统输赢' ,
`sysWinLoseShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '骰宝系统输赢' ,
`sysWinLoseTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '21点系统输赢' ,
`sysWinLoseToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '龙虎斗系统输赢' ,
`sysWinLoseFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '五星宏辉系统输赢' ,
`sysWinLoseDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '斗地主系统输赢' ,
`loginPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日登陆人数' ,
`loginPeopleFormat`  int(11) NULL DEFAULT 0 COMMENT '该日登陆正式用户' ,
`loginPeopleIos`  int(11) NULL DEFAULT 0 COMMENT '该日IOS登陆人数' ,
`loginPeopleAndroid`  int(11) NULL DEFAULT 0 COMMENT '该日Android登陆人数' ,
`yunPianBalance`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '更新云片短信余额，单位元' ,
`back_1`  float(5,2) NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_2`  float(5,2) NULL DEFAULT 0.00 COMMENT '2日回头率' ,
`back_3`  float(5,2) NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_4`  float(5,2) NULL DEFAULT 0.00 COMMENT '4日回头率' ,
`back_5`  float(5,2) NULL DEFAULT 0.00 COMMENT '5日回头率' ,
`back_6`  float(5,2) NULL DEFAULT 0.00 COMMENT '6日回头率' ,
`back_7`  float(5,2) NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_8`  float(5,2) NULL DEFAULT 0.00 COMMENT '8日回头率' ,
`back_9`  float(5,2) NULL DEFAULT 0.00 COMMENT '9日回头率' ,
`back_10`  float(5,2) NULL DEFAULT 0.00 COMMENT '10日回头率' ,
`back_15`  float(5,2) NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户价值' ,
`gongxian_avg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '人均贡献' ,
`yingshou_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收' ,
`yingshou_ratio`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收比(因为可能测试数据直接加钱，所以允许大于100%)' ,
PRIMARY KEY (`day`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_product_total
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_product_total_log
-- ----------------------------
DROP TABLE IF EXISTS `wz_product_total_log`;
CREATE TABLE `wz_product_total_log` (
`timestamp`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(该表执行对象是ProductTotalDatasForCall,数据每10分钟会发布到potato上)' ,
`countRegister`  int(11) NULL DEFAULT 0 COMMENT '该日注册人数' ,
`countBindPhone`  int(11) NULL DEFAULT 0 COMMENT '该日注册绑定手机人数' ,
`bind_count`  int(11) NULL DEFAULT 0 COMMENT '该日绑定手机总人数' ,
`countBindAlipay`  int(11) NULL DEFAULT 0 COMMENT '该日绑定支付宝人数' ,
`rechargeTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日下单人数' ,
`rechargePaidRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '该日充值订单付账百分比' ,
`rechargeTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日下单总笔数' ,
`ratioNewPayUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '新充值人数/注册人数 百分比例' ,
`ratioBindUser2RegUser`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '绑定人数/注册人数 百分比例' ,
`ratioNewPayUser2BindUser`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '绑定人数/新充值人数 百分比例' ,
`reg_ip_count`  int(11) NULL DEFAULT 0 COMMENT '该日新进入IP（以注册IP计）' ,
`rechargeWillBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日预计充值金额，单位元，两位小数' ,
`rechargeHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '总计充值金额，单位元' ,
`pay_new_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_total_money_1`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '在线充值金额，单位元' ,
`pay_new_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_1`  decimal(16,2) NULL DEFAULT 0.00 ,
`agentOutMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理充值金额，单位元' ,
`pay_new_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`pay_old_user_money_2`  decimal(16,2) NULL DEFAULT 0.00 ,
`rechargePaidPeople`  int(11) NULL DEFAULT 0 COMMENT '总计充值人数' ,
`pay_new_user_people`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people`  int(11) NULL DEFAULT 0 ,
`pay_total_people_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值人数' ,
`pay_new_user_people_1`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_1`  int(11) NULL DEFAULT 0 ,
`agentOutPeople`  int(11) NULL DEFAULT 0 COMMENT '代理充值人数' ,
`pay_new_user_people_2`  int(11) NULL DEFAULT 0 ,
`pay_old_user_people_2`  int(11) NULL DEFAULT 0 ,
`rechargePaidTimes`  int(11) NULL DEFAULT 0 COMMENT '总计充值笔数' ,
`pay_total_times_1`  int(11) NULL DEFAULT 0 COMMENT '在线充值笔数' ,
`agentOutTimes`  int(11) NULL DEFAULT 0 COMMENT '代理充值笔数' ,
`rechargePeopleAvg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPPU（该日充值玩家的人均充值金额），单位元，两位小数' ,
`pay_arpu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '日ARPU（日总充值/日登录用户数），单位元，两位小数' ,
`rechargeRatio`  decimal(5,2) NULL DEFAULT 0.00 COMMENT '付费率（充值人数/登陆人数）' ,
`agentPayMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理支付金额，单位元' ,
`agentGetMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理进货金额，单位元' ,
`agentGetPeople`  int(11) NULL DEFAULT 0 COMMENT '代理进货人数' ,
`agentGetTimes`  int(11) NULL DEFAULT 0 COMMENT '代理进货次数' ,
`agentCurMoney`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理余币，单位元' ,
`cashHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日提现金额，单位元' ,
`cashTotalTax`  int(11) NULL DEFAULT 0 COMMENT '该日兑换税费，单位元' ,
`cashTotalPeople`  int(11) NULL DEFAULT 0 COMMENT '该日提现人数' ,
`cashTotalTimes`  int(11) NULL DEFAULT 0 COMMENT '该日提现次数' ,
`taxHadBe`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日税收总额，单位元，两位小数' ,
`taxDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日斗地主税收总额，单位元，两位小数' ,
`taxJinHua`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日扎金花税收总额，单位元，两位小数' ,
`taxNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日百人牛牛税收总额，单位元，两位小数' ,
`taxLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日老虎机税收总额，单位元，两位小数' ,
`taxSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日梭哈税收总额，单位元，两位小数' ,
`taxQiangZhuang`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日抢庄牛牛税收总额，单位元，两位小数' ,
`taxJingDian66`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日经典牛牛税收总额，单位元，两位小数' ,
`taxMSuoHa`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日多人梭哈税收总额，单位元，两位小数' ,
`taxFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日李逵捕鱼税收总额，单位元' ,
`taxJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日金蟾捕鱼税收总额，单位元' ,
`taxRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日红黑大战税收总额，单位元' ,
`tax3Shui`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日十三张(十三水)税收总额，单位元' ,
`taxShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日骰宝税收总额，单位元' ,
`taxTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日21点税收总额, 单位元' ,
`taxToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日龙虎斗税收总额, 单位元' ,
`taxFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '该日五星宏辉税收总额, 单位元' ,
`playPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日全部类型游戏活跃人数' ,
`playPeopleDiZhu`  int(11) NULL DEFAULT 0 COMMENT '该日斗地主活跃人数' ,
`playPeopleJinHua`  int(11) NULL DEFAULT 0 COMMENT '该日扎金花活跃人数' ,
`playPeopleNiuNiu`  int(11) NULL DEFAULT 0 COMMENT '该日百人牛牛活跃人数' ,
`playPeopleLaoHu`  int(11) NULL DEFAULT 0 COMMENT '该日老虎机活跃人数' ,
`playPeopleSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日梭哈活跃人数' ,
`playPeopleQiangZhuang`  int(11) NULL DEFAULT 0 COMMENT '该日抢庄牛牛活跃人数' ,
`playPeopleJingDian66`  int(11) NULL DEFAULT 0 COMMENT '该日经典牛牛活跃人数' ,
`playPeopleMSuoHa`  int(11) NULL DEFAULT 0 COMMENT '该日多人梭哈活跃人数' ,
`playPeopleFish`  int(11) NULL DEFAULT 0 COMMENT '该日李逵捕鱼活跃人数' ,
`playPeopleJcFish`  int(11) NULL DEFAULT 0 COMMENT '该日金蟾捕鱼活跃人数' ,
`playPeopleRed`  int(11) NULL DEFAULT 0 COMMENT '该日红黑大战活跃人数' ,
`playPeople3Shui`  int(11) NULL DEFAULT 0 COMMENT '该日十三张(十三水)活跃人数' ,
`playPeopleShaiZi`  int(11) NULL DEFAULT 0 COMMENT '该日骰宝活跃人数' ,
`playPeopleTwentyone`  int(11) NULL DEFAULT 0 COMMENT '该日21点活跃人数' ,
`playPeopleToradora`  int(11) NULL DEFAULT 0 COMMENT '该日龙虎斗活跃人数' ,
`playPeopleFivestar`  int(11) NULL DEFAULT 0 COMMENT '该日五星宏辉活跃人数' ,
`sys_100_is_banker_count`  int(11) NULL DEFAULT 0 COMMENT '牛牛系统当庄次数' ,
`sysWinLoseNiuNiu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '牛牛系统输赢' ,
`sysWinLoseLaoHu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '老虎机系统输赢' ,
`sysWinLoseFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '李逵捕鱼系统输赢' ,
`sysWinLoseJcFish`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '金蟾捕鱼系统输赢' ,
`sysWinLoseRed`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '红黑大战系统输赢' ,
`sysWinLoseShaiZi`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '骰宝系统输赢' ,
`sysWinLoseTwentyone`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '21点系统输赢' ,
`sysWinLoseToradora`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '龙虎斗系统输赢' ,
`sysWinLoseFivestar`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '五星宏辉系统输赢' ,
`sysWinLoseDiZhu`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '斗地主系统输赢' ,
`loginPeopleHadBe`  int(11) NULL DEFAULT 0 COMMENT '该日登陆人数' ,
`loginPeopleFormat`  int(11) NULL DEFAULT 0 COMMENT '该日登陆正式用户' ,
`loginPeopleIos`  int(11) NULL DEFAULT 0 COMMENT '该日IOS登陆人数' ,
`loginPeopleAndroid`  int(11) NULL DEFAULT 0 COMMENT '该日Android登陆人数' ,
`yunPianBalance`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '更新云片短信余额，单位元' ,
`back_1`  float(5,2) NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_2`  float(5,2) NULL DEFAULT 0.00 COMMENT '2日回头率' ,
`back_3`  float(5,2) NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_4`  float(5,2) NULL DEFAULT 0.00 COMMENT '4日回头率' ,
`back_5`  float(5,2) NULL DEFAULT 0.00 COMMENT '5日回头率' ,
`back_6`  float(5,2) NULL DEFAULT 0.00 COMMENT '6日回头率' ,
`back_7`  float(5,2) NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_8`  float(5,2) NULL DEFAULT 0.00 COMMENT '8日回头率' ,
`back_9`  float(5,2) NULL DEFAULT 0.00 COMMENT '9日回头率' ,
`back_10`  float(5,2) NULL DEFAULT 0.00 COMMENT '10日回头率' ,
`back_15`  float(5,2) NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户价值' ,
`gongxian_avg`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '人均贡献' ,
`yingshou_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收' ,
`yingshou_ratio`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '营收比(因为可能测试数据直接加钱，所以允许大于100%)' ,
PRIMARY KEY (`timestamp`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_product_total_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_proxy_day_order_sum
-- ----------------------------
DROP TABLE IF EXISTS `wz_proxy_day_order_sum`;
CREATE TABLE `wz_proxy_day_order_sum` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '(每日每个代理商下的数据)' ,
`proxy_guid`  int(11) NOT NULL COMMENT '代理商账号guid' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '平台ID' ,
`pay_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理商支付的钱，单位元' ,
`get_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理商获得的金币，单位元' ,
`get_times`  int(11) NULL DEFAULT 0 COMMENT '代理商来进货的次数' ,
`out_money`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '代理商卖出的金币，单位元' ,
`out_people`  int(11) NULL DEFAULT 0 COMMENT '代理商卖出的玩家人数' ,
`out_times`  int(11) NULL DEFAULT 0 COMMENT '代理商卖出的玩家人次' ,
PRIMARY KEY (`day`, `proxy_guid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_proxy_day_order_sum
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_recharge_channel_day
-- ----------------------------
DROP TABLE IF EXISTS `wz_recharge_channel_day`;
CREATE TABLE `wz_recharge_channel_day` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '该表是每天每充值渠道充值金额表' ,
`plat_id`  int(11) NOT NULL DEFAULT 0 COMMENT '分发平台ID' ,
`pay_channel_id`  int(11) NOT NULL COMMENT '充值渠道ID，和 recharge.t_recharge_channel 中的 id 对应，（0：未知充值渠道，1：苹果沙箱）' ,
`pay_total_rmb`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '充值总额，单位元' ,
`pay_react_rmb`  decimal(16,2) NULL DEFAULT 0.00 COMMENT '扣除充值渠道费用后的充值总额，单位元' ,
PRIMARY KEY (`day`, `plat_id`, `pay_channel_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_recharge_channel_day
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_sys_day_sheet
-- ----------------------------
DROP TABLE IF EXISTS `wz_sys_day_sheet`;
CREATE TABLE `wz_sys_day_sheet` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '日期（该表是系统报表每日数据）' ,
`jiesuan_flag`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '结算标识，代码以此识别该日是否被下一日做了结算' ,
`jiesuan_time`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '结算时间，代码以此标记该日被下一日结算时的时间' ,
`yingshou_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '营收总金额，单位元' ,
`yingshou_ch_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道营收，单位元，仅仅是渠道下的充值-兑换-分成' ,
`fencheng_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道分成，单位元' ,
`pay_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数' ,
`pay_total_people_1`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数(在线)' ,
`pay_total_people_2`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数(代理)' ,
`pay_new_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总人数' ,
`pay_new_user_people_1`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总人数(在线)' ,
`pay_new_user_people_2`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总人数(代理)' ,
`pay_old_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总人数' ,
`pay_old_user_people_1`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总人数(在线)' ,
`pay_old_user_people_2`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总人数(代理)' ,
`pay_total_times`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数' ,
`pay_total_times_1`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数(在线)' ,
`pay_total_times_2`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数(代理)' ,
`pay_new_user_times`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总次数' ,
`pay_new_user_times_1`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总次数(在线)' ,
`pay_new_user_times_2`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总次数(代理)' ,
`pay_old_user_times`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总次数' ,
`pay_old_user_times_1`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总次数(在线)' ,
`pay_old_user_times_2`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总次数(代理)' ,
`pay_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元' ,
`pay_total_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元(在线)' ,
`pay_total_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元(代理)' ,
`pay_new_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户充值金额，单位元' ,
`pay_new_user_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户充值金额，单位元(在线)' ,
`pay_new_user_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户充值金额，单位元(代理)' ,
`pay_old_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户充值总金额，单位元' ,
`pay_old_user_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户充值总金额，单位元(在线)' ,
`pay_old_user_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户充值总金额，单位元(代理)' ,
`pay_react_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元' ,
`pay_react_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元(在线)' ,
`pay_react_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元(代理)' ,
`pay_select`  varchar(4096) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '充值方式（微信QQ等）金额及占比' ,
`pay_arpu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '日ARPU（日总充值/日登录用户数）' ,
`pay_arppu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '日ARPPU（日总充值/日总充值人数）' ,
`pay_day_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '首日付费率（100*新用户充值总人数/当日注册用户数）' ,
`pay_login_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '登陆玩家付费率' ,
`pay_play_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '活跃玩家付费率' ,
`over_user`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产用户' ,
`over_user_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '当日破产率' ,
`over_pay_user`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产后充值用户' ,
`over_times`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产后充值次数' ,
`over_pay_times`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产次数' ,
`cash_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总金额，单位元' ,
`cash_total_tax`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换税收(手续费)，单位元' ,
`cash_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换总人数' ,
`cash_total_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换总次数' ,
`cash_new_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户兑换金额，单位元' ,
`cash_old_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户兑换金额，单位元' ,
`cash_new_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户兑换人数' ,
`cash_old_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户兑换人数' ,
`gold_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总金币/100，实际单位元' ,
`gold_bind_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总绑定金/100，实际单位元' ,
`gold_bind_money_proxy`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总绑定金/100，实际单位元，代理' ,
`gold_bind_money_player`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总绑定金/100，实际单位元，玩家' ,
`gold_bank_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总银行金/100，实际单位元' ,
`gold_bank_money_proxy`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总银行金/100，实际单位元，代理' ,
`gold_bank_money_player`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总银行金/100，实际单位元，玩家' ,
`gold_free_reg_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家注册赠送钱数，单位元' ,
`gold_free_bind_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家绑定赠送钱数，单位元' ,
`gold_player_free_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家受赠的钱，单位元' ,
`gold_player_add_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家钱数相对上一天的增长，单位元' ,
`gold_player_add_ratio`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家钱数相对上一天的增长百分比' ,
`reg_user`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户数量' ,
`reg_user_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户游客账号数量' ,
`reg_user_format`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户正式账号数量' ,
`bind_count`  int(11) NOT NULL DEFAULT 0 COMMENT '该日绑定手机总人数' ,
`reg_ip_count`  int(11) NOT NULL DEFAULT 0 COMMENT '注册Ip数量' ,
`reg_ios`  int(11) NOT NULL DEFAULT 0 COMMENT '注册手机IOS数量' ,
`reg_android`  int(11) NOT NULL DEFAULT 0 COMMENT '注册手机android数量' ,
`login_user`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆用户数' ,
`login_user_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆游客用户数' ,
`login_user_format`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆正式用户数' ,
`login_user_new`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆新用户数' ,
`login_user_old`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆旧用户数' ,
`login_ip_count`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆Ip数' ,
`login_ios`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆IOS数量' ,
`login_android`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆android数量' ,
`tax_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总税收' ,
`tax_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '总人数' ,
`tax_dizhu_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '地主税收' ,
`tax_dizhu_people`  int(11) NOT NULL DEFAULT 0 COMMENT '地主人数' ,
`tax_jinhua_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '金花税收' ,
`tax_jinhua_people`  int(11) NOT NULL DEFAULT 0 COMMENT '金花人数' ,
`tax_niuniu_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '牛牛税收' ,
`tax_niuniu_people`  int(11) NOT NULL DEFAULT 0 COMMENT '牛牛人数' ,
`tax_laohu_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机税收' ,
`tax_laohu_people`  int(11) NOT NULL DEFAULT 0 COMMENT '老虎机人数' ,
`tax_suoha_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '二人梭哈税收' ,
`tax_suoha_people`  int(11) NOT NULL DEFAULT 0 COMMENT '二人梭哈人数' ,
`tax_qiang_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '抢庄牛牛税收' ,
`tax_qiang_people`  int(11) NOT NULL DEFAULT 0 COMMENT '抢庄牛牛人数' ,
`tax_jing6_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '经典牛牛税收' ,
`tax_jing6_people`  int(11) NOT NULL DEFAULT 0 COMMENT '经典牛牛人数' ,
`tax_msuoha_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '多人梭哈税收' ,
`tax_msuoha_people`  int(11) NOT NULL DEFAULT 0 COMMENT '多人梭哈人数' ,
`tax_fish_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '李逵捕鱼税收' ,
`tax_fish_people`  int(11) NOT NULL DEFAULT 0 COMMENT '李逵捕鱼人数' ,
`tax_jcfish_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '金蟾捕鱼税收' ,
`tax_jcfish_people`  int(11) NOT NULL DEFAULT 0 COMMENT '金蟾捕鱼人数' ,
`tax_red_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '红黑大战税收' ,
`tax_red_people`  int(11) NOT NULL DEFAULT 0 COMMENT '红黑大战人数' ,
`tax_3shui_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '十三张(十三水)税收' ,
`tax_3shui_people`  int(11) NOT NULL DEFAULT 0 COMMENT '十三张(十三水)人数' ,
`tax_shaizi_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '骰宝税收' ,
`tax_shaizi_people`  int(11) NOT NULL DEFAULT 0 COMMENT '骰宝人数' ,
`tax_twentyone_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '21点税收' ,
`tax_twentyone_people`  int(11) NOT NULL DEFAULT 0 COMMENT '21点人数' ,
`tax_toradora_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '龙虎斗税收' ,
`tax_toradora_people`  int(11) NOT NULL DEFAULT 0 COMMENT '龙虎斗人数' ,
`tax_fivestar_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '五星宏辉税收' ,
`tax_fivestar_people`  int(11) NOT NULL DEFAULT 0 COMMENT '五星宏辉人数' ,
`tax_sys_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛系统输赢金币/100，实际单位元，赢为正输为负' ,
`tax_laohu_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机系统输赢金币/100，实际单位元，赢正输负' ,
`tax_fish_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '李逵捕鱼系统输赢金币/100，实际单位元，赢正输负' ,
`tax_jcfish_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '金蟾捕鱼系统输赢金币/100，实际单位元，赢正输负' ,
`tax_red_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '红黑大战系统输赢金币/100，实际单位元，赢正输负' ,
`tax_shaizi_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '骰宝系统输赢，单位元' ,
`tax_twentyone_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '21点系统输赢，单位元' ,
`tax_toradora_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '龙虎斗系统输赢，单位元' ,
`tax_fivestar_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '五星宏辉系统输赢，单位元' ,
`tax_dizhu_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '斗地主系统输赢金币/100，实际单位元，赢正输负' ,
`tax_niuniu_times`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛玩家人次' ,
`tax_jinhua_times`  int(11) NOT NULL DEFAULT 0 COMMENT '炸金花玩家人次' ,
`tax_laohu_times`  int(11) NOT NULL DEFAULT 0 COMMENT '老虎机玩家人次' ,
`pool_jinhua_has`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '奖池炸金花钱数，单位元' ,
`pool_laohu_has`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机金花钱数，单位元' ,
`sys_100_is_banker_count`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄总局数' ,
`sys_100_is_banker_win`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄赢局数' ,
`sys_100_is_banker_kill9`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄通杀局数' ,
`sys_100_is_banker_kill9_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛坐庄通杀概率' ,
`sys_100_is_banker_crush`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄通赔局数' ,
`sys_100_is_banker_crush_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛坐庄通赔概率' ,
`play_turn_count_total`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_total`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_total`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_dizhu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_dizhu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_dizhu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_jinhua`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_jinhua`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长，合计' ,
`play_cost_time_avg_jinhua`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_niuniu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_niuniu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长，百人牛牛' ,
`play_cost_time_avg_niuniu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_laohu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，老虎机' ,
`play_cost_time_laohu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_laohu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_suoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，二人梭哈' ,
`play_cost_time_suoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_suoha`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_qiang`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，抢庄牛牛' ,
`play_cost_time_qiang`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_qiang`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_jing6`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，经典牛牛' ,
`play_cost_time_jing6`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_jing6`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_msuoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，多人梭哈' ,
`play_cost_time_msuoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_msuoha`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_fish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，李逵捕鱼' ,
`play_cost_time_fish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_fish`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_jcfish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，金蟾捕鱼' ,
`play_cost_time_jcfish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_jcfish`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_red`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，红黑大战' ,
`play_cost_time_red`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_red`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_3shui`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数，十三张(十三水)' ,
`play_cost_time_3shui`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_3shui`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_shaizi`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数，骰宝' ,
`play_cost_time_shaizi`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_shaizi`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_twentyone`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数, 21点' ,
`play_cost_time_twentyone`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_twentyone`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_toradora`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数, 龙虎斗' ,
`play_cost_time_toradora`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_toradora`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_fivestar`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数, 五星宏辉' ,
`play_cost_time_fivestar`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_fivestar`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`agent_pay_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理商支付的钱，单位元' ,
`agent_get_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理商获得的金币，单位元' ,
`agent_get_people`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商来进货的人数' ,
`agent_get_times`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商来进货的次数' ,
`agent_out_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理商卖出的金币，单位元' ,
`agent_out_people`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商卖出的玩家人数' ,
`agent_out_times`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商卖出的玩家人次' ,
`back_1`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_2`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '2日回头率' ,
`back_3`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_4`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '4日回头率' ,
`back_5`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '5日回头率' ,
`back_6`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '6日回头率' ,
`back_7`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_8`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '8日回头率' ,
`back_9`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '9日回头率' ,
`back_10`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '10日回头率' ,
`back_15`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`back_30`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '30日回头率' ,
`back_base`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '回头率额外统计数据(pay_ratio:留存用户付费率,arppu:留存用户ARPPU)' ,
`back_cash`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '回头充值历史兑换数据(ori_cash_times:回头充值玩家历史兑换订单数,ori_cash_people:回头充值玩家历史兑换用户数)' ,
`back_play`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '新玩家游戏数据(game_people:人数,play_count:局数,total_time:时长,total_tax:税收(元),agv_time:均时,avg_tax:均税(元))' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '玩家价值(LTV)统计' ,
`update_time`  varchar(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '更新时间(主要数据)' ,
PRIMARY KEY (`day`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_sys_day_sheet
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_sys_day_sheet_plats
-- ----------------------------
DROP TABLE IF EXISTS `wz_sys_day_sheet_plats`;
CREATE TABLE `wz_sys_day_sheet_plats` (
`day`  char(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '日期' ,
`plat_id`  int(11) NOT NULL COMMENT '分发平台ID' ,
`jiesuan_flag`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '结算标识，代码以此识别该日是否被下一日做了结算' ,
`jiesuan_time`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '结算时间，代码以此标记该日被下一日结算时的时间' ,
`yingshou_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '营收总金额，单位元' ,
`yingshou_ch_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道营收，单位元，仅仅是渠道下的充值-兑换-分成' ,
`fencheng_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '渠道分成，单位元' ,
`pay_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数' ,
`pay_total_people_1`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数(在线)' ,
`pay_total_people_2`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数(代理)' ,
`pay_new_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总人数' ,
`pay_new_user_people_1`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总人数(在线)' ,
`pay_new_user_people_2`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总人数(代理)' ,
`pay_old_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总人数' ,
`pay_old_user_people_1`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总人数(在线)' ,
`pay_old_user_people_2`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总人数(代理)' ,
`pay_total_times`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数' ,
`pay_total_times_1`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数(在线)' ,
`pay_total_times_2`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数(代理)' ,
`pay_new_user_times`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总次数' ,
`pay_new_user_times_1`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总次数(在线)' ,
`pay_new_user_times_2`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户充值总次数(代理)' ,
`pay_old_user_times`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总次数' ,
`pay_old_user_times_1`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总次数(在线)' ,
`pay_old_user_times_2`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户充值总次数(代理)' ,
`pay_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元' ,
`pay_total_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元(在线)' ,
`pay_total_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元(代理)' ,
`pay_new_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户充值金额，单位元' ,
`pay_new_user_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户充值金额，单位元(在线)' ,
`pay_new_user_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户充值金额，单位元(代理)' ,
`pay_old_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户充值总金额，单位元' ,
`pay_old_user_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户充值总金额，单位元(在线)' ,
`pay_old_user_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户充值总金额，单位元(代理)' ,
`pay_react_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元' ,
`pay_react_money_1`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元(在线)' ,
`pay_react_money_2`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元(代理)' ,
`pay_select`  varchar(4096) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '充值方式（微信QQ等）金额及占比' ,
`pay_arpu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '日ARPU（日总充值/日登录用户数）' ,
`pay_arppu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '日ARPPU（日总充值/日总充值人数）' ,
`pay_day_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '首日付费率（100*新用户充值总人数/当日注册用户数）' ,
`pay_login_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '登陆玩家付费率' ,
`pay_play_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '活跃玩家付费率' ,
`over_user`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产用户' ,
`over_user_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '当日破产率' ,
`over_pay_user`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产后充值用户' ,
`over_times`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产后充值次数' ,
`over_pay_times`  int(11) NOT NULL DEFAULT 0 COMMENT '当日破产次数' ,
`cash_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总金额，单位元' ,
`cash_total_tax`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '兑换税收(手续费)，单位元' ,
`cash_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换总人数' ,
`cash_total_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换总次数' ,
`cash_new_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '新用户兑换金额，单位元' ,
`cash_old_user_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老用户兑换金额，单位元' ,
`cash_new_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '新用户兑换人数' ,
`cash_old_user_people`  int(11) NOT NULL DEFAULT 0 COMMENT '老用户兑换人数' ,
`gold_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总金币/100，实际单位元' ,
`gold_bind_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总绑定金/100，实际单位元' ,
`gold_bind_money_proxy`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总绑定金/100，实际单位元，代理' ,
`gold_bind_money_player`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总绑定金/100，实际单位元，玩家' ,
`gold_bank_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总银行金/100，实际单位元' ,
`gold_bank_money_proxy`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总银行金/100，实际单位元，代理' ,
`gold_bank_money_player`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总银行金/100，实际单位元，玩家' ,
`gold_free_reg_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家注册赠送钱数，单位元' ,
`gold_free_bind_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家绑定赠送钱数，单位元' ,
`gold_player_free_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家受赠的钱，单位元' ,
`gold_player_add_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家钱数相对上一天的增长，单位元' ,
`gold_player_add_ratio`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '玩家钱数相对上一天的增长百分比' ,
`reg_user`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户数量' ,
`reg_user_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户游客账号数量' ,
`reg_user_format`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户正式账号数量' ,
`bind_count`  int(11) NOT NULL DEFAULT 0 COMMENT '该日绑定手机总人数' ,
`reg_ip_count`  int(11) NOT NULL DEFAULT 0 COMMENT '注册Ip数量' ,
`reg_ios`  int(11) NOT NULL DEFAULT 0 COMMENT '注册手机IOS数量' ,
`reg_android`  int(11) NOT NULL DEFAULT 0 COMMENT '注册手机android数量' ,
`login_user`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆用户数' ,
`login_user_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆游客用户数' ,
`login_user_format`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆正式用户数' ,
`login_user_new`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆新用户数' ,
`login_user_old`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆旧用户数' ,
`login_ip_count`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆Ip数' ,
`login_ios`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆IOS数量' ,
`login_android`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆android数量' ,
`tax_total_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '总税收' ,
`tax_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '总人数' ,
`tax_dizhu_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '地主税收' ,
`tax_dizhu_people`  int(11) NOT NULL DEFAULT 0 COMMENT '地主人数' ,
`tax_jinhua_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '金花税收' ,
`tax_jinhua_people`  int(11) NOT NULL DEFAULT 0 COMMENT '金花人数' ,
`tax_niuniu_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '牛牛税收' ,
`tax_niuniu_people`  int(11) NOT NULL DEFAULT 0 COMMENT '牛牛人数' ,
`tax_laohu_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机税收' ,
`tax_laohu_people`  int(11) NOT NULL DEFAULT 0 COMMENT '老虎机人数' ,
`tax_suoha_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '二人梭哈税收' ,
`tax_suoha_people`  int(11) NOT NULL DEFAULT 0 COMMENT '二人梭哈人数' ,
`tax_qiang_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '抢庄牛牛税收' ,
`tax_qiang_people`  int(11) NOT NULL DEFAULT 0 COMMENT '抢庄牛牛人数' ,
`tax_jing6_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '经典牛牛税收' ,
`tax_jing6_people`  int(11) NOT NULL DEFAULT 0 COMMENT '经典牛牛人数' ,
`tax_msuoha_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '多人梭哈税收' ,
`tax_msuoha_people`  int(11) NOT NULL DEFAULT 0 COMMENT '多人梭哈人数' ,
`tax_fish_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '李逵捕鱼税收' ,
`tax_fish_people`  int(11) NOT NULL DEFAULT 0 COMMENT '李逵捕鱼人数' ,
`tax_jcfish_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '金蟾捕鱼税收' ,
`tax_jcfish_people`  int(11) NOT NULL DEFAULT 0 COMMENT '金蟾捕鱼人数' ,
`tax_red_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '红黑大战税收' ,
`tax_red_people`  int(11) NOT NULL DEFAULT 0 COMMENT '红黑大战人数' ,
`tax_3shui_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '十三张(十三水)税收' ,
`tax_3shui_people`  int(11) NOT NULL DEFAULT 0 COMMENT '十三张(十三水)人数' ,
`tax_shaizi_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '骰宝税收' ,
`tax_shaizi_people`  int(11) NOT NULL DEFAULT 0 COMMENT '骰宝人数' ,
`tax_twentyone_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '21点税收' ,
`tax_twentyone_people`  int(11) NOT NULL DEFAULT 0 COMMENT '21点人数' ,
`tax_toradora_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '龙虎斗税收' ,
`tax_toradora_people`  int(11) NOT NULL DEFAULT 0 COMMENT '龙虎斗人数' ,
`tax_fivestar_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '五星宏辉税收' ,
`tax_fivestar_people`  int(11) NOT NULL DEFAULT 0 COMMENT '五星宏辉人数' ,
`tax_sys_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛系统输赢金币/100，实际单位元，赢为正输为负' ,
`tax_laohu_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机系统输赢金币/100，实际单位元，赢正输负' ,
`tax_fish_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '李逵捕鱼系统输赢金币/100，实际单位元，赢正输负' ,
`tax_jcfish_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '金蟾捕鱼系统输赢金币/100，实际单位元，赢正输负' ,
`tax_red_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '红黑大战系统输赢金币/100，实际单位元，赢正输负' ,
`tax_shaizi_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '骰宝系统输赢，单位元' ,
`tax_twentyone_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '21点系统输赢，单位元' ,
`tax_toradora_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '龙虎斗系统输赢，单位元' ,
`tax_fivestar_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '五星宏辉系统输赢，单位元' ,
`tax_dizhu_win_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '斗地主系统输赢金币/100，实际单位元，赢正输负' ,
`tax_niuniu_times`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛玩家人次' ,
`tax_jinhua_times`  int(11) NOT NULL DEFAULT 0 COMMENT '炸金花玩家人次' ,
`tax_laohu_times`  int(11) NOT NULL DEFAULT 0 COMMENT '老虎机玩家人次' ,
`pool_jinhua_has`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '奖池炸金花钱数，单位元' ,
`pool_laohu_has`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机金花钱数，单位元' ,
`sys_100_is_banker_count`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄总局数' ,
`sys_100_is_banker_win`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄赢局数' ,
`sys_100_is_banker_kill9`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄通杀局数' ,
`sys_100_is_banker_kill9_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛坐庄通杀概率' ,
`sys_100_is_banker_crush`  int(11) NOT NULL DEFAULT 0 COMMENT '百人牛牛坐庄通赔局数' ,
`sys_100_is_banker_crush_ratio`  decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛坐庄通赔概率' ,
`play_turn_count_total`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_total`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_total`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_dizhu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_dizhu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_dizhu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_jinhua`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_jinhua`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长，合计' ,
`play_cost_time_avg_jinhua`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_niuniu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数' ,
`play_cost_time_niuniu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长，百人牛牛' ,
`play_cost_time_avg_niuniu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_laohu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，老虎机' ,
`play_cost_time_laohu`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_laohu`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_suoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，二人梭哈' ,
`play_cost_time_suoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_suoha`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_qiang`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，抢庄牛牛' ,
`play_cost_time_qiang`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_qiang`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_jing6`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，经典牛牛' ,
`play_cost_time_jing6`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_jing6`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_msuoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，多人梭哈' ,
`play_cost_time_msuoha`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_msuoha`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_fish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，李逵捕鱼' ,
`play_cost_time_fish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_fish`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_jcfish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，金蟾捕鱼' ,
`play_cost_time_jcfish`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_jcfish`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_red`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总局数，红黑大战' ,
`play_cost_time_red`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_red`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_3shui`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数，十三张(十三水)' ,
`play_cost_time_3shui`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_3shui`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_shaizi`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数，骰宝' ,
`play_cost_time_shaizi`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_shaizi`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_twentyone`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数, 21点' ,
`play_cost_time_twentyone`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_twentyone`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_toradora`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数, 龙虎斗' ,
`play_cost_time_toradora`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_toradora`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`play_turn_count_fivestar`  int(11) NOT NULL DEFAULT 0 COMMENT '总局数, 五星宏辉' ,
`play_cost_time_fivestar`  int(11) NOT NULL DEFAULT 0 COMMENT '总时长' ,
`play_cost_time_avg_fivestar`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '平均时长' ,
`agent_pay_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理商支付的钱，单位元' ,
`agent_get_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理商获得的金币，单位元' ,
`agent_get_people`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商来进货的人数' ,
`agent_get_times`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商来进货的次数' ,
`agent_out_money`  decimal(16,2) NOT NULL DEFAULT 0.00 COMMENT '代理商卖出的金币，单位元' ,
`agent_out_people`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商卖出的玩家人数' ,
`agent_out_times`  int(11) NOT NULL DEFAULT 0 COMMENT '代理商卖出的玩家人次' ,
`back_1`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '昨日回头率' ,
`back_2`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '2日回头率' ,
`back_3`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '3日回头率' ,
`back_4`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '4日回头率' ,
`back_5`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '5日回头率' ,
`back_6`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '6日回头率' ,
`back_7`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '7日回头率' ,
`back_8`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '8日回头率' ,
`back_9`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '9日回头率' ,
`back_10`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '10日回头率' ,
`back_15`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '15日回头率' ,
`back_30`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '30日回头率' ,
`back_base`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '回头率额外统计数据(pay_ratio:留存用户付费率,arppu:留存用户ARPPU)' ,
`back_cash`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '回头充值历史兑换数据(ori_cash_times:回头充值玩家历史兑换订单数,ori_cash_people:回头充值玩家历史兑换用户数)' ,
`back_play`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '新玩家游戏数据(game_people:人数,play_count:局数,total_time:时长,total_tax:税收(元),agv_time:均时,avg_tax:均税(元))' ,
`ltv`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '玩家价值(LTV)统计' ,
`update_time`  varchar(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '更新时间(主要数据)' ,
PRIMARY KEY (`day`, `plat_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_sys_day_sheet_plats
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_sys_month_sheet
-- ----------------------------
DROP TABLE IF EXISTS `wz_sys_month_sheet`;
CREATE TABLE `wz_sys_month_sheet` (
`month`  char(7) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '日期（该表是系统报表每日数据）' ,
`jiesuan_flag`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '结算标识，代码以此识别该日是否被下一日做了结算' ,
`jiesuan_time`  char(19) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '结算时间，代码以此标记该日被下一日结算时的时间' ,
`yingshou_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '营收金额，单位元' ,
`fencheng_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '渠道分成，单位元' ,
`pay_total_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '充值总额，单位元' ,
`pay_react_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '扣除充值渠道税费后的充值总额，单位元' ,
`pay_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总人数' ,
`pay_total_times`  int(11) NOT NULL DEFAULT 0 COMMENT '充值总次数' ,
`pay_arpu`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '月ARPU（月充值总量/月登录用户人数）' ,
`pay_arppu`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '月ARPPU（月充值总量/月充值用户人数）' ,
`pay_month_ratio`  float(5,2) NOT NULL DEFAULT 0.00 COMMENT '月付费率（月充值用户人数/月注册用户数量）' ,
`cash_total_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '兑换总金额，单位元' ,
`cash_total_people`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换总人数' ,
`cash_total_times`  int(11) NOT NULL DEFAULT 0 COMMENT '兑换总次数' ,
`gold_total_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '玩家的总金币/100，实际单位元' ,
`gold_bind_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '玩家的绑定金币/100，实际单位元' ,
`gold_bank_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '玩家的银行金币/100，实际单位元' ,
`reg_user`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户数量' ,
`reg_user_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户游客账号数量' ,
`reg_user_format`  int(11) NOT NULL DEFAULT 0 COMMENT '注册用户正式账号数量' ,
`reg_ip_count`  int(11) NOT NULL DEFAULT 0 COMMENT '注册Ip数量' ,
`reg_ios`  int(11) NOT NULL DEFAULT 0 COMMENT '注册手机IOS数量' ,
`reg_android`  int(11) NOT NULL DEFAULT 0 COMMENT '注册手机android数量' ,
`login_user`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆用户数' ,
`login_user_guest`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆游客用户数' ,
`login_user_format`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆正式用户数' ,
`login_ip_count`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆Ip数' ,
`login_ios`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆IOS数量' ,
`login_android`  int(11) NOT NULL DEFAULT 0 COMMENT '登陆android数量' ,
`tax_total_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '总税收' ,
`tax_dizhu_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '地主税收' ,
`tax_jinhua_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '金花税收' ,
`tax_niuniu_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '牛牛税收' ,
`tax_laohu_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机税收' ,
`tax_sys_win_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '百人牛牛系统输赢金币/100，实际单位元，赢为正输为负' ,
`tax_laohu_win_money`  float(12,2) NOT NULL DEFAULT 0.00 COMMENT '老虎机系统输赢金币/100，实际单位元，赢正输负' ,
PRIMARY KEY (`month`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of wz_sys_month_sheet
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Auto increment value for action_log
-- ----------------------------
ALTER TABLE `action_log` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for channel_business
-- ----------------------------
ALTER TABLE `channel_business` AUTO_INCREMENT=22;

-- ----------------------------
-- Auto increment value for channel_tax
-- ----------------------------
ALTER TABLE `channel_tax` AUTO_INCREMENT=2174;

-- ----------------------------
-- Auto increment value for ds_errors_record
-- ----------------------------
ALTER TABLE `ds_errors_record` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for ds_select_cycle
-- ----------------------------
ALTER TABLE `ds_select_cycle` AUTO_INCREMENT=14;

-- ----------------------------
-- Auto increment value for ds_select_forever
-- ----------------------------
ALTER TABLE `ds_select_forever` AUTO_INCREMENT=10;

-- ----------------------------
-- Auto increment value for menus
-- ----------------------------
ALTER TABLE `menus` AUTO_INCREMENT=19;

-- ----------------------------
-- Auto increment value for permission_role
-- ----------------------------
ALTER TABLE `permission_role` AUTO_INCREMENT=54;

-- ----------------------------
-- Auto increment value for permission_user
-- ----------------------------
ALTER TABLE `permission_user` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for permissions
-- ----------------------------
ALTER TABLE `permissions` AUTO_INCREMENT=91;

-- ----------------------------
-- Auto increment value for role_user
-- ----------------------------
ALTER TABLE `role_user` AUTO_INCREMENT=56;

-- ----------------------------
-- Auto increment value for roles
-- ----------------------------
ALTER TABLE `roles` AUTO_INCREMENT=4;

-- ----------------------------
-- Auto increment value for users
-- ----------------------------
ALTER TABLE `users` AUTO_INCREMENT=60;

-- ----------------------------
-- Auto increment value for wz_a_data_group
-- ----------------------------
ALTER TABLE `wz_a_data_group` AUTO_INCREMENT=18;
