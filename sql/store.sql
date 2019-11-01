/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50727
Source Host           : localhost:3306
Source Database       : store

Target Server Type    : MYSQL
Target Server Version : 50727
File Encoding         : 65001

Date: 2019-08-25 18:33:49
*/

SET FOREIGN_KEY_CHECKS=0;

DROP DATABASE IF EXISTS store;
CREATE DATABASE store;
USE store;

-- ----------------------------
-- Table structure for channel_plat
-- ----------------------------
DROP TABLE IF EXISTS `channel_plat`;
CREATE TABLE `channel_plat` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`plat_id`  int(11) NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of channel_plat
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Table structure for wz_kvs_data_cache
-- ----------------------------
DROP TABLE IF EXISTS `wz_kvs_data_cache`;
CREATE TABLE `wz_kvs_data_cache` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`key`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`value`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
`created_at`  timestamp NULL DEFAULT NULL ,
`updated_at`  timestamp NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Records of wz_kvs_data_cache
-- ----------------------------
BEGIN;
COMMIT;

-- ----------------------------
-- Auto increment value for channel_plat
-- ----------------------------
ALTER TABLE `channel_plat` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for wz_kvs_data_cache
-- ----------------------------
ALTER TABLE `wz_kvs_data_cache` AUTO_INCREMENT=1;
