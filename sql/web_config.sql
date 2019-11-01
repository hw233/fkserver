/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : web_config

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:34:11
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS web_config;
CREATE DATABASE web_config;
USE web_config;

-- ----------------------------
-- Table structure for t_bank_log
-- ----------------------------
DROP TABLE IF EXISTS `t_bank_log`;
CREATE TABLE `t_bank_log` (
`id`  int(10) NOT NULL AUTO_INCREMENT ,
`admin_name`  varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '管理员用户名' ,
`user_guid`  int(10) NULL DEFAULT NULL COMMENT '操作玩家ID' ,
`before_bank`  bigint(20) NULL DEFAULT NULL COMMENT '操作之前银行金' ,
`after_bank`  bigint(20) NULL DEFAULT NULL COMMENT '操作之后银行金' ,
`addtime`  timestamp NULL DEFAULT NULL COMMENT '添加时间' ,
`ip`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作者IP' ,
`contents`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '说明' ,
`status`  int(1) NULL DEFAULT NULL COMMENT '更新是否成功 0为失败。1为成功' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='绑定金操作日志'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_bank_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_cash_url_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_cash_url_cfg`;
CREATE TABLE `t_cash_url_cfg` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`service_url`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '转账地址' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_service_url` (`service_url`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='提现地址存储表'
AUTO_INCREMENT=31

;

-- ----------------------------
-- Records of t_cash_url_cfg
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_client_config_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_client_config_cfg`;
CREATE TABLE `t_client_config_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`channel`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`version`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '版本号' ,
`father`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '父级' ,
`key`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '键名' ,
`value`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键值' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='客户端配置表'
AUTO_INCREMENT=263

;

-- ----------------------------
-- Records of t_client_config_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_client_config_cfg` VALUES ('234', 'test', '1.0.0', '', 'hall_download_info', '{\"hall_update_res.zip\": {\r\n			\"filename\": \"hall_update_res.zip\",\r\n			\"updated_at\": \"2018-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 39,\r\n			\"size\": \"1328\",\r\n			\"md5\": \"892188fb29502ae10da9afed659e2e9d\",\r\n			\"plat_id\": 2,\r\n			\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_update_res.zip\"\r\n		},\r\n		\"hall_res.zip\": {\r\n			\"filename\": \"hall_res.zip\",\r\n			\"updated_at\": \"2018-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 37,\r\n			\"size\": \"8036197\",\r\n			\"md5\": \"7145e15f292b0e8b508ded65bd12b773\",\r\n			\"plat_id\": 2,\r\n			\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_res.zip\"\r\n		},\r\n		\"hall_src.zip\": {\r\n			\"filename\": \"hall_src.zip\",\r\n			\"updated_at\": \"2018-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 38,\r\n			\"size\": \"1152172\",\r\n			\"md5\": \"447b3c9866b330b25018c7bdcaaf103b\",\r\n			\"plat_id\": 2,\r\n			\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_src.zip\"\r\n		}}', '大厅下载信息', '2019-08-22 11:04:36', '2019-08-22 11:55:42', '2019-08-22 11:55:42'), ('229', 'test', '1.0.0', 'config', 'hall_download_info', ' {\r\n		\"hall_update_res.zip\": {\r\n			\"filename\": \"hall_update_res.zip\",\r\n			\"updated_at\": \"2018-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 39,\r\n			\"size\": \"1328\",\r\n			\"md5\": \"892188fb29502ae10da9afed659e2e9d\",\r\n			\"plat_id\": 2,\r\n			\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_update_res.zip\"\r\n		},\r\n		\"hall_res.zip\": {\r\n			\"filename\": \"hall_res.zip\",\r\n			\"updated_at\": \"2018-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 37,\r\n			\"size\": \"8036197\",\r\n			\"md5\": \"7145e15f292b0e8b508ded65bd12b773\",\r\n			\"plat_id\": 2,\r\n			\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_res.zip\"\r\n		},\r\n		\"hall_src.zip\": {\r\n			\"filename\": \"hall_src.zip\",\r\n			\"updated_at\": \"2018-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 38,\r\n			\"size\": \"1152172\",\r\n			\"md5\": \"447b3c9866b330b25018c7bdcaaf103b\",\r\n			\"plat_id\": 2,\r\n			\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_src.zip\"\r\n		}\r\n	}', 'lkdsaojfdsa', '2019-08-21 10:44:15', '2019-08-21 10:55:13', '2019-08-21 10:55:13'), ('230', 'test', '1.0.1', 'hall_info', 'backup_server_urls', '[\"http:\\/\\/118.24.60.168\\/api\\/index\\/index\", \"http:\\/\\/118.24.60.168\\/api\\/index\\/index\"]', 'dsafda', '2019-08-21 10:54:20', '2019-08-22 11:57:11', '2019-08-22 11:57:11'), ('231', 'test', '1.0.0', 'hall_info', 'addr', '[\"101.37.247.237#7788\"]', 'test', '2019-08-21 10:54:59', '2019-08-21 10:54:59', null), ('232', 'test', '1.0.0', 'hall_info', 'version', '1.0.0', 'dsafd', '2019-08-21 10:55:52', '2019-08-21 10:55:52', null), ('235', 'test', '1.0.0', '', 'client_info', '{\r\n		\"channel\": \"test\",\r\n		\"version\": \"1.0.0\",\r\n		\"is_must_update\": \"true\",\r\n		\"server_urls\": [\"http://101.37.247.237/api/update/client_const.json\"],\r\n		\"update_url\": \"http://101.37.247.237/api/update/jx_201907160818/hall_res.zip\",\r\n		\"enable_debug\": true,\r\n		\"platform_id\":\"2\"\r\n	}', '客户端基础配置', '2019-08-22 11:06:22', '2019-08-22 11:06:22', null), ('236', 'test', '1.0.1', 'hall_info', 'config', '{\r\n			\"hall_ui_other_btns_config\": {\r\n				\"btn_kaifu\": true,\r\n				\"more_game_back_btn\": true,\r\n				\"more_game_btn\": true\r\n			},\r\n			\"pay_url\": {\r\n				\"web_create_order\": \"https:\\/\\/pay.126zl.com\\/api\\/pay\\/store\",\r\n				\"ios_query_order\": \"https:\\/\\/pay.126zl.com\\/api\\/apple\\/apple_pay\",\r\n				\"ios_create_order\": \"https:\\/\\/pay.126zl.com\\/api\\/apple\\/store\",\r\n				\"web_query_order\": \"https:\\/\\/pay.126zl.com\\/api\\/pay\\/show\"\r\n			},\r\n			\"gold_to_money_ratio\": \"100\",\r\n			\"template\": \"default\",\r\n			\"iospay\": \"true\",\r\n			\"feedback_list_url\": \"http:\\/\\/118.24.60.168:8888\\/api\\/feedback\\/messageList\",\r\n			\"custom_service_url\": \"https:\\/\\/Callcenter.2ytx.com\",\r\n			\"personal_center_btns\": [{\r\n				\"account_bind_view_btn\": true\r\n			}, {\r\n				\"person_info_view_btn\": true\r\n			}, {\r\n				\"alipay_bind_view_btn\": true\r\n			}, {\r\n				\"modify_password_view_btn\": true\r\n			}],\r\n			\"exchange_min_remain_money\": \"3.0\",\r\n			\"inviter_code\": \"true\",\r\n			\"agents_info\": [{\r\n				\"qq\": \"1256945632\",\r\n				\"zfb\": \"222\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu1\",\r\n				\"weixin\": \"1667773\",\r\n				\"name\": \"蒙特在线\",\r\n				\"min_recharge\": 50\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu2\",\r\n				\"weixin\": \"504161\",\r\n				\"name\": \"筑赢金库\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu3\",\r\n				\"weixin\": \"7171799\",\r\n				\"name\": \"官方充值1号店 \"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu4\",\r\n				\"weixin\": \"1707004\",\r\n				\"name\": \"FAFA金库\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu5\",\r\n				\"weixin\": \"8088874\",\r\n				\"name\": \"斯巴达金库\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu11\",\r\n				\"weixin\": \"5122219\",\r\n				\"name\": \"招财猫的小叮当\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu22\",\r\n				\"weixin\": \"931724\",\r\n				\"name\": \"24小时在线\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu33\",\r\n				\"weixin\": \"1', '大厅相关配置', '2019-08-22 11:08:33', '2019-08-22 14:04:16', '2019-08-22 14:04:16'), ('237', 'test', '1.0.0', '', 'frame_download_info', '{\"frame_src.zip\": {\r\n			\"filename\": \"frame_src.zip\",\r\n			\"updated_at\": \"2017-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 12,\r\n			\"size\": \"161355\",\r\n			\"md5\": \"6bcf55022b53429cf0d7c15972cbc160\",\r\n			\"plat_id\": 1,\r\n			\"update_url\": \"http:\\/\\/118.24.60.168\\/update1\\/frame_src.zip\"\r\n		},\r\n		\"frame_res.zip\": {\r\n			\"filename\": \"frame_res.zip\",\r\n			\"updated_at\": \"2017-07-29 00:27:12\",\r\n			\"version\": \"1.0.19\",\r\n			\"id\": 13,\r\n			\"size\": \"813524\",\r\n			\"md5\": \"d07099c2ca6df1e3248ca40fcbf223a3\",\r\n			\"plat_id\": 1,\r\n			\"update_url\": \"http:\\/\\/118.24.60.168\\/update1\\/frame_res.zip\"\r\n		}\r\n}', '框架下载信息', '2019-08-22 11:09:28', '2019-08-22 15:10:23', null), ('238', 'test', '1.0.0', '', 'games_download_info', '{}', '游戏下配置', '2019-08-22 11:10:24', '2019-08-22 11:18:48', null), ('239', 'test', '1.0.0', 'games_download_info', '5', '{\r\n			\"ddzgame_res.zip\": {\r\n				\"md5\": \"c31febe042bc9134373d13873e3fc90a\",\r\n				\"version\": \"1.0.28\",\r\n				\"size\": \"7572694\",\r\n				\"update_url\": \"http:\\/\\/down.2ytx.com\\/update\\/201707100400\\/ddzgame_res.zip\"\r\n			},\r\n			\"ddzgame_src.zip\": {\r\n				\"md5\": \"8162a4380877258efdeb1e08a2d53a81\",\r\n				\"version\": \"1.0.30\",\r\n				\"size\": \"285268\",\r\n				\"update_url\": \"http:\\/\\/down.2ytx.com\\/update\\/201707100400\\/ddzgame_src.zip\"\r\n			}\r\n		}', '斗地主配置', '2019-08-22 11:19:46', '2019-08-22 11:19:46', null), ('240', 'test', '1.0.0', 'games_download_info', '6', ' {\r\n			\"gflower_src.zip\": {\r\n				\"updated_at\": \"2017-07-30 03:55:05\",\r\n				\"version\": \"1.0.20\",\r\n				\"id\": 31,\r\n				\"size\": \"236139\",\r\n				\"plat_id\": 1,\r\n				\"md5\": \"740647870492035529f1dc3d1c5b0024\",\r\n				\"update_url\": \"http:\\/\\/118.24.60.168\\/update1\\/gflower_src.zip\"\r\n			},\r\n			\"gflower_res.zip\": {\r\n				\"updated_at\": \"2017-07-29 00:27:12\",\r\n				\"version\": \"1.0.19\",\r\n				\"id\": 30,\r\n				\"size\": \"5564642\",\r\n				\"plat_id\": 1,\r\n				\"md5\": \"4912b5b7575e65514c147656a28f19b8\",\r\n				\"update_url\": \"http:\\/\\/118.24.60.168\\/update1\\/gflower_res.zip\"\r\n			}\r\n		}', '炸金花配置', '2019-08-22 11:20:46', '2019-08-22 15:09:47', null), ('241', 'test', '1.0.0', 'config', 'hall_ui_other_btns_config', '{\r\n				\"btn_kaifu\": true,\r\n				\"more_game_back_btn\": true,\r\n				\"more_game_btn\": true\r\n			}', '客户端按钮开关', '2019-08-22 13:54:37', '2019-08-22 13:54:37', null), ('242', 'test', '1.0.0', 'config', 'pay_url', '{\r\n				\"web_create_order\": \"https:\\/\\/pay.126zl.com\\/api\\/pay\\/store\",\r\n				\"ios_query_order\": \"https:\\/\\/pay.126zl.com\\/api\\/apple\\/apple_pay\",\r\n				\"ios_create_order\": \"https:\\/\\/pay.126zl.com\\/api\\/apple\\/store\",\r\n				\"web_query_order\": \"https:\\/\\/pay.126zl.com\\/api\\/pay\\/show\"\r\n			}', '支付url', '2019-08-22 13:56:13', '2019-08-22 13:56:13', null), ('243', 'test', '1.0.0', 'config', 'gold_to_money_ratio', '100', '金币，钱竞换比率', '2019-08-22 13:57:51', '2019-08-22 15:07:27', null), ('244', 'test', '1.0.0', 'config', 'template', 'default', '模板', '2019-08-22 13:58:25', '2019-08-22 15:07:16', null), ('245', 'test', '1.0.0', '', 'iospay', 'true', 'ios支付开关', '2019-08-22 13:58:55', '2019-08-22 13:58:55', null), ('246', 'test', '1.0.0', 'config', 'feedback_list_url', 'http:\\/\\/118.24.60.168:8888\\/api\\/feedback\\/messageList', '反馈url列表', '2019-08-22 13:59:37', '2019-08-22 13:59:37', null), ('247', 'test', '1.0.0', 'config', 'custom_service_url', 'https:\\/\\/Callcenter.2ytx.com', '客户url', '2019-08-22 14:00:18', '2019-08-22 14:00:18', null), ('248', 'test', '1.0.0', 'config', 'personal_center_btns', ' [{\r\n				\"account_bind_view_btn\": true\r\n			}, {\r\n				\"person_info_view_btn\": true\r\n			}, {\r\n				\"alipay_bind_view_btn\": true\r\n			}, {\r\n				\"modify_password_view_btn\": true\r\n			}]', '个人中心按钮配置', '2019-08-22 14:01:17', '2019-08-22 14:01:17', null), ('249', 'test', '1.0.0', 'config', 'exchange_min_remain_money', '3.0', '提现最小剩余值', '2019-08-22 14:01:54', '2019-08-22 14:01:54', null), ('250', 'test', '1.0.0', 'config', 'inviter_code', 'true', '邀请码开关', '2019-08-22 14:02:24', '2019-08-22 14:02:24', null), ('251', 'test', '1.0.0', 'config', 'agents_info', '[{\r\n				\"qq\": \"1256945632\",\r\n				\"zfb\": \"222\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu1\",\r\n				\"weixin\": \"1667773\",\r\n				\"name\": \"蒙特在线\",\r\n				\"min_recharge\": 50\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu2\",\r\n				\"weixin\": \"504161\",\r\n				\"name\": \"筑赢金库\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu3\",\r\n				\"weixin\": \"7171799\",\r\n				\"name\": \"官方充值1号店 \"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu4\",\r\n				\"weixin\": \"1707004\",\r\n				\"name\": \"FAFA金库\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu5\",\r\n				\"weixin\": \"8088874\",\r\n				\"name\": \"斯巴达金库\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu11\",\r\n				\"weixin\": \"5122219\",\r\n				\"name\": \"招财猫的小叮当\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu22\",\r\n				\"weixin\": \"931724\",\r\n				\"name\": \"24小时在线\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu33\",\r\n				\"weixin\": \"1671313\",\r\n				\"name\": \"葫芦兄弟\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu44\",\r\n				\"weixin\": \"7820707\",\r\n				\"name\": \"小希\"\r\n			}, {\r\n				\"qq\": \"\",\r\n				\"zfb\": \"\",\r\n				\"phone\": \"\",\r\n				\"account\": \"kefu55\",\r\n				\"weixin\": \"7288835\",\r\n				\"name\": \"招财金库\"\r\n			}]', '代理信息', '2019-08-22 14:03:07', '2019-08-22 14:03:07', null), ('252', 'test', '1.0.0', 'config', 'feedback_create_url', 'http:\\/\\/118.24.60.168:8888\\/api\\/feedback\\/create', '反馈提交url', '2019-08-22 14:04:06', '2019-08-22 14:04:06', null), ('253', 'test', '1.0.0', 'config', 'need_hide_games', '\"6\": {\r\n					\"version\": 1,\r\n					\"hide_sec\": 5\r\n				}', '隐藏游戏', '2019-08-22 14:05:00', '2019-08-22 14:05:00', null), ('254', 'test', '1.0.0', 'config', 'hall_ui_btns_config', '[{\r\n				\"btn_account\": true\r\n			}, {\r\n				\"bank_center_btn\": true\r\n			}, {\r\n				\"btn_exchange\": true\r\n			}, {\r\n				\"btn_feedback\": true\r\n			}, {\r\n				\"btn_notice\": true\r\n			}, {\r\n				\"btn_message\": true\r\n			}, {\r\n				\"btn_custom_service\": true\r\n			}, {\r\n				\"setting_btn\": true\r\n			}]', '大厅按钮开关', '2019-08-22 14:05:42', '2019-08-22 14:05:42', null), ('255', 'test', '1.0.0', 'config', 'exchange_multiple', '50', '兑换倍率', '2019-08-22 14:06:16', '2019-08-22 14:06:16', null), ('256', 'test', '1.0.0', 'config', 'become_agent_url', 'http:\\/\\/118.24.60.168:8888\\/api\\/proxy\\/create', '成为代理请求url', '2019-08-22 14:06:47', '2019-08-22 14:06:47', null), ('257', 'test', '1.0.0', 'config', 'max_recharge_per', '3500', '单次最大冲值', '2019-08-22 14:07:36', '2019-08-22 14:07:36', null), ('258', 'test', '1.0.0', 'config', 'recharge_types', '{\r\n				\"transferpay\": false,\r\n				\"zfb\": true,\r\n				\"androidpay\": false,\r\n				\"weixin\": true,\r\n				\"dlcz\": true,\r\n				\"iospay\": false,\r\n				\"dlzs\": true,\r\n				\"tgy\": false\r\n			}', '充值类型开关', '2019-08-22 14:08:25', '2019-08-22 14:08:25', null), ('259', 'test', '1.0.0', 'config', 'feedback_login_url', 'http:\\/\\/118.24.60.168:8888\\/api\\/feedback\\/loginInit', '反馈登陆url', '2019-08-22 14:09:00', '2019-08-22 14:09:00', null), ('260', 'test', '1.0.0', 'config', 'agents_zhaoshang', '{\r\n				\"qq\": {},\r\n				\"weixin\": {}\r\n			}', '代理招商客服', '2019-08-22 14:09:38', '2019-08-22 14:09:38', null), ('261', 'test', '1.0.0', 'config', 'site_home_url', 'http:\\/\\/www.muhexi.com', '主页', '2019-08-22 14:56:47', '2019-08-22 14:56:47', null), ('262', 'test', '1.0.0', 'config', 'complain_url', 'http:\\/\\/118.24.60.168:8888\\/api\\/proxy\\/complain', '投诉本局url', '2019-08-22 14:59:51', '2019-08-22 14:59:51', null);
COMMIT;

-- ----------------------------
-- Table structure for t_config_template_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_config_template_cfg`;
CREATE TABLE `t_config_template_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`father`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '父级' ,
`key`  varchar(75) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '键名' ,
`value`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '键值' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`),
UNIQUE INDEX `unique_key_father` (`key`, `father`) USING BTREE 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='客户端配置模板表'
AUTO_INCREMENT=31

;

-- ----------------------------
-- Records of t_config_template_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_config_template_cfg` VALUES ('30', 'hall_info', 'config', 'sadsafdsafds', 'dsafdsa', '2019-08-21 10:58:05', '2019-08-21 10:58:05');
COMMIT;

-- ----------------------------
-- Table structure for t_frame_version_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_frame_version_cfg`;
CREATE TABLE `t_frame_version_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`version`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '版本号' ,
`channel`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`update_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '下载地址' ,
`describe`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '框架更新说明' ,
`filename`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包文件名字' ,
`md5`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包内容md5加密' ,
`size`  int(10) NOT NULL DEFAULT 0 COMMENT '包大小' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=7

;

-- ----------------------------
-- Records of t_frame_version_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_frame_version_cfg` VALUES ('4', '1.0.0', 'test', 'http://localhost/uploads/20190821/frame_res.zip', '主版本', 'frame_res.zip', 'B1D7B2975DB1BF6A5190D4D0D6140A6A', '2656580', '2019-08-21 10:36:14', '2019-08-21 11:12:05', '2019-08-21 11:12:05'), ('2', '1.0.0', 'main', 'http://localhost/uploads/20190821/frame_res.zip', '主框架', 'frame_res.zip', 'B1D7B2975DB1BF6A5190D4D0D6140A6A', '2656580', '2019-08-21 10:22:09', '2019-08-21 11:13:00', '2019-08-21 11:13:00'), ('3', '1.0.0', 'test', 'http://localhost/uploads/20190821/frame_res.zip', '框架测试版', 'frame_res.zip', 'B1D7B2975DB1BF6A5190D4D0D6140A6A', '2656580', '2019-08-21 10:23:10', '2019-08-21 11:12:55', '2019-08-21 11:12:55'), ('5', '1.0.0', 'test', 'http://localhost/uploads/20190821/frame_src.zip', '框架代码', 'frame_src.zip', 'BA40283506291F264323AC72B9B8C0B3', '452081', '2019-08-21 11:12:40', '2019-08-21 11:12:40', null), ('6', '1.0.0', 'test', 'http://localhost/uploads/20190821/gflower_res.zip', '框架资源', 'gflower_res.zip', '9EE8E9DA24E46727F30AE49863350644', '3090962', '2019-08-21 11:13:21', '2019-08-21 11:13:21', null);
COMMIT;

-- ----------------------------
-- Table structure for t_game_tax_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_game_tax_cfg`;
CREATE TABLE `t_game_tax_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`game_id`  smallint(4) NOT NULL DEFAULT 0 COMMENT '游戏id' ,
`game_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '游戏名字' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '游戏说明' ,
`tax`  smallint(4) NOT NULL DEFAULT 0 COMMENT '税收' ,
`is_enable`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '1启用' ,
`is_show`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '1显示' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='游戏税收配置表'
AUTO_INCREMENT=11

;

-- ----------------------------
-- Records of t_game_tax_cfg
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_game_version_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_game_version_cfg`;
CREATE TABLE `t_game_version_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`game_id`  int(10) NOT NULL DEFAULT 0 COMMENT '游戏id' ,
`channel`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`game_name`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '游戏名字' ,
`version`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '版本号' ,
`update_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '下载地址' ,
`describe`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '游戏更新说明' ,
`filename`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包文件名字' ,
`md5`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包内容md5加密' ,
`size`  int(10) NOT NULL DEFAULT 0 COMMENT '包大小' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=3

;

-- ----------------------------
-- Records of t_game_version_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_game_version_cfg` VALUES ('1', '3', 'test', 'fishing', '1.0.1', 'http://localhost/uploads/20190821/fishgame_res.zip', '捕鱼测试版', 'fishgame_res.zip', '3C6284A4635809E1AADE9C35DDBC735A', '24760934', '2019-08-21 10:26:58', '2019-08-21 10:26:58', null), ('2', '3', 'test', 'fishing', '1.0.0', 'http://localhost/uploads/20190821/fishgame_src.zip', '捕鱼游戏代码', 'fishgame_src.zip', 'EE60C81EA535C070C6C71E4736F67FB5', '590261', '2019-08-21 11:16:06', '2019-08-21 11:16:06', null);
COMMIT;

-- ----------------------------
-- Table structure for t_hall_version_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_hall_version_cfg`;
CREATE TABLE `t_hall_version_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`version`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '版本号' ,
`channel`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '渠道号' ,
`update_url`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '下载地址' ,
`describe`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '大厅更新说明' ,
`filename`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包文件名字' ,
`md5`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '包内容md5加密' ,
`size`  int(10) NOT NULL DEFAULT 0 COMMENT '包大小' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
`deleted_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=5

;

-- ----------------------------
-- Records of t_hall_version_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_hall_version_cfg` VALUES ('1', '1.0.1', 'main', 'http://localhost/uploads/20190821/hall_res.zip', '大厅主版本', 'hall_res.zip', '7145E15F292B0E8B508DED65BD12B773', '8036197', '2019-08-21 10:19:33', '2019-08-21 11:14:24', '2019-08-21 11:14:24'), ('2', '1.0.0', 'test', 'http://localhost/uploads/20190821/hall_res.zip', '大厅测试版', 'hall_res.zip', '7145E15F292B0E8B508DED65BD12B773', '8036197', '2019-08-21 10:23:53', '2019-08-21 11:14:31', '2019-08-21 11:14:31'), ('3', '1.0.0', 'test', 'http://localhost/uploads/20190821/hall_src.zip', '大厅代码', 'hall_src.zip', '447B3C9866B330B25018C7BDCAAF103B', '1152172', '2019-08-21 11:14:13', '2019-08-21 11:14:13', null), ('4', '1.0.0', 'test', 'http://localhost/uploads/20190821/hall_res.zip', '大厅资源', 'hall_res.zip', '7145E15F292B0E8B508DED65BD12B773', '8036197', '2019-08-21 11:15:01', '2019-08-21 11:15:01', null);
COMMIT;

-- ----------------------------
-- Table structure for t_log_cash_white
-- ----------------------------
DROP TABLE IF EXISTS `t_log_cash_white`;
CREATE TABLE `t_log_cash_white` (
`day`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
`guid`  bigint(20) NULL DEFAULT NULL ,
`remark`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`day`),
INDEX `day_index` (`day`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;

-- ----------------------------
-- Records of t_log_cash_white
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_log_feng_guid
-- ----------------------------
DROP TABLE IF EXISTS `t_log_feng_guid`;
CREATE TABLE `t_log_feng_guid` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`guid`  bigint(20) NOT NULL COMMENT '要封掉的guid' ,
`type`  tinyint(2) NULL DEFAULT NULL COMMENT '类型：1=封号 0=解封' ,
`phone`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的手机号，即account' ,
`mac`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '关联封掉的imei' ,
`reason`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封号的原因' ,
`handler`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作用户' ,
`time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '操作时间' ,
PRIMARY KEY (`id`),
INDEX `guid_index` (`guid`) USING BTREE 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_log_feng_guid
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_money_log
-- ----------------------------
DROP TABLE IF EXISTS `t_money_log`;
CREATE TABLE `t_money_log` (
`id`  int(10) NOT NULL AUTO_INCREMENT ,
`admin_name`  varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '管理员用户名' ,
`user_guid`  int(10) NULL DEFAULT NULL COMMENT '操作玩家ID' ,
`before_money`  bigint(20) NULL DEFAULT NULL COMMENT '操作之前绑定金' ,
`after_money`  bigint(20) NULL DEFAULT NULL COMMENT '操作之后绑定金' ,
`addtime`  timestamp NULL DEFAULT NULL COMMENT '添加时间' ,
`ip`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '操作者IP' ,
`contents`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '说明' ,
`status`  int(1) NULL DEFAULT NULL COMMENT '更新是否成功 0为失败。1为成功' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='绑定金操作日志'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_money_log
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_print_card_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_print_card_cfg`;
CREATE TABLE `t_print_card_cfg` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`goods_id`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '商品ID' ,
`goods_amt`  double(11,2) NOT NULL DEFAULT 0.00 COMMENT '订单价格' ,
`goods_gold`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '转换金币(万)' ,
`goods_desc`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '描述' ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='点卡配置'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of t_print_card_cfg
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for t_risk_config_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_risk_config_cfg`;
CREATE TABLE `t_risk_config_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`recharge_min`  int(10) UNSIGNED NOT NULL COMMENT '充值区间小' ,
`recharge_max`  int(10) UNSIGNED NOT NULL COMMENT '充值区间大' ,
`type`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '1总充值区间 2单笔充值区间' ,
`proportion`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '比例 1代表1%' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='风控系统配置表'
AUTO_INCREMENT=19

;

-- ----------------------------
-- Records of t_risk_config_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_risk_config_cfg` VALUES ('17', '5', '100', '1', '100', '测试', '2019-08-15 21:09:11', '2019-08-15 21:09:11'), ('18', '23', '200', '2', '100', '测试', '2019-08-15 22:14:41', '2019-08-15 22:15:20');
COMMIT;

-- ----------------------------
-- Table structure for t_system_config_cfg
-- ----------------------------
DROP TABLE IF EXISTS `t_system_config_cfg`;
CREATE TABLE `t_system_config_cfg` (
`id`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`key`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '键名' ,
`value`  text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '键值' ,
`description`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '描述' ,
`created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='管理后台配置表'
AUTO_INCREMENT=9

;

-- ----------------------------
-- Records of t_system_config_cfg
-- ----------------------------
BEGIN;
INSERT INTO `t_system_config_cfg` VALUES ('7', 'smsSwitch', '1', '短信接口配置，1为正常短信接口，2为灾备短信接口', '2019-08-14 15:12:27', null), ('8', 'cashMoneyMax', '100', '提现审核的最大金额限制', '2019-08-15 22:09:32', '2019-08-15 22:09:32');
COMMIT;

-- ----------------------------
-- Auto increment value for t_bank_log
-- ----------------------------
ALTER TABLE `t_bank_log` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_cash_url_cfg
-- ----------------------------
ALTER TABLE `t_cash_url_cfg` AUTO_INCREMENT=31;

-- ----------------------------
-- Auto increment value for t_client_config_cfg
-- ----------------------------
ALTER TABLE `t_client_config_cfg` AUTO_INCREMENT=263;

-- ----------------------------
-- Auto increment value for t_config_template_cfg
-- ----------------------------
ALTER TABLE `t_config_template_cfg` AUTO_INCREMENT=31;

-- ----------------------------
-- Auto increment value for t_frame_version_cfg
-- ----------------------------
ALTER TABLE `t_frame_version_cfg` AUTO_INCREMENT=7;

-- ----------------------------
-- Auto increment value for t_game_tax_cfg
-- ----------------------------
ALTER TABLE `t_game_tax_cfg` AUTO_INCREMENT=11;

-- ----------------------------
-- Auto increment value for t_game_version_cfg
-- ----------------------------
ALTER TABLE `t_game_version_cfg` AUTO_INCREMENT=3;

-- ----------------------------
-- Auto increment value for t_hall_version_cfg
-- ----------------------------
ALTER TABLE `t_hall_version_cfg` AUTO_INCREMENT=5;

-- ----------------------------
-- Auto increment value for t_log_feng_guid
-- ----------------------------
ALTER TABLE `t_log_feng_guid` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_money_log
-- ----------------------------
ALTER TABLE `t_money_log` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_print_card_cfg
-- ----------------------------
ALTER TABLE `t_print_card_cfg` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for t_risk_config_cfg
-- ----------------------------
ALTER TABLE `t_risk_config_cfg` AUTO_INCREMENT=19;

-- ----------------------------
-- Auto increment value for t_system_config_cfg
-- ----------------------------
ALTER TABLE `t_system_config_cfg` AUTO_INCREMENT=9;
