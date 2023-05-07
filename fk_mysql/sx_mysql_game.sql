/*
 Navicat Premium Data Transfer

 Source Server         : 顺欣预发布
 Source Server Type    : MariaDB
 Source Server Version : 100607
 Source Host           : 20.187.72.52:3306
 Source Schema         : game

 Target Server Type    : MariaDB
 Target Server Version : 100607
 File Encoding         : 65001

 Date: 27/01/2023 11:43:50
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_club
-- ----------------------------
DROP TABLE IF EXISTS `t_club`;
CREATE TABLE `t_club`  (
  `id` int(4) NOT NULL DEFAULT 0,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `owner` int(4) NOT NULL,
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `type` smallint(1) NULL DEFAULT 0 COMMENT '0是群 1联盟',
  `parent` int(4) NULL DEFAULT NULL,
  `status` smallint(1) NOT NULL DEFAULT 0 COMMENT '营业状态 0正常 1打烊',
  `creator` int(4) NULL DEFAULT NULL,
  `created_at` int(11) NULL DEFAULT 0,
  `updated_at` int(11) NULL DEFAULT 0,
  PRIMARY KEY (`id`, `owner`) USING BTREE,
  INDEX `idx_club`(`id`) USING BTREE,
  INDEX `idx_type`(`type`) USING BTREE,
  INDEX `idx_club_type`(`id`, `type`) USING BTREE,
  INDEX `idx_status`(`status`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '亲友群或联盟表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club
-- ----------------------------
INSERT INTO `t_club` VALUES (679757, '001', 454224, '', 0, 0, 0, 1, 1657794246, 1657794246);
INSERT INTO `t_club` VALUES (690812, '萧让亲友', 838031, '', 0, 0, 0, 1, 1667296878, 1667296878);
INSERT INTO `t_club` VALUES (813402, '王大爷的亲友群', 701579, '', 0, 0, 0, 1, 1654675776, 1654675776);
INSERT INTO `t_club` VALUES (832287, '011_200558', 200558, '', 0, 0, 0, 1, 1654742708, 1654742708);
INSERT INTO `t_club` VALUES (60320931, 'vip001', 838031, '', 1, 0, 0, 1, 1671867328, 1671867328);
INSERT INTO `t_club` VALUES (63080376, '预发布联盟', 784411, '', 1, 0, 0, 1, 1671623967, 1671623967);
INSERT INTO `t_club` VALUES (63162504, '测试联盟', 704946, '', 1, 0, 0, 1, 1655692622, 1655692622);
INSERT INTO `t_club` VALUES (64793141, '我的预发布', 700139, '', 1, 0, 0, 1, 1671627966, 1671627966);
INSERT INTO `t_club` VALUES (66219171, '秋生联盟', 130200, '', 1, 0, 0, 1, 1672471241, 1672471241);
INSERT INTO `t_club` VALUES (66428602, '废掉', 701579, '', 1, 0, 1, 1, 1654655392, 1654655392);
INSERT INTO `t_club` VALUES (67262628, '盟主哼哈嘿', 553184, '', 1, 0, 0, 1, 1667962332, 1667962332);
INSERT INTO `t_club` VALUES (67975768, 'sixgod', 454224, '', 1, 0, 0, 1, 1657794232, 1657794232);
INSERT INTO `t_club` VALUES (68057792, 'caiqing111', 841507, '', 1, 0, 0, 1, 1658325286, 1658325286);
INSERT INTO `t_club` VALUES (68705185, 'vip001', 838031, '', 1, 0, 0, 1, 1672477362, 1672477362);
INSERT INTO `t_club` VALUES (69081204, '第二个联盟', 271686, '', 1, 0, 0, 1, 1667964854, 1667964854);
INSERT INTO `t_club` VALUES (69760170, '预发二联盟', 784411, '', 1, 0, 0, 1, 1671624154, 1671624154);
INSERT INTO `t_club` VALUES (80736136, '011_200558', 200558, '', 1, 0, 0, 1, 1654742733, 1654742733);
INSERT INTO `t_club` VALUES (81378004, 'vic001联盟', 701579, '', 1, 0, 0, 1, 1655975725, 1655975725);
INSERT INTO `t_club` VALUES (83035683, 'caiqing012的联盟', 816808, '', 1, 0, 0, 1, 1655277922, 1655277922);
INSERT INTO `t_club` VALUES (85389915, 'wode', 468842, '', 1, 0, 0, 1, 1671286502, 1672473471);
INSERT INTO `t_club` VALUES (85665832, 'rong001', 365220, '', 1, 0, 0, 1, 1655968827, 1655968827);
INSERT INTO `t_club` VALUES (88603133, 'lili联盟', 546824, '', 1, 0, 0, 1, 1659704379, 1659704379);

-- ----------------------------
-- Table structure for t_club_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_club_commission`;
CREATE TABLE `t_club_commission`  (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `club` int(4) NOT NULL,
  `commission` bigint(8) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`, `club`) USING BTREE,
  INDEX `idx_club`(`club`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club_commission
-- ----------------------------

-- ----------------------------
-- Table structure for t_club_gaming_blacklist
-- ----------------------------
DROP TABLE IF EXISTS `t_club_gaming_blacklist`;
CREATE TABLE `t_club_gaming_blacklist`  (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club_id` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unqi_idx`(`club_id`, `guid`) USING HASH
) ENGINE = InnoDB AUTO_INCREMENT = 5490 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club_gaming_blacklist
-- ----------------------------
INSERT INTO `t_club_gaming_blacklist` VALUES (5485, 81378004, 600332);
INSERT INTO `t_club_gaming_blacklist` VALUES (5487, 81378004, 176516);

-- ----------------------------
-- Table structure for t_club_member
-- ----------------------------
DROP TABLE IF EXISTS `t_club_member`;
CREATE TABLE `t_club_member`  (
  `club` int(8) NOT NULL COMMENT 'club id',
  `guid` int(8) NOT NULL COMMENT '玩家id',
  `status` smallint(2) NOT NULL DEFAULT 0 COMMENT '成员状态 0：正常 1：已移除',
  PRIMARY KEY (`club`, `guid`) USING BTREE,
  UNIQUE INDEX `idx_club_id`(`club`, `guid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '亲友群或联盟成员' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club_member
-- ----------------------------
INSERT INTO `t_club_member` VALUES (679757, 454224, 0);
INSERT INTO `t_club_member` VALUES (690812, 444507, 0);
INSERT INTO `t_club_member` VALUES (690812, 838031, 0);
INSERT INTO `t_club_member` VALUES (813402, 285541, 0);
INSERT INTO `t_club_member` VALUES (813402, 623211, 0);
INSERT INTO `t_club_member` VALUES (813402, 684573, 0);
INSERT INTO `t_club_member` VALUES (813402, 701579, 0);
INSERT INTO `t_club_member` VALUES (813402, 753973, 0);
INSERT INTO `t_club_member` VALUES (832287, 200558, 0);
INSERT INTO `t_club_member` VALUES (60320931, 444185, 0);
INSERT INTO `t_club_member` VALUES (60320931, 444507, 0);
INSERT INTO `t_club_member` VALUES (60320931, 678070, 0);
INSERT INTO `t_club_member` VALUES (60320931, 686627, 0);
INSERT INTO `t_club_member` VALUES (60320931, 838031, 0);
INSERT INTO `t_club_member` VALUES (60320931, 904998, 0);
INSERT INTO `t_club_member` VALUES (60320931, 907284, 0);
INSERT INTO `t_club_member` VALUES (63080376, 784411, 0);
INSERT INTO `t_club_member` VALUES (63080376, 969335, 0);
INSERT INTO `t_club_member` VALUES (63162504, 573589, 0);
INSERT INTO `t_club_member` VALUES (63162504, 704946, 0);
INSERT INTO `t_club_member` VALUES (64793141, 293188, 0);
INSERT INTO `t_club_member` VALUES (64793141, 361304, 0);
INSERT INTO `t_club_member` VALUES (64793141, 374654, 0);
INSERT INTO `t_club_member` VALUES (64793141, 700139, 0);
INSERT INTO `t_club_member` VALUES (64793141, 999386, 0);
INSERT INTO `t_club_member` VALUES (66219171, 130200, 0);
INSERT INTO `t_club_member` VALUES (66219171, 223429, 0);
INSERT INTO `t_club_member` VALUES (66219171, 433185, 0);
INSERT INTO `t_club_member` VALUES (66219171, 453372, 0);
INSERT INTO `t_club_member` VALUES (66219171, 548694, 0);
INSERT INTO `t_club_member` VALUES (66219171, 713117, 0);
INSERT INTO `t_club_member` VALUES (66428602, 701579, 0);
INSERT INTO `t_club_member` VALUES (67262628, 119700, 0);
INSERT INTO `t_club_member` VALUES (67262628, 160142, 0);
INSERT INTO `t_club_member` VALUES (67262628, 187666, 0);
INSERT INTO `t_club_member` VALUES (67262628, 271686, 0);
INSERT INTO `t_club_member` VALUES (67262628, 326092, 0);
INSERT INTO `t_club_member` VALUES (67262628, 338663, 0);
INSERT INTO `t_club_member` VALUES (67262628, 361607, 0);
INSERT INTO `t_club_member` VALUES (67262628, 415909, 0);
INSERT INTO `t_club_member` VALUES (67262628, 448518, 0);
INSERT INTO `t_club_member` VALUES (67262628, 551000, 0);
INSERT INTO `t_club_member` VALUES (67262628, 553184, 0);
INSERT INTO `t_club_member` VALUES (67262628, 587423, 0);
INSERT INTO `t_club_member` VALUES (67262628, 617849, 0);
INSERT INTO `t_club_member` VALUES (67262628, 651402, 0);
INSERT INTO `t_club_member` VALUES (67262628, 767947, 0);
INSERT INTO `t_club_member` VALUES (67262628, 851492, 0);
INSERT INTO `t_club_member` VALUES (67262628, 918682, 0);
INSERT INTO `t_club_member` VALUES (67975768, 454224, 0);
INSERT INTO `t_club_member` VALUES (67975768, 568541, 0);
INSERT INTO `t_club_member` VALUES (67975768, 725921, 0);
INSERT INTO `t_club_member` VALUES (67975768, 867979, 0);
INSERT INTO `t_club_member` VALUES (68057792, 841507, 0);
INSERT INTO `t_club_member` VALUES (68705185, 838031, 0);
INSERT INTO `t_club_member` VALUES (69081204, 254139, 0);
INSERT INTO `t_club_member` VALUES (69081204, 271686, 0);
INSERT INTO `t_club_member` VALUES (69081204, 345846, 0);
INSERT INTO `t_club_member` VALUES (69081204, 617849, 0);
INSERT INTO `t_club_member` VALUES (69760170, 784411, 0);
INSERT INTO `t_club_member` VALUES (80736136, 200558, 0);
INSERT INTO `t_club_member` VALUES (81378004, 152426, 0);
INSERT INTO `t_club_member` VALUES (81378004, 176516, 0);
INSERT INTO `t_club_member` VALUES (81378004, 200558, 0);
INSERT INTO `t_club_member` VALUES (81378004, 203700, 0);
INSERT INTO `t_club_member` VALUES (81378004, 270827, 0);
INSERT INTO `t_club_member` VALUES (81378004, 285541, 0);
INSERT INTO `t_club_member` VALUES (81378004, 364602, 0);
INSERT INTO `t_club_member` VALUES (81378004, 365220, 0);
INSERT INTO `t_club_member` VALUES (81378004, 439596, 0);
INSERT INTO `t_club_member` VALUES (81378004, 444185, 0);
INSERT INTO `t_club_member` VALUES (81378004, 468083, 0);
INSERT INTO `t_club_member` VALUES (81378004, 493732, 0);
INSERT INTO `t_club_member` VALUES (81378004, 511985, 0);
INSERT INTO `t_club_member` VALUES (81378004, 568541, 0);
INSERT INTO `t_club_member` VALUES (81378004, 571057, 0);
INSERT INTO `t_club_member` VALUES (81378004, 600332, 0);
INSERT INTO `t_club_member` VALUES (81378004, 618763, 0);
INSERT INTO `t_club_member` VALUES (81378004, 623211, 0);
INSERT INTO `t_club_member` VALUES (81378004, 659532, 0);
INSERT INTO `t_club_member` VALUES (81378004, 684573, 0);
INSERT INTO `t_club_member` VALUES (81378004, 701579, 0);
INSERT INTO `t_club_member` VALUES (81378004, 743811, 0);
INSERT INTO `t_club_member` VALUES (81378004, 753973, 0);
INSERT INTO `t_club_member` VALUES (81378004, 780508, 0);
INSERT INTO `t_club_member` VALUES (81378004, 841251, 0);
INSERT INTO `t_club_member` VALUES (81378004, 905173, 0);
INSERT INTO `t_club_member` VALUES (83035683, 816808, 0);
INSERT INTO `t_club_member` VALUES (85389915, 123187, 0);
INSERT INTO `t_club_member` VALUES (85389915, 349020, 0);
INSERT INTO `t_club_member` VALUES (85389915, 468842, 0);
INSERT INTO `t_club_member` VALUES (85389915, 552045, 0);
INSERT INTO `t_club_member` VALUES (85389915, 617849, 0);
INSERT INTO `t_club_member` VALUES (85389915, 627003, 0);
INSERT INTO `t_club_member` VALUES (85389915, 742950, 0);
INSERT INTO `t_club_member` VALUES (85389915, 745754, 0);
INSERT INTO `t_club_member` VALUES (85389915, 904998, 0);
INSERT INTO `t_club_member` VALUES (85665832, 254329, 0);
INSERT INTO `t_club_member` VALUES (85665832, 316760, 0);
INSERT INTO `t_club_member` VALUES (85665832, 365220, 0);
INSERT INTO `t_club_member` VALUES (85665832, 661060, 0);
INSERT INTO `t_club_member` VALUES (85665832, 701579, 0);
INSERT INTO `t_club_member` VALUES (85665832, 753973, 0);
INSERT INTO `t_club_member` VALUES (85665832, 852949, 0);
INSERT INTO `t_club_member` VALUES (88603133, 140279, 0);
INSERT INTO `t_club_member` VALUES (88603133, 152426, 0);
INSERT INTO `t_club_member` VALUES (88603133, 176516, 0);
INSERT INTO `t_club_member` VALUES (88603133, 218751, 0);
INSERT INTO `t_club_member` VALUES (88603133, 280773, 0);
INSERT INTO `t_club_member` VALUES (88603133, 387979, 0);
INSERT INTO `t_club_member` VALUES (88603133, 538628, 0);
INSERT INTO `t_club_member` VALUES (88603133, 546824, 0);
INSERT INTO `t_club_member` VALUES (88603133, 552276, 0);
INSERT INTO `t_club_member` VALUES (88603133, 573589, 0);
INSERT INTO `t_club_member` VALUES (88603133, 600332, 0);
INSERT INTO `t_club_member` VALUES (88603133, 618763, 0);
INSERT INTO `t_club_member` VALUES (88603133, 743811, 0);
INSERT INTO `t_club_member` VALUES (88603133, 780508, 0);
INSERT INTO `t_club_member` VALUES (88603133, 800545, 0);
INSERT INTO `t_club_member` VALUES (88603133, 808009, 0);
INSERT INTO `t_club_member` VALUES (88603133, 828113, 0);
INSERT INTO `t_club_member` VALUES (88603133, 841251, 0);

-- ----------------------------
-- Table structure for t_club_money
-- ----------------------------
DROP TABLE IF EXISTS `t_club_money`;
CREATE TABLE `t_club_money`  (
  `club` int(11) NOT NULL,
  `money_id` int(2) NOT NULL,
  `money` bigint(8) NOT NULL,
  PRIMARY KEY (`club`, `money_id`) USING BTREE,
  INDEX `index_club_money_id`(`club`, `money_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '亲友群或联盟金钱' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club_money
-- ----------------------------
INSERT INTO `t_club_money` VALUES (679757, 0, 0);
INSERT INTO `t_club_money` VALUES (679757, 58, 0);
INSERT INTO `t_club_money` VALUES (690812, 0, 0);
INSERT INTO `t_club_money` VALUES (690812, 61, 0);
INSERT INTO `t_club_money` VALUES (813402, 0, 0);
INSERT INTO `t_club_money` VALUES (813402, 49, 0);
INSERT INTO `t_club_money` VALUES (832287, 0, 0);
INSERT INTO `t_club_money` VALUES (832287, 50, 0);
INSERT INTO `t_club_money` VALUES (60320931, 0, 0);
INSERT INTO `t_club_money` VALUES (60320931, 68, 0);
INSERT INTO `t_club_money` VALUES (63080376, 0, 0);
INSERT INTO `t_club_money` VALUES (63080376, 65, 0);
INSERT INTO `t_club_money` VALUES (63162504, 0, 0);
INSERT INTO `t_club_money` VALUES (63162504, 53, 0);
INSERT INTO `t_club_money` VALUES (64793141, 0, 0);
INSERT INTO `t_club_money` VALUES (64793141, 67, 0);
INSERT INTO `t_club_money` VALUES (66219171, 0, 0);
INSERT INTO `t_club_money` VALUES (66219171, 69, 0);
INSERT INTO `t_club_money` VALUES (66428602, 0, 0);
INSERT INTO `t_club_money` VALUES (66428602, 48, 0);
INSERT INTO `t_club_money` VALUES (67262628, 0, 0);
INSERT INTO `t_club_money` VALUES (67262628, 62, 0);
INSERT INTO `t_club_money` VALUES (67975768, 0, 0);
INSERT INTO `t_club_money` VALUES (67975768, 57, 0);
INSERT INTO `t_club_money` VALUES (68057792, 0, 0);
INSERT INTO `t_club_money` VALUES (68057792, 59, 0);
INSERT INTO `t_club_money` VALUES (68705185, 0, 0);
INSERT INTO `t_club_money` VALUES (68705185, 70, 0);
INSERT INTO `t_club_money` VALUES (69081204, 0, 0);
INSERT INTO `t_club_money` VALUES (69081204, 63, 0);
INSERT INTO `t_club_money` VALUES (69760170, 0, 0);
INSERT INTO `t_club_money` VALUES (69760170, 66, 0);
INSERT INTO `t_club_money` VALUES (80649427, 0, 0);
INSERT INTO `t_club_money` VALUES (80649427, 54, 0);
INSERT INTO `t_club_money` VALUES (80736136, 0, 0);
INSERT INTO `t_club_money` VALUES (80736136, 51, 0);
INSERT INTO `t_club_money` VALUES (81378004, 0, 0);
INSERT INTO `t_club_money` VALUES (81378004, 56, 0);
INSERT INTO `t_club_money` VALUES (83035683, 0, 0);
INSERT INTO `t_club_money` VALUES (83035683, 52, 0);
INSERT INTO `t_club_money` VALUES (85389915, 0, 0);
INSERT INTO `t_club_money` VALUES (85389915, 64, 0);
INSERT INTO `t_club_money` VALUES (85665832, 0, 0);
INSERT INTO `t_club_money` VALUES (85665832, 55, 0);
INSERT INTO `t_club_money` VALUES (88603133, 0, 0);
INSERT INTO `t_club_money` VALUES (88603133, 60, 0);

-- ----------------------------
-- Table structure for t_club_money_type
-- ----------------------------
DROP TABLE IF EXISTS `t_club_money_type`;
CREATE TABLE `t_club_money_type`  (
  `money_id` int(4) NOT NULL,
  `club` int(4) NOT NULL,
  PRIMARY KEY (`money_id`, `club`) USING BTREE,
  INDEX `index_club_money_type`(`club`, `money_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club_money_type
-- ----------------------------
INSERT INTO `t_club_money_type` VALUES (48, 66428602);
INSERT INTO `t_club_money_type` VALUES (49, 813402);
INSERT INTO `t_club_money_type` VALUES (50, 832287);
INSERT INTO `t_club_money_type` VALUES (51, 80736136);
INSERT INTO `t_club_money_type` VALUES (52, 83035683);
INSERT INTO `t_club_money_type` VALUES (53, 63162504);
INSERT INTO `t_club_money_type` VALUES (55, 85665832);
INSERT INTO `t_club_money_type` VALUES (56, 81378004);
INSERT INTO `t_club_money_type` VALUES (57, 67975768);
INSERT INTO `t_club_money_type` VALUES (58, 679757);
INSERT INTO `t_club_money_type` VALUES (59, 68057792);
INSERT INTO `t_club_money_type` VALUES (60, 88603133);
INSERT INTO `t_club_money_type` VALUES (61, 690812);
INSERT INTO `t_club_money_type` VALUES (62, 67262628);
INSERT INTO `t_club_money_type` VALUES (63, 69081204);
INSERT INTO `t_club_money_type` VALUES (64, 85389915);
INSERT INTO `t_club_money_type` VALUES (65, 63080376);
INSERT INTO `t_club_money_type` VALUES (66, 69760170);
INSERT INTO `t_club_money_type` VALUES (67, 64793141);
INSERT INTO `t_club_money_type` VALUES (68, 60320931);
INSERT INTO `t_club_money_type` VALUES (69, 66219171);
INSERT INTO `t_club_money_type` VALUES (70, 68705185);

-- ----------------------------
-- Table structure for t_club_role
-- ----------------------------
DROP TABLE IF EXISTS `t_club_role`;
CREATE TABLE `t_club_role`  (
  `id` int(8) UNSIGNED NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(4) NOT NULL,
  `role` tinyint(2) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unique_idx`(`club`, `guid`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 15722 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_club_role
-- ----------------------------
INSERT INTO `t_club_role` VALUES (15585, 66428602, 701579, 4);
INSERT INTO `t_club_role` VALUES (15587, 66428602, 753973, 2);
INSERT INTO `t_club_role` VALUES (15589, 66428602, 684573, 2);
INSERT INTO `t_club_role` VALUES (15591, 66428602, 285541, 2);
INSERT INTO `t_club_role` VALUES (15593, 813402, 701579, 4);
INSERT INTO `t_club_role` VALUES (15595, 832287, 200558, 4);
INSERT INTO `t_club_role` VALUES (15597, 80736136, 200558, 4);
INSERT INTO `t_club_role` VALUES (15599, 83035683, 816808, 4);
INSERT INTO `t_club_role` VALUES (15601, 63162504, 704946, 4);
INSERT INTO `t_club_role` VALUES (15605, 85665832, 365220, 4);
INSERT INTO `t_club_role` VALUES (15607, 66428602, 365220, 2);
INSERT INTO `t_club_role` VALUES (15609, 81378004, 701579, 4);
INSERT INTO `t_club_role` VALUES (15611, 81378004, 365220, 2);
INSERT INTO `t_club_role` VALUES (15613, 81378004, 285541, 2);
INSERT INTO `t_club_role` VALUES (15615, 81378004, 684573, 2);
INSERT INTO `t_club_role` VALUES (15617, 81378004, 753973, 2);
INSERT INTO `t_club_role` VALUES (15619, 85665832, 701579, 2);
INSERT INTO `t_club_role` VALUES (15621, 85665832, 753973, 2);
INSERT INTO `t_club_role` VALUES (15623, 67975768, 454224, 4);
INSERT INTO `t_club_role` VALUES (15625, 679757, 454224, 4);
INSERT INTO `t_club_role` VALUES (15627, 81378004, 780508, 2);
INSERT INTO `t_club_role` VALUES (15629, 68057792, 841507, 4);
INSERT INTO `t_club_role` VALUES (15631, 88603133, 546824, 4);
INSERT INTO `t_club_role` VALUES (15633, 88603133, 552276, 2);
INSERT INTO `t_club_role` VALUES (15635, 813402, 285541, 3);
INSERT INTO `t_club_role` VALUES (15637, 85665832, 661060, 2);
INSERT INTO `t_club_role` VALUES (15639, 85665832, 316760, 2);
INSERT INTO `t_club_role` VALUES (15641, 88603133, 280773, 2);
INSERT INTO `t_club_role` VALUES (15643, 88603133, 387979, 2);
INSERT INTO `t_club_role` VALUES (15649, 88603133, 140279, 2);
INSERT INTO `t_club_role` VALUES (15651, 690812, 838031, 4);
INSERT INTO `t_club_role` VALUES (15657, 69793347, 316818, 2);
INSERT INTO `t_club_role` VALUES (15659, 67262628, 553184, 4);
INSERT INTO `t_club_role` VALUES (15661, 67262628, 415909, 2);
INSERT INTO `t_club_role` VALUES (15663, 67262628, 851492, 2);
INSERT INTO `t_club_role` VALUES (15665, 67262628, 160142, 2);
INSERT INTO `t_club_role` VALUES (15667, 69081204, 271686, 4);
INSERT INTO `t_club_role` VALUES (15669, 69081204, 254139, 2);
INSERT INTO `t_club_role` VALUES (15671, 69081204, 617849, 2);
INSERT INTO `t_club_role` VALUES (15673, 69081204, 345846, 2);
INSERT INTO `t_club_role` VALUES (15675, 67262628, 326092, 2);
INSERT INTO `t_club_role` VALUES (15677, 67262628, 271686, 2);
INSERT INTO `t_club_role` VALUES (15679, 67262628, 617849, 2);
INSERT INTO `t_club_role` VALUES (15681, 67262628, 918682, 2);
INSERT INTO `t_club_role` VALUES (15683, 67262628, 361607, 2);
INSERT INTO `t_club_role` VALUES (15685, 67262628, 338663, 2);
INSERT INTO `t_club_role` VALUES (15687, 67262628, 187666, 2);
INSERT INTO `t_club_role` VALUES (15689, 67262628, 651402, 2);
INSERT INTO `t_club_role` VALUES (15691, 85389915, 468842, 4);
INSERT INTO `t_club_role` VALUES (15693, 63080376, 784411, 4);
INSERT INTO `t_club_role` VALUES (15695, 69760170, 784411, 4);
INSERT INTO `t_club_role` VALUES (15697, 64793141, 700139, 4);
INSERT INTO `t_club_role` VALUES (15699, 64793141, 374654, 2);
INSERT INTO `t_club_role` VALUES (15701, 64793141, 999386, 2);
INSERT INTO `t_club_role` VALUES (15703, 64793141, 361304, 2);
INSERT INTO `t_club_role` VALUES (15705, 88603133, 800545, 2);
INSERT INTO `t_club_role` VALUES (15707, 85389915, 123187, 2);
INSERT INTO `t_club_role` VALUES (15709, 60320931, 838031, 4);
INSERT INTO `t_club_role` VALUES (15711, 60320931, 904998, 2);
INSERT INTO `t_club_role` VALUES (15713, 60320931, 686627, 2);
INSERT INTO `t_club_role` VALUES (15715, 60320931, 907284, 2);
INSERT INTO `t_club_role` VALUES (15717, 66219171, 130200, 4);
INSERT INTO `t_club_role` VALUES (15719, 66219171, 223429, 2);
INSERT INTO `t_club_role` VALUES (15721, 68705185, 838031, 4);

-- ----------------------------
-- Table structure for t_notice
-- ----------------------------
DROP TABLE IF EXISTS `t_notice`;
CREATE TABLE `t_notice`  (
  `id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_croatian_ci NOT NULL,
  `type` tinyint(1) NOT NULL,
  `where` tinyint(1) NOT NULL,
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `club` int(4) NULL DEFAULT NULL,
  `start_time` int(8) NULL DEFAULT NULL,
  `end_time` int(8) NULL DEFAULT NULL,
  `play_count` int(4) NULL DEFAULT NULL,
  `create_time` int(8) NULL DEFAULT NULL,
  `update_time` int(8) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_type_where`(`type`, `where`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf16 COLLATE = utf16_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_notice
-- ----------------------------
INSERT INTO `t_notice` VALUES ('1641202915980-3064', 0, 3, '{\"content\":\"警告故意装怪拖延时间的，举报截图3张超过20秒不出牌的。直接封号处理。打假直接清分。请共创和谐游戏！\"}', 84538038, 0, 0, 0, 1641202915, 1648261042);
INSERT INTO `t_notice` VALUES ('1652000975540-9718', 0, 3, '{\"content\":\"做代理联系客服，代理有钱赚上下分联系客服微信17343268464\"}', 62812682, 0, 0, 0, 1652000975, 1652009924);
INSERT INTO `t_notice` VALUES ('1652241377320-2076', 0, 1, '{\"title\":\"\",\"content\":\"百般乐器，唢呐为百王，不是升天，就是拜堂，千年琵琶，万年筝，一把二胡拉一生。唢呐一响全剧终，曲一响，布一盖，全村度老小等上菜，走的走，抬的抬，后面跟着一片白。\"}', NULL, 1652237748, 1652324151, 1, 1652241377, 1652241377);
INSERT INTO `t_notice` VALUES ('1652254276280-9340', 0, 3, '{\"content\":\"我问问翁翁\"}', 62075498, 0, 0, 0, 1652254276, 1652254283);
INSERT INTO `t_notice` VALUES ('1652270732650-6723', 0, 3, '{\"content\":\"水电费更丰富上市公司大飒飒防守打法是懂法守法发的发生发斯蒂芬水电费舒服舒服水电费的沙发沙发斯蒂芬舒服\"}', 626718, 0, 0, 0, 1652270732, 1652326279);
INSERT INTO `t_notice` VALUES ('1652321990650-6834', 0, 3, '{\"content\":\"caiqing盟主公告\"}', 62671882, 0, 0, 0, 1652321990, 1652321990);
INSERT INTO `t_notice` VALUES ('1652586562080-5002', 0, 3, '{\"content\":\"发现打连积分清零\"}', 813172, 0, 0, 0, 1652586562, 1652586562);
INSERT INTO `t_notice` VALUES ('1652627604440-6488', 2, 1, '{\"content\":\"亲爱的玩家:\\n      鉴于昨日网络不稳定及相关日志查询无返回情况，游戏将于 5月17日04:00停服维护，进行优化，大约持续0.5小时，优化不影响任何帐号信息，维护期间无法正常登陆游戏，给您带来的不便敬请谅解。\",\"title\":\"维护公告\"}', NULL, 1652688000, 1655547048, 1, 1652627604, 1655287852);
INSERT INTO `t_notice` VALUES ('1654689917410-1662', 0, 1, '{\"title\":\"维护公告\",\"content\":\"百般乐器，唢呐为百王，不是升天，就是拜堂，千年琵琶，万年筝，一把二胡拉一生。唢呐一响全剧终，曲一响，布一盖，全村度老小等上菜，走的走，抬的抬，后面跟着一片白。\"}', NULL, 1654646400, 1654819200, 1, 1654689917, 1654689917);
INSERT INTO `t_notice` VALUES ('1654829394710-5124', 0, 1, '{\"content\":\"警告故意装怪拖延时间的，举报截图3张超过20秒不出牌的。直接封号处理。打假直接清分。请共创和谐游戏！\",\"title\":\"公告标题\"}', NULL, 1654819200, 1655251200, 1, 1654829394, 1654829394);
INSERT INTO `t_notice` VALUES ('1655283839680-6558', 0, 1, '{\"content\":\"公告正文\",\"title\":\"公告标题\"}', NULL, 1655251200, 1656547200, 1, 1655283839, 1655283839);
INSERT INTO `t_notice` VALUES ('1655287580950-5155', 2, 1, '{\"title\":\"大厅测试公告（弹窗）\",\"content\":\"我是大厅测试公告（弹窗），来呀来呀来呀\"}', NULL, 1655136000, 1656086400, 1, 1655287580, 1656076268);
INSERT INTO `t_notice` VALUES ('1660042114290-531', 0, 3, '{\"content\":\"ffeee\"}', 65882523, 0, 0, 0, 1660042114, 1660042114);

-- ----------------------------
-- Table structure for t_partner_member
-- ----------------------------
DROP TABLE IF EXISTS `t_partner_member`;
CREATE TABLE `t_partner_member`  (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  `partner` int(8) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `idx_partner_mem`(`club`, `partner`, `guid`) USING BTREE,
  INDEX `idx_club`(`club`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 240302 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_partner_member
-- ----------------------------
INSERT INTO `t_partner_member` VALUES (240015, 66428602, 701579, 0, 0);
INSERT INTO `t_partner_member` VALUES (240029, 813402, 701579, 0, 0);
INSERT INTO `t_partner_member` VALUES (240031, 813402, 753973, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240033, 813402, 684573, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240035, 813402, 285541, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240037, 813402, 623211, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240039, 832287, 200558, 0, 0);
INSERT INTO `t_partner_member` VALUES (240041, 80736136, 200558, 0, 0);
INSERT INTO `t_partner_member` VALUES (240045, 83035683, 816808, 0, 0);
INSERT INTO `t_partner_member` VALUES (240047, 63162504, 704946, 0, 0);
INSERT INTO `t_partner_member` VALUES (240051, 63162504, 573589, 704946, 0);
INSERT INTO `t_partner_member` VALUES (240053, 85665832, 365220, 0, 0);
INSERT INTO `t_partner_member` VALUES (240057, 81378004, 701579, 0, 0);
INSERT INTO `t_partner_member` VALUES (240059, 81378004, 365220, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240061, 81378004, 285541, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240063, 81378004, 270827, 285541, 0);
INSERT INTO `t_partner_member` VALUES (240065, 81378004, 684573, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240067, 81378004, 511985, 684573, 0);
INSERT INTO `t_partner_member` VALUES (240069, 81378004, 623211, 684573, 0);
INSERT INTO `t_partner_member` VALUES (240071, 81378004, 753973, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240075, 85665832, 701579, 365220, 0);
INSERT INTO `t_partner_member` VALUES (240077, 85665832, 753973, 365220, 0);
INSERT INTO `t_partner_member` VALUES (240079, 85665832, 254329, 753973, 0);
INSERT INTO `t_partner_member` VALUES (240081, 81378004, 203700, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240083, 67975768, 454224, 0, 0);
INSERT INTO `t_partner_member` VALUES (240085, 679757, 454224, 0, 0);
INSERT INTO `t_partner_member` VALUES (240087, 67975768, 725921, 454224, 0);
INSERT INTO `t_partner_member` VALUES (240089, 67975768, 568541, 454224, 0);
INSERT INTO `t_partner_member` VALUES (240091, 67975768, 867979, 454224, 0);
INSERT INTO `t_partner_member` VALUES (240093, 81378004, 568541, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240095, 81378004, 780508, 285541, 0);
INSERT INTO `t_partner_member` VALUES (240097, 81378004, 743811, 285541, 0);
INSERT INTO `t_partner_member` VALUES (240099, 81378004, 468083, 780508, 0);
INSERT INTO `t_partner_member` VALUES (240101, 68057792, 841507, 0, 0);
INSERT INTO `t_partner_member` VALUES (240103, 81378004, 152426, 780508, 0);
INSERT INTO `t_partner_member` VALUES (240105, 88603133, 546824, 0, 0);
INSERT INTO `t_partner_member` VALUES (240107, 88603133, 280773, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240109, 88603133, 552276, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240111, 88603133, 387979, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240113, 88603133, 573589, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240115, 81378004, 841251, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240117, 81378004, 493732, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240119, 81378004, 444185, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240121, 81378004, 905173, 684573, 0);
INSERT INTO `t_partner_member` VALUES (240123, 81378004, 176516, 753973, 0);
INSERT INTO `t_partner_member` VALUES (240125, 81378004, 600332, 753973, 0);
INSERT INTO `t_partner_member` VALUES (240127, 81378004, 618763, 753973, 0);
INSERT INTO `t_partner_member` VALUES (240129, 81378004, 364602, 753973, 0);
INSERT INTO `t_partner_member` VALUES (240131, 81378004, 200558, 753973, 0);
INSERT INTO `t_partner_member` VALUES (240133, 81378004, 659532, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240135, 81378004, 439596, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240137, 81378004, 571057, 701579, 0);
INSERT INTO `t_partner_member` VALUES (240139, 88603133, 808009, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240141, 88603133, 743811, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240143, 88603133, 152426, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240145, 88603133, 780508, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240147, 88603133, 538628, 546824, 0);
INSERT INTO `t_partner_member` VALUES (240149, 88603133, 618763, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240151, 88603133, 176516, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240153, 88603133, 841251, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240155, 88603133, 600332, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240157, 85665832, 661060, 365220, 0);
INSERT INTO `t_partner_member` VALUES (240163, 85665832, 852949, 365220, 0);
INSERT INTO `t_partner_member` VALUES (240165, 85665832, 316760, 365220, 0);
INSERT INTO `t_partner_member` VALUES (240171, 88603133, 140279, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240175, 88603133, 218751, 552276, 0);
INSERT INTO `t_partner_member` VALUES (240179, 690812, 838031, 0, 0);
INSERT INTO `t_partner_member` VALUES (240187, 690812, 444507, 838031, 0);
INSERT INTO `t_partner_member` VALUES (240189, 69793347, 316818, 998317, 0);
INSERT INTO `t_partner_member` VALUES (240191, 67262628, 553184, 0, 0);
INSERT INTO `t_partner_member` VALUES (240193, 67262628, 415909, 553184, 0);
INSERT INTO `t_partner_member` VALUES (240195, 67262628, 851492, 415909, 0);
INSERT INTO `t_partner_member` VALUES (240197, 67262628, 160142, 415909, 0);
INSERT INTO `t_partner_member` VALUES (240199, 69081204, 271686, 0, 0);
INSERT INTO `t_partner_member` VALUES (240201, 69081204, 254139, 271686, 0);
INSERT INTO `t_partner_member` VALUES (240203, 69081204, 617849, 254139, 0);
INSERT INTO `t_partner_member` VALUES (240205, 69081204, 345846, 254139, 0);
INSERT INTO `t_partner_member` VALUES (240207, 67262628, 271686, 415909, 0);
INSERT INTO `t_partner_member` VALUES (240209, 67262628, 326092, 160142, 0);
INSERT INTO `t_partner_member` VALUES (240211, 67262628, 617849, 326092, 0);
INSERT INTO `t_partner_member` VALUES (240213, 67262628, 918682, 617849, 0);
INSERT INTO `t_partner_member` VALUES (240215, 67262628, 119700, 415909, 0);
INSERT INTO `t_partner_member` VALUES (240217, 67262628, 448518, 415909, 0);
INSERT INTO `t_partner_member` VALUES (240219, 67262628, 338663, 553184, 0);
INSERT INTO `t_partner_member` VALUES (240221, 67262628, 361607, 553184, 0);
INSERT INTO `t_partner_member` VALUES (240223, 67262628, 187666, 553184, 0);
INSERT INTO `t_partner_member` VALUES (240225, 67262628, 651402, 553184, 0);
INSERT INTO `t_partner_member` VALUES (240227, 67262628, 587423, 326092, 0);
INSERT INTO `t_partner_member` VALUES (240229, 67262628, 551000, 851492, 0);
INSERT INTO `t_partner_member` VALUES (240231, 67262628, 767947, 338663, 0);
INSERT INTO `t_partner_member` VALUES (240233, 85389915, 468842, 0, 0);
INSERT INTO `t_partner_member` VALUES (240235, 85389915, 123187, 468842, 0);
INSERT INTO `t_partner_member` VALUES (240241, 63080376, 784411, 0, 0);
INSERT INTO `t_partner_member` VALUES (240243, 63080376, 969335, 784411, 0);
INSERT INTO `t_partner_member` VALUES (240245, 69760170, 784411, 0, 0);
INSERT INTO `t_partner_member` VALUES (240247, 64793141, 700139, 0, 0);
INSERT INTO `t_partner_member` VALUES (240249, 64793141, 374654, 700139, 0);
INSERT INTO `t_partner_member` VALUES (240251, 64793141, 999386, 374654, 0);
INSERT INTO `t_partner_member` VALUES (240253, 64793141, 361304, 999386, 0);
INSERT INTO `t_partner_member` VALUES (240255, 64793141, 293188, 361304, 0);
INSERT INTO `t_partner_member` VALUES (240257, 88603133, 800545, 387979, 0);
INSERT INTO `t_partner_member` VALUES (240259, 88603133, 828113, 800545, 0);
INSERT INTO `t_partner_member` VALUES (240261, 60320931, 838031, 0, 0);
INSERT INTO `t_partner_member` VALUES (240263, 60320931, 904998, 838031, 0);
INSERT INTO `t_partner_member` VALUES (240265, 60320931, 686627, 904998, 0);
INSERT INTO `t_partner_member` VALUES (240267, 60320931, 907284, 686627, 0);
INSERT INTO `t_partner_member` VALUES (240269, 60320931, 444507, 907284, 0);
INSERT INTO `t_partner_member` VALUES (240271, 85389915, 349020, 468842, 0);
INSERT INTO `t_partner_member` VALUES (240273, 85389915, 617849, 468842, 0);
INSERT INTO `t_partner_member` VALUES (240275, 66219171, 130200, 0, 0);
INSERT INTO `t_partner_member` VALUES (240277, 66219171, 223429, 130200, 0);
INSERT INTO `t_partner_member` VALUES (240279, 66219171, 453372, 130200, 0);
INSERT INTO `t_partner_member` VALUES (240281, 66219171, 713117, 130200, 0);
INSERT INTO `t_partner_member` VALUES (240283, 66219171, 433185, 130200, 0);
INSERT INTO `t_partner_member` VALUES (240285, 66219171, 548694, 223429, 0);
INSERT INTO `t_partner_member` VALUES (240287, 68705185, 838031, 0, 0);
INSERT INTO `t_partner_member` VALUES (240289, 60320931, 444185, 838031, 0);
INSERT INTO `t_partner_member` VALUES (240291, 60320931, 678070, 838031, 0);
INSERT INTO `t_partner_member` VALUES (240293, 85389915, 745754, 468842, 0);
INSERT INTO `t_partner_member` VALUES (240295, 85389915, 904998, 468842, 0);
INSERT INTO `t_partner_member` VALUES (240297, 85389915, 742950, 123187, 0);
INSERT INTO `t_partner_member` VALUES (240299, 85389915, 552045, 468842, 0);
INSERT INTO `t_partner_member` VALUES (240301, 85389915, 627003, 468842, 0);

-- ----------------------------
-- Table structure for t_player
-- ----------------------------
DROP TABLE IF EXISTS `t_player`;
CREATE TABLE `t_player`  (
  `guid` int(8) NOT NULL COMMENT '全局唯一标识符',
  `is_android` int(1) NOT NULL DEFAULT 0 COMMENT '是机器人',
  `account` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '账号',
  `nickname` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '昵称',
  `level` int(1) NOT NULL DEFAULT 0 COMMENT '玩家等级',
  `head_url` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0' COMMENT '头像',
  `phone` char(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '手机号',
  `phone_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '手机类型',
  `union_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '微信union_id',
  `platform_id` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '0' COMMENT '平台id',
  `vip` tinyint(1) NULL DEFAULT NULL,
  `status` tinyint(1) NULL DEFAULT 1 COMMENT '是否可用 1可用 0封号',
  `promoter` int(8) NULL DEFAULT NULL,
  `channel_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `created_time` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`guid`) USING BTREE,
  INDEX `idx_guid_createtime`(`guid`, `created_time`, `promoter`, `channel_id`) USING BTREE,
  INDEX `idx_guid`(`guid`) USING BTREE,
  INDEX `idx_time`(`created_time`) USING BTREE,
  INDEX `idx_status`(`status`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '玩家表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_player
-- ----------------------------
INSERT INTO `t_player` VALUES (101021, 0, '188281', 'guest_101021', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:12:42');
INSERT INTO `t_player` VALUES (105718, 0, 'guest_454224', 'guest_105718', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-31 22:02:09');
INSERT INTO `t_player` VALUES (110018, 0, '252288', 'guest_110018', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-15 20:46:24');
INSERT INTO `t_player` VALUES (110044, 0, '156309', 'guest_110044', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 12:29:40');
INSERT INTO `t_player` VALUES (111351, 0, '54095', 'guest_111351', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 21:21:45');
INSERT INTO `t_player` VALUES (113465, 0, 'vic008', 'guest_113465', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-10 18:05:41');
INSERT INTO `t_player` VALUES (115348, 0, '591454', 'guest_115348', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:47:12');
INSERT INTO `t_player` VALUES (118403, 0, '715106', 'guest_118403', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 16:56:04');
INSERT INTO `t_player` VALUES (119700, 0, '6755656', 'guest_119700', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:13:47');
INSERT INTO `t_player` VALUES (124918, 0, '17781', 'guest_124918', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 18:44:59');
INSERT INTO `t_player` VALUES (125746, 0, 'lili05', 'guest_125746', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-18 14:59:02');
INSERT INTO `t_player` VALUES (126821, 0, '524838', 'guest_126821', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-23 15:39:58');
INSERT INTO `t_player` VALUES (128440, 0, '665345', 'guest_128440', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 17:54:08');
INSERT INTO `t_player` VALUES (130200, 0, 'qs01', 'qs01', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:18:40');
INSERT INTO `t_player` VALUES (134405, 0, '103982', 'guest_134405', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:34:55');
INSERT INTO `t_player` VALUES (135856, 0, '118010', 'guest_135856', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:13:31');
INSERT INTO `t_player` VALUES (136998, 0, '523516', 'guest_136998', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:45:15');
INSERT INTO `t_player` VALUES (137524, 0, '552779', 'guest_137524', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 22:00:42');
INSERT INTO `t_player` VALUES (137556, 0, '468842', 'guest_137556', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-16 20:45:33');
INSERT INTO `t_player` VALUES (137913, 0, 'c6f8247cc8992a83a7e91a5ae7c1e06224ed83e8', '阿奇去去去', 0, '', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-07-04 17:46:01');
INSERT INTO `t_player` VALUES (138120, 0, '872626', 'guest_138120', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:36:01');
INSERT INTO `t_player` VALUES (138183, 0, '28070', 'guest_138183', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-02 19:03:12');
INSERT INTO `t_player` VALUES (139322, 0, '951bc02aee409aa458cae4301e4881cfe7e2d9ed', 'guest_139322', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-04 21:19:47');
INSERT INTO `t_player` VALUES (139340, 0, '1323b01e19ccb8a00b0427aa18da98defb5594b1', 'guest_139340', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-16 12:48:29');
INSERT INTO `t_player` VALUES (139358, 0, '722931', 'guest_139358', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 10:42:14');
INSERT INTO `t_player` VALUES (139847, 0, '553699', 'guest_139847', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-08 21:05:35');
INSERT INTO `t_player` VALUES (140279, 0, 'lili008', 'guest_140279', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-19 16:29:31');
INSERT INTO `t_player` VALUES (141793, 0, '37321', 'guest_141793', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-02 15:45:08');
INSERT INTO `t_player` VALUES (142183, 0, '540696', 'guest_142183', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:31:35');
INSERT INTO `t_player` VALUES (145719, 0, '370406', 'guest_145719', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-04 10:43:28');
INSERT INTO `t_player` VALUES (146448, 0, '980018', 'guest_146448', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 11:55:19');
INSERT INTO `t_player` VALUES (151892, 0, '504443', 'guest_151892', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 16:49:43');
INSERT INTO `t_player` VALUES (152426, 0, 'caiqing005', '005_152426', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:40:43');
INSERT INTO `t_player` VALUES (154400, 0, '204688', 'guest_154400', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:20:26');
INSERT INTO `t_player` VALUES (155456, 0, '188874', 'guest_155456', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 20:46:58');
INSERT INTO `t_player` VALUES (156800, 0, '490905', 'guest_156800', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-26 18:53:00');
INSERT INTO `t_player` VALUES (157087, 0, '228292', 'guest_157087', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:54:18');
INSERT INTO `t_player` VALUES (157190, 0, '270655', 'guest_157190', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-29 10:42:55');
INSERT INTO `t_player` VALUES (158962, 0, '59114', 'guest_158962', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 21:56:46');
INSERT INTO `t_player` VALUES (160142, 0, '2321323', 'guest_160142', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '18510003001', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:26:51');
INSERT INTO `t_player` VALUES (164158, 0, '389389', 'guest_164158', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-04 12:18:08');
INSERT INTO `t_player` VALUES (168663, 0, 'vvvv', 'guest_168663', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 22:09:33');
INSERT INTO `t_player` VALUES (172846, 0, '393454', 'guest_172846', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 13:02:24');
INSERT INTO `t_player` VALUES (173513, 0, '210033', 'guest_173513', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:30:47');
INSERT INTO `t_player` VALUES (173724, 0, '150526', 'guest_173724', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-05 23:11:38');
INSERT INTO `t_player` VALUES (174748, 0, '465034', 'guest_174748', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:06:14');
INSERT INTO `t_player` VALUES (175501, 0, 'caiqng002', 'guest_175501', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-02 20:36:35');
INSERT INTO `t_player` VALUES (176516, 0, 'caiqing006', '006_176516', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:41:06');
INSERT INTO `t_player` VALUES (177441, 0, '674594', 'guest_177441', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:30:25');
INSERT INTO `t_player` VALUES (179621, 0, '837316', 'guest_179621', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-26 18:43:44');
INSERT INTO `t_player` VALUES (181479, 0, '858487', 'guest_181479', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-03 20:10:04');
INSERT INTO `t_player` VALUES (182233, 0, '380019', 'guest_182233', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 20:14:16');
INSERT INTO `t_player` VALUES (184111, 0, '929233', 'guest_184111', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:24:16');
INSERT INTO `t_player` VALUES (185502, 0, 'fafa11', 'guest_185502', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 15:11:28');
INSERT INTO `t_player` VALUES (187666, 0, '2131231313', 'guest_187666', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:18:39');
INSERT INTO `t_player` VALUES (189243, 0, '401257', 'guest_189243', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 12:21:45');
INSERT INTO `t_player` VALUES (198191, 0, '254329', 'guest_198191', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 12:33:10');
INSERT INTO `t_player` VALUES (200558, 0, 'caiqing011', '011_200558', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-09 10:40:10');
INSERT INTO `t_player` VALUES (203700, 0, '194735', 'guest_203700', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 16:49:01');
INSERT INTO `t_player` VALUES (206489, 0, '810943', 'guest_206489', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-02 10:55:54');
INSERT INTO `t_player` VALUES (210795, 0, 'sz001', 'guest_210795', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 18:22:03');
INSERT INTO `t_player` VALUES (211389, 0, '644753', 'guest_211389', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-27 17:39:51');
INSERT INTO `t_player` VALUES (211922, 0, '145461', 'guest_211922', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:38:54');
INSERT INTO `t_player` VALUES (212344, 0, '74290', 'guest_212344', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:40:46');
INSERT INTO `t_player` VALUES (214356, 0, '90618', 'guest_214356', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:13:48');
INSERT INTO `t_player` VALUES (215284, 0, '433399', 'guest_215284', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 17:40:40');
INSERT INTO `t_player` VALUES (215290, 0, '178063', 'guest_215290', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:33:53');
INSERT INTO `t_player` VALUES (216253, 0, '851492', 'guest_216253', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:25:04');
INSERT INTO `t_player` VALUES (216294, 0, 'qqqq1', 'guest_216294', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-03 16:43:58');
INSERT INTO `t_player` VALUES (216882, 0, '136205', 'guest_216882', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 20:52:58');
INSERT INTO `t_player` VALUES (218751, 0, 'lili009', 'guest_218751', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-19 16:32:13');
INSERT INTO `t_player` VALUES (220092, 0, '308397', 'guest_220092', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 22:02:01');
INSERT INTO `t_player` VALUES (223429, 0, 'qs02', 'qs02', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:21:23');
INSERT INTO `t_player` VALUES (225581, 0, '420659', 'guest_225581', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 18:37:15');
INSERT INTO `t_player` VALUES (228098, 0, '185057', 'guest_228098', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-01 15:43:14');
INSERT INTO `t_player` VALUES (228620, 0, '737963', 'guest_228620', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:01:53');
INSERT INTO `t_player` VALUES (228794, 0, 'c15797f687b077c5743e7ee9f0c191746ee9a954', 'guest_228794', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-31 10:41:21');
INSERT INTO `t_player` VALUES (232495, 0, 'caqing002', '002_232495', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 18:08:14');
INSERT INTO `t_player` VALUES (232523, 0, '369065', 'guest_232523', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 17:45:51');
INSERT INTO `t_player` VALUES (234923, 0, 'fat666', 'guest_234923', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-18 20:42:00');
INSERT INTO `t_player` VALUES (236076, 0, '699648', 'guest_236076', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-12 09:16:34');
INSERT INTO `t_player` VALUES (244136, 0, '617849', 'guest_244136', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-16 20:45:50');
INSERT INTO `t_player` VALUES (244374, 0, '257741', 'guest_244374', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-26 18:21:57');
INSERT INTO `t_player` VALUES (244423, 0, '408052', 'guest_244423', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-12 17:04:38');
INSERT INTO `t_player` VALUES (249560, 0, '59324', 'guest_249560', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 17:54:28');
INSERT INTO `t_player` VALUES (254139, 0, '858589', 'guest_254139', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:34:29');
INSERT INTO `t_player` VALUES (254329, 0, '993597', '993597_254329', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 11:23:55');
INSERT INTO `t_player` VALUES (255411, 0, '828778', 'guest_255411', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-08 12:02:05');
INSERT INTO `t_player` VALUES (255744, 0, '998689', 'guest_255744', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 17:49:35');
INSERT INTO `t_player` VALUES (264616, 0, '461921', 'guest_264616', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-03 12:29:51');
INSERT INTO `t_player` VALUES (264763, 0, '855072', 'guest_264763', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 21:42:54');
INSERT INTO `t_player` VALUES (266472, 0, '425371', 'guest_266472', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-10-15 12:38:32');
INSERT INTO `t_player` VALUES (266909, 0, '310789', 'guest_266909', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:10:46');
INSERT INTO `t_player` VALUES (269088, 0, 'zhangqing001', 'guest_269088', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-13 10:29:00');
INSERT INTO `t_player` VALUES (270827, 0, '542973', 'caiqing110', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 11:19:50');
INSERT INTO `t_player` VALUES (271686, 0, '98989', 'guest_271686', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:32:58');
INSERT INTO `t_player` VALUES (278383, 0, 'bc2da19da2bc4075a3cc630fc19229c2ad4af94f', 'xiaoer_nb777', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/J7icgYrfcKJ3e8A1pZib8iabTnMbon2iaSMIXtjFxejd7ed1YibBoHAld5L6soPjzhwJp1P5m5bE4aaVsbONAnqISzg/132', '', 'Android', 'ompjp1BcBSqziv_6zdOoEpEuoH8k', '0', NULL, 1, NULL, '', '2022-06-02 10:03:05');
INSERT INTO `t_player` VALUES (280773, 0, 'lili002', 'guest_280773', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-05 20:55:05');
INSERT INTO `t_player` VALUES (281730, 0, '459926', 'guest_281730', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 22:16:06');
INSERT INTO `t_player` VALUES (283635, 0, '29b2b8aca0f397652ae8514287fb4a5a0f5fdcdd', 'guest_283635', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-01 21:07:26');
INSERT INTO `t_player` VALUES (285541, 0, 'vic003', 'vic003', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 10:26:59');
INSERT INTO `t_player` VALUES (286022, 0, '876010', 'guest_286022', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-07 22:41:35');
INSERT INTO `t_player` VALUES (287126, 0, '641635', 'guest_287126', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:20:40');
INSERT INTO `t_player` VALUES (287169, 0, '775679', 'guest_287169', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 12:30:05');
INSERT INTO `t_player` VALUES (287763, 0, '692988', 'guest_287763', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 18:33:30');
INSERT INTO `t_player` VALUES (288904, 0, '396527', 'guest_288904', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-04 20:20:09');
INSERT INTO `t_player` VALUES (289401, 0, '176979', 'guest_289401', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-03 23:51:40');
INSERT INTO `t_player` VALUES (291650, 0, '663711', 'guest_291650', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 11:55:32');
INSERT INTO `t_player` VALUES (292011, 0, '737724', 'guest_292011', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 15:44:38');
INSERT INTO `t_player` VALUES (293188, 0, '98998', 'guest_293188', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 21:09:34');
INSERT INTO `t_player` VALUES (294236, 0, '98301', 'guest_294236', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-02 17:46:17');
INSERT INTO `t_player` VALUES (294382, 0, 'e0a50f3774b36a562352149c0d640afcf4021b96', 'guest_294382', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 15:18:27');
INSERT INTO `t_player` VALUES (300530, 0, '312615', 'guest_300530', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 12:50:44');
INSERT INTO `t_player` VALUES (302904, 0, '415181', 'guest_302904', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-10-14 10:54:45');
INSERT INTO `t_player` VALUES (304343, 0, '198060', 'guest_304343', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:13:13');
INSERT INTO `t_player` VALUES (305786, 0, '641767', 'guest_305786', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-05 20:50:15');
INSERT INTO `t_player` VALUES (306970, 0, '654930', 'guest_306970', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-11 21:25:57');
INSERT INTO `t_player` VALUES (308820, 0, 'vinc001', 'guest_308820', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:24:02');
INSERT INTO `t_player` VALUES (310566, 0, '269360', 'guest_310566', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:20:52');
INSERT INTO `t_player` VALUES (310797, 0, '354748', 'guest_310797', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 11:51:45');
INSERT INTO `t_player` VALUES (313594, 0, '338106', 'guest_313594', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-02 19:03:13');
INSERT INTO `t_player` VALUES (313700, 0, '397885', 'guest_313700', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-25 21:30:27');
INSERT INTO `t_player` VALUES (315572, 0, '867980', 'guest_315572', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 17:16:10');
INSERT INTO `t_player` VALUES (316760, 0, 'rong003', 'rong003', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-09 11:09:55');
INSERT INTO `t_player` VALUES (316841, 0, '881238', 'guest_316841', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-12 09:15:54');
INSERT INTO `t_player` VALUES (321641, 0, '636573', 'guest_321641', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:11:49');
INSERT INTO `t_player` VALUES (322758, 0, '165526', 'guest_322758', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-28 11:10:51');
INSERT INTO `t_player` VALUES (325649, 0, '619134', 'guest_325649', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-03 23:47:02');
INSERT INTO `t_player` VALUES (325726, 0, 'khhh', 'guest_325726', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-08 17:18:46');
INSERT INTO `t_player` VALUES (326092, 0, '211212', 'guest_326092', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:57:54');
INSERT INTO `t_player` VALUES (326224, 0, 'caiqng009', 'guest_326224', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-25 00:01:37');
INSERT INTO `t_player` VALUES (329643, 0, '771677', 'guest_329643', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 17:12:37');
INSERT INTO `t_player` VALUES (330952, 0, '671588', 'guest_330952', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-25 21:30:27');
INSERT INTO `t_player` VALUES (334831, 0, '608947', 'guest_334831', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:39:20');
INSERT INTO `t_player` VALUES (336015, 0, '376322', 'guest_336015', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-29 12:34:06');
INSERT INTO `t_player` VALUES (338663, 0, '9832323', 'guest_338663', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:17:04');
INSERT INTO `t_player` VALUES (343271, 0, '362550', 'guest_343271', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-18 18:00:06');
INSERT INTO `t_player` VALUES (345846, 0, '23131312', 'guest_345846', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:36:35');
INSERT INTO `t_player` VALUES (346248, 0, ' rong004', 'rong004', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-23 18:24:43');
INSERT INTO `t_player` VALUES (348580, 0, '705340', 'guest_348580', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-04 10:41:59');
INSERT INTO `t_player` VALUES (349020, 0, '21213333', 'guest_349020', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-24 16:24:55');
INSERT INTO `t_player` VALUES (350108, 0, '893968', 'guest_350108', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-02 17:55:50');
INSERT INTO `t_player` VALUES (351990, 0, '916166', 'guest_351990', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-08 18:29:15');
INSERT INTO `t_player` VALUES (356115, 0, '828309', 'guest_356115', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-11 12:31:46');
INSERT INTO `t_player` VALUES (357268, 0, '104805', 'guest_357268', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-27 12:30:48');
INSERT INTO `t_player` VALUES (358330, 0, '500001', 'guest_358330', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:48:22');
INSERT INTO `t_player` VALUES (361304, 0, '0323', 'guest_361304', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 21:08:44');
INSERT INTO `t_player` VALUES (361607, 0, '231232131232', 'guest_361607', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:18:01');
INSERT INTO `t_player` VALUES (361690, 0, '931636', 'guest_361690', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-05 18:12:43');
INSERT INTO `t_player` VALUES (364122, 0, '999051', 'guest_364122', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 12:21:41');
INSERT INTO `t_player` VALUES (364271, 0, '151838', 'guest_364271', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-07 15:38:16');
INSERT INTO `t_player` VALUES (364602, 0, 'caiqing010', '010_364602', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:54:08');
INSERT INTO `t_player` VALUES (365220, 0, 'rong001', 'rong001', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 15:18:13');
INSERT INTO `t_player` VALUES (365880, 0, '281954', 'guest_365880', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 13:01:38');
INSERT INTO `t_player` VALUES (366676, 0, '461921', 'guest_366676', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:16:33');
INSERT INTO `t_player` VALUES (372031, 0, '431048', 'guest_372031', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 17:57:59');
INSERT INTO `t_player` VALUES (372767, 0, 'test002', 't002_372767', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 12:42:44');
INSERT INTO `t_player` VALUES (373339, 0, '812039', 'guest_373339', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:19:37');
INSERT INTO `t_player` VALUES (373475, 0, '434540', 'guest_373475', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-27 20:57:09');
INSERT INTO `t_player` VALUES (374004, 0, '665229', 'guest_374004', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 12:53:08');
INSERT INTO `t_player` VALUES (374654, 0, '2121213', 'guest_374654', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 21:06:36');
INSERT INTO `t_player` VALUES (379327, 0, 'vic006', 'guest_379327', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-30 17:39:21');
INSERT INTO `t_player` VALUES (380441, 0, 'b381c9956d4bdb86ac53771fed4b5629aa2ea189', '哈撒给', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/j5IEQtaEaPdpH3VjWWnbwzg7ZBrTBltt64TlIDYZZVhgKyh4cl63qiaxQD161tcQURm1ia7NUQ6PvWScHnOM3Ltw/132', NULL, 'Android', 'ompjp1EEyl7VwpM4Ms4sYW6Flk9E', '0', NULL, 1, NULL, '', '2021-12-23 06:13:55');
INSERT INTO `t_player` VALUES (380450, 0, '468398', 'guest_380450', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-02 22:08:35');
INSERT INTO `t_player` VALUES (380926, 0, '939202', 'guest_380926', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', 1, 1, NULL, '', '2022-06-22 21:02:46');
INSERT INTO `t_player` VALUES (381247, 0, '473659', 'guest_381247', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 12:52:16');
INSERT INTO `t_player` VALUES (382611, 0, '69961', 'guest_382611', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 20:17:46');
INSERT INTO `t_player` VALUES (383072, 0, '849481', 'guest_383072', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 12:39:54');
INSERT INTO `t_player` VALUES (383251, 0, '956665', 'guest_383251', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 20:11:53');
INSERT INTO `t_player` VALUES (387869, 0, '285939', 'guest_387869', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-12 16:21:14');
INSERT INTO `t_player` VALUES (387979, 0, 'lili004', 'guest_387979', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-05 20:56:15');
INSERT INTO `t_player` VALUES (389967, 0, '852963', 'guest_389ffa967', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 10:37:56');
INSERT INTO `t_player` VALUES (390502, 0, '408215', 'guest_390502', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-10 16:21:26');
INSERT INTO `t_player` VALUES (390839, 0, 'lili666', 'guest_390839', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 21:26:44');
INSERT INTO `t_player` VALUES (391682, 0, '265501', 'guest_391682', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-31 15:15:28');
INSERT INTO `t_player` VALUES (392024, 0, '601862', 'guest_392024', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 20:04:57');
INSERT INTO `t_player` VALUES (392545, 0, '198453', 'guest_392545', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 21:42:38');
INSERT INTO `t_player` VALUES (392554, 0, '664773', 'guest_392554', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 11:48:39');
INSERT INTO `t_player` VALUES (399394, 0, 'sixgod008', 'guest_399394', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-16 12:46:03');
INSERT INTO `t_player` VALUES (400276, 0, '00c77f1cd9f059f0fe33cf564c2f2d96a3ecba53', '阿奇去去去', 0, '', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-06-26 01:35:16');
INSERT INTO `t_player` VALUES (402755, 0, '591312', 'guest_402755', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-29 21:27:01');
INSERT INTO `t_player` VALUES (403857, 0, '419634', 'guest_403857', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:52:09');
INSERT INTO `t_player` VALUES (407558, 0, '475648', 'guest_407558', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-28 16:02:42');
INSERT INTO `t_player` VALUES (409024, 0, 'f4e087ca38b06ecf473efaf877cdb4a83e586684', '阿奇去去去', 0, '', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-07-04 17:42:12');
INSERT INTO `t_player` VALUES (409361, 0, '714316', 'guest_409361', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-05 20:55:25');
INSERT INTO `t_player` VALUES (412652, 0, '425782', 'guest_412652', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 14:13:39');
INSERT INTO `t_player` VALUES (413123, 0, '91491c35e09149d8fda8885d1198c09ce91afe52', 'guest_413123', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-02 10:55:17');
INSERT INTO `t_player` VALUES (414948, 0, '268113', 'guest_414948', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-27 17:23:05');
INSERT INTO `t_player` VALUES (415909, 0, 'fa8001', 'guest_415909', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:00:38');
INSERT INTO `t_player` VALUES (416961, 0, '568863', 'guest_416961', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-07 23:01:26');
INSERT INTO `t_player` VALUES (420478, 0, '736466', 'guest_420478', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-04 10:49:28');
INSERT INTO `t_player` VALUES (420682, 0, '96239', 'guest_420682', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 16:47:24');
INSERT INTO `t_player` VALUES (421492, 0, '650492', 'guest_421492', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 17:59:17');
INSERT INTO `t_player` VALUES (422366, 0, '122121', 'guest_422366', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-10 16:05:29');
INSERT INTO `t_player` VALUES (422575, 0, '361147', 'guest_422575', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 20:31:55');
INSERT INTO `t_player` VALUES (423679, 0, '5853c267530cae44366ba2fce0fa5ab86999abbd', 'guest_423679', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-28 11:48:13');
INSERT INTO `t_player` VALUES (426115, 0, '434065', 'guest_426115', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 12:21:44');
INSERT INTO `t_player` VALUES (430526, 0, '373797', 'guest_430526', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 16:46:23');
INSERT INTO `t_player` VALUES (432125, 0, '716390', 'guest_432125', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 12:30:20');
INSERT INTO `t_player` VALUES (433185, 0, 'qs05', 'qs05', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:22:40');
INSERT INTO `t_player` VALUES (433205, 0, '595580', 'guest_433205', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-29 16:04:02');
INSERT INTO `t_player` VALUES (436730, 0, '141667', 'guest_436730', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 15:58:46');
INSERT INTO `t_player` VALUES (437358, 0, '616771', 'guest_437358', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:23:10');
INSERT INTO `t_player` VALUES (438109, 0, '695249', 'guest_438109', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-19 12:33:54');
INSERT INTO `t_player` VALUES (439596, 0, 'lz002', 'guest_439596', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-27 12:42:55');
INSERT INTO `t_player` VALUES (441423, 0, '588746', 'guest_441423', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 15:42:56');
INSERT INTO `t_player` VALUES (441697, 0, '123123123ccc', 'guest_441697', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-25 21:43:11');
INSERT INTO `t_player` VALUES (441871, 0, '342430', 'guest_441871', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-05 18:19:30');
INSERT INTO `t_player` VALUES (441897, 0, '776045', 'guest_441897', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-28 12:59:06');
INSERT INTO `t_player` VALUES (443589, 0, '6876d6030ff8d863d4317bdfb255bff9543a947a', 'guest_443589', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-12 17:45:14');
INSERT INTO `t_player` VALUES (443619, 0, '504976', 'guest_443619', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 13:07:55');
INSERT INTO `t_player` VALUES (444185, 0, 'lz111', 'guest_444185', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-28 10:33:12');
INSERT INTO `t_player` VALUES (444507, 0, 'vip005', 'vip005', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 18:09:51');
INSERT INTO `t_player` VALUES (444689, 0, '168831', 'guest_444689', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:23:34');
INSERT INTO `t_player` VALUES (448518, 0, '656546546', 'guest_448518', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:14:31');
INSERT INTO `t_player` VALUES (450260, 0, '992cce2a95ef18f34ba8272c7c255feb6aa52362', '天涯', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q3auHgzwzM5wumjTxXXkK63ibsZ3UK5Gkibibicibtp6Kqc42ibB4fxR0nlmIjNaBqztqjRb9s0LwL1yGOumpRY91hSJG38ibdeqquf/132', '', 'Android', 'ompjp1HpPKqnRZlU1RpgUNmnyS10', '0', NULL, 1, NULL, '', '2022-07-22 12:07:18');
INSERT INTO `t_player` VALUES (450392, 0, 'vip', 'guest_450392', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-02 16:55:02');
INSERT INTO `t_player` VALUES (451733, 0, '405388', 'guest_451733', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-13 17:42:00');
INSERT INTO `t_player` VALUES (452483, 0, 'a2979d7894d17bbd5346746d6778a214177d2e7b', 'guest_452483', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-20 20:07:44');
INSERT INTO `t_player` VALUES (453372, 0, 'qs03', 'qs03', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:21:51');
INSERT INTO `t_player` VALUES (454224, 0, 'sixgod001', 'guest_454224', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 18:22:37');
INSERT INTO `t_player` VALUES (456551, 0, '954617', 'guest_456551', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 18:49:03');
INSERT INTO `t_player` VALUES (456918, 0, 'flyfat', 'guest_456918', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 21:15:47');
INSERT INTO `t_player` VALUES (457010, 0, '327439', 'guest_457010', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 18:44:24');
INSERT INTO `t_player` VALUES (460507, 0, '804733', 'guest_460507', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-27 16:22:54');
INSERT INTO `t_player` VALUES (462354, 0, '898555', 'guest_462354', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 22:16:34');
INSERT INTO `t_player` VALUES (464371, 0, '551871', 'guest_464371', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-13 10:19:04');
INSERT INTO `t_player` VALUES (464425, 0, '698296', 'guest_464425', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-29 20:25:23');
INSERT INTO `t_player` VALUES (466171, 0, 'b09b1ecd235b0841c57ae4205daa55e917251379', 'guest_466171', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-18 20:39:22');
INSERT INTO `t_player` VALUES (466835, 0, '232979', 'guest_466835', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 21:01:22');
INSERT INTO `t_player` VALUES (468083, 0, 'caiqing110', 'caiqing110', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-20 17:28:05');
INSERT INTO `t_player` VALUES (468842, 0, '90a3fdb971947dd75c1eb6509a40b84404ac1fa4', '阿奇去去去', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q3auHgzwzM7nbcKYQct8icVnsqTt7hR5ExYTM9saOa6ca9CcfltUhvg8rxAaj7ynl8z4Dj3kzemt1HukGCABn80YmGaOEOxPm/132', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-12-17 22:14:19');
INSERT INTO `t_player` VALUES (470005, 0, '766279', 'guest_470005', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 21:49:50');
INSERT INTO `t_player` VALUES (471472, 0, '930361', 'guest_471472', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:10:52');
INSERT INTO `t_player` VALUES (471758, 0, '163138', 'guest_471758', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-19 13:14:18');
INSERT INTO `t_player` VALUES (471763, 0, '911239', 'guest_471763', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:21:30');
INSERT INTO `t_player` VALUES (477990, 0, '957186', 'guest_477990', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 11:19:47');
INSERT INTO `t_player` VALUES (478963, 0, 'lz555', 'guest_478963', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 17:20:38');
INSERT INTO `t_player` VALUES (480657, 0, '545706', 'guest_480657', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:07:42');
INSERT INTO `t_player` VALUES (486359, 0, '489554', 'guest_486359', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 10:10:06');
INSERT INTO `t_player` VALUES (492105, 0, '576220', 'guest_492105', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 18:13:33');
INSERT INTO `t_player` VALUES (493535, 0, '371877', 'guest_493535', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-10-14 10:55:55');
INSERT INTO `t_player` VALUES (493606, 0, '51655', 'guest_493606', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-11 12:52:23');
INSERT INTO `t_player` VALUES (493732, 0, '672046', 'guest_493732', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 22:52:40');
INSERT INTO `t_player` VALUES (500943, 0, '129166', 'guest_500943', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:24:00');
INSERT INTO `t_player` VALUES (503009, 0, '286038', 'guest_503009', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 17:42:59');
INSERT INTO `t_player` VALUES (503224, 0, '507046', 'guest_503224', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 10:32:56');
INSERT INTO `t_player` VALUES (503419, 0, '648954', 'guest_503419', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 21:57:15');
INSERT INTO `t_player` VALUES (505930, 0, '641053', 'guest_505930', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-03 16:26:56');
INSERT INTO `t_player` VALUES (506824, 0, '369065', 'guest_506824', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', 0, 1, NULL, '', '2022-06-04 10:32:26');
INSERT INTO `t_player` VALUES (507126, 0, 'f3d7616a193d77cbec10de5bfd824367d4d081ae', 'guest_507126', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-23 21:08:04');
INSERT INTO `t_player` VALUES (511985, 0, '343948', 'guest_511985', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 11:13:05');
INSERT INTO `t_player` VALUES (513587, 0, '您好，欢迎咨询在线人工客服！！！         请问 咨询什么问题啦？', 'guest_513587', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:53:36');
INSERT INTO `t_player` VALUES (513603, 0, '478241', 'guest_513603', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-05 22:08:35');
INSERT INTO `t_player` VALUES (516748, 0, '747112', 'guest_516748', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 23:21:13');
INSERT INTO `t_player` VALUES (520685, 0, '随机ID', 'guest_520685', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:33:10');
INSERT INTO `t_player` VALUES (521473, 0, 'cccc', 'guest_521473', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 12:46:51');
INSERT INTO `t_player` VALUES (521588, 0, '418605', 'guest_521588', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 07:59:46');
INSERT INTO `t_player` VALUES (522459, 0, '942305', 'guest_522459', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 21:07:43');
INSERT INTO `t_player` VALUES (525382, 0, '521564', 'guest_525382', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-25 12:44:59');
INSERT INTO `t_player` VALUES (525655, 0, '541267', 'guest_525655', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:11:08');
INSERT INTO `t_player` VALUES (528387, 0, '6dfef724aedf39b075720f20a5dfcb2e7a145068', 'guest_528387', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:55:32');
INSERT INTO `t_player` VALUES (529734, 0, '748136', 'guest_529734', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-16 17:48:01');
INSERT INTO `t_player` VALUES (529785, 0, '777576', 'guest_529785', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 15:08:08');
INSERT INTO `t_player` VALUES (533128, 0, '160066', 'guest_533128', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:23:39');
INSERT INTO `t_player` VALUES (534305, 0, '136998', 'guest_534305', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:45:47');
INSERT INTO `t_player` VALUES (535161, 0, '938500', 'guest_535161', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-13 20:21:19');
INSERT INTO `t_player` VALUES (538096, 0, 'dc37d5e986707438a5b17e89c940947d9ba78cd3', 'guest_538096', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 15:58:55');
INSERT INTO `t_player` VALUES (538351, 0, '36092', 'guest_538351', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-11 11:39:27');
INSERT INTO `t_player` VALUES (538628, 0, 'caiqing004', '004_538628', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:56:37');
INSERT INTO `t_player` VALUES (540943, 0, 'dec1bbc94b82d9b5ddfdf2dee689a6158af9acab', 'guest_540943', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-24 07:50:12');
INSERT INTO `t_player` VALUES (542280, 0, '380926', 'guest_542280', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-22 21:13:26');
INSERT INTO `t_player` VALUES (543963, 0, '295577', 'guest_543963', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-21 16:47:52');
INSERT INTO `t_player` VALUES (546773, 0, 'xiaorang01', 'guest_546773', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-25 21:50:49');
INSERT INTO `t_player` VALUES (546824, 0, 'lili001', 'guest_546824', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-05 20:52:49');
INSERT INTO `t_player` VALUES (548694, 0, 'qs06', 'qs06', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:27:33');
INSERT INTO `t_player` VALUES (551000, 0, '21213123213', 'guest_551000', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:49:16');
INSERT INTO `t_player` VALUES (551262, 0, '150915', 'guest_551262', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:25:11');
INSERT INTO `t_player` VALUES (552045, 0, 'ef5ec0d32ea0ece3998c91274d14a01f0a00483d', 'king', 0, '', '', 'Android', 'ompjp1Bcb4_JOhLE-bsf-vCT30Qo', '0', NULL, 1, NULL, '', '2023-01-07 10:37:21');
INSERT INTO `t_player` VALUES (552276, 0, 'lili003', 'guest_552276', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-05 20:55:42');
INSERT INTO `t_player` VALUES (552840, 0, '6dd42fcd024e82473627946af33a546d9ce8caf3', 'guest_552840', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-24 08:48:56');
INSERT INTO `t_player` VALUES (552956, 0, '704946', 'guest_552956', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 10:20:27');
INSERT INTO `t_player` VALUES (553184, 0, 'fa8000', 'guest_553184', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 10:46:35');
INSERT INTO `t_player` VALUES (555313, 0, '501127', 'guest_555313', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 18:30:41');
INSERT INTO `t_player` VALUES (557557, 0, 'dsfasdfasdf', 'guest_557557', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:09:10');
INSERT INTO `t_player` VALUES (558122, 0, '279333', 'guest_558122', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 12:52:02');
INSERT INTO `t_player` VALUES (561535, 0, 'd818bf3daac88e64c877b6bcd6bfaa3a5a5a7928', '金牌girl', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/vA3eDF0MS2eFPZExD6bqgqTUTsPBpGAr25FtdHwfsNj89kIcc81UOiarjKMJTqFrdVdYN2Khz94rU7Zicswuzq8Q/132', '', 'Android', 'oXRuxxOB2pNoFoQkEQFsOYn20xK4', '0', NULL, 1, NULL, '', '2021-08-05 21:52:22');
INSERT INTO `t_player` VALUES (562014, 0, '204164', 'guest_562014', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 20:17:35');
INSERT INTO `t_player` VALUES (562263, 0, '179715', 'guest_562263', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 15:57:10');
INSERT INTO `t_player` VALUES (567506, 0, 'fat999', 'guest_567506', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-18 22:05:27');
INSERT INTO `t_player` VALUES (568541, 0, 'sixgod003', '568541', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 18:27:18');
INSERT INTO `t_player` VALUES (570624, 0, '590895', 'guest_570624', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 18:03:26');
INSERT INTO `t_player` VALUES (571057, 0, 'lz444', 'guest_571057', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-27 12:44:55');
INSERT INTO `t_player` VALUES (571335, 0, '10370', 'guest_571335', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-10-05 23:56:13');
INSERT INTO `t_player` VALUES (571590, 0, '1121221', 'guest_571590', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 0, NULL, '', '2022-11-09 12:24:16');
INSERT INTO `t_player` VALUES (572501, 0, '01dbccdbef00b8205c134dad6a782122b399b2a9', 'guest_572501', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-03 18:30:09');
INSERT INTO `t_player` VALUES (573589, 0, 'li001', 'guest_573589', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 10:28:44');
INSERT INTO `t_player` VALUES (574823, 0, '4617', 'guest_574823', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-22 20:37:39');
INSERT INTO `t_player` VALUES (578255, 0, '4ee51f53a08704c203aa46959ab5b73b6bee41e5', 'guest_578255', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-10 21:27:54');
INSERT INTO `t_player` VALUES (579658, 0, '991284', 'guest_579658', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 18:03:11');
INSERT INTO `t_player` VALUES (584333, 0, '395442', 'guest_584333', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 22:01:09');
INSERT INTO `t_player` VALUES (586082, 0, '12711', 'guest_586082', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-27 18:38:21');
INSERT INTO `t_player` VALUES (587423, 0, '221312321', 'guest_587423', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:42:23');
INSERT INTO `t_player` VALUES (587846, 0, '250146', 'guest_587846', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-06 09:04:33');
INSERT INTO `t_player` VALUES (588575, 0, '691298', 'guest_588575', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-27 18:38:40');
INSERT INTO `t_player` VALUES (590202, 0, '336575', 'guest_590202', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 17:58:43');
INSERT INTO `t_player` VALUES (591777, 0, '815741', 'guest_591777', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 18:50:15');
INSERT INTO `t_player` VALUES (591867, 0, '29987', 'guest_591867', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 22:03:23');
INSERT INTO `t_player` VALUES (592677, 0, '140790', 'guest_592677', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:08:31');
INSERT INTO `t_player` VALUES (593532, 0, '233235', 'guest_593532', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 20:04:55');
INSERT INTO `t_player` VALUES (597181, 0, '831313', 'guest_597181', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-15 16:20:13');
INSERT INTO `t_player` VALUES (597380, 0, '260149', 'guest_597380', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 17:48:56');
INSERT INTO `t_player` VALUES (598629, 0, 'cdc9e06da873f31bb045df6e58087ec43a8015ac', '阿奇去去去', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q3auHgzwzM7nbcKYQct8icVnsqTt7hR5ExYTM9saOa6ca9CcfltUhvg8rxAaj7ynl8z4Dj3kzemvdYAqgjAXMlEicsiaArcbn4S/132', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-09-08 11:20:21');
INSERT INTO `t_player` VALUES (598753, 0, '12167', 'guest_598753', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 16:47:50');
INSERT INTO `t_player` VALUES (599030, 0, '200454', 'guest_599030', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 16:22:16');
INSERT INTO `t_player` VALUES (600332, 0, 'caiqing007', '007_600332', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:42:43');
INSERT INTO `t_player` VALUES (602388, 0, '124244', 'guest_602388', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 15:39:06');
INSERT INTO `t_player` VALUES (604448, 0, '2112', 'guest_604448', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-09 12:41:30');
INSERT INTO `t_player` VALUES (610897, 0, '844914', 'guest_610897', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-02 16:04:03');
INSERT INTO `t_player` VALUES (611190, 0, '911893', 'guest_611190', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 16:29:15');
INSERT INTO `t_player` VALUES (617767, 0, '905273', 'guest_617767', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 21:09:30');
INSERT INTO `t_player` VALUES (617849, 0, '212121', 'guest_617849', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:35:52');
INSERT INTO `t_player` VALUES (618758, 0, '438284', 'guest_618758', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 15:06:43');
INSERT INTO `t_player` VALUES (618763, 0, 'caiqing008', '008_618763', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:49:37');
INSERT INTO `t_player` VALUES (619079, 0, '826614', 'guest_619079', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-29 12:33:43');
INSERT INTO `t_player` VALUES (619898, 0, '41e2768bc3816ac92b57dc7be5bf4939b495fad4	', 'guest_619898', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-04 21:16:24');
INSERT INTO `t_player` VALUES (621908, 0, 'vip007', 'guest_621908', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-01 22:55:36');
INSERT INTO `t_player` VALUES (622560, 0, '722348', 'guest_622560', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-22 10:26:45');
INSERT INTO `t_player` VALUES (623211, 0, 'vic005', 'vic005', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 20:40:56');
INSERT INTO `t_player` VALUES (625872, 0, '63fdf75dd685078c18da3a06a3fdb7284989b06d', '春风十里', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/s4wzgOCEBgbZa8MfErfiaMEp3zxiafAfyGOUbNE5IfMbb2o3ppXhnkzmJMap9UXicefsnIrRUl8agcJ36q6n7Wciaw/132', NULL, 'Android', 'ompjp1LzhWb0ifCZ_iiRlEOEEpKo', '0', NULL, 1, NULL, '', '2021-12-21 17:52:51');
INSERT INTO `t_player` VALUES (627003, 0, '208453', 'guest_627003', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-13 21:09:26');
INSERT INTO `t_player` VALUES (632003, 0, '61378', 'guest_632003', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 22:01:58');
INSERT INTO `t_player` VALUES (632647, 0, 'test001', 't001_632647', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 12:41:28');
INSERT INTO `t_player` VALUES (633655, 0, '719694', 'guest_633655', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:38:17');
INSERT INTO `t_player` VALUES (636540, 0, '695717', 'guest_636540', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-09 20:32:13');
INSERT INTO `t_player` VALUES (637306, 0, 'de0522f045f7eb59102543e7827b9967762ad586', 'guest_637306', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-18 20:47:41');
INSERT INTO `t_player` VALUES (640258, 0, '179027', 'guest_640258', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 20:08:22');
INSERT INTO `t_player` VALUES (640567, 0, '379296', 'guest_640567', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-26 18:43:10');
INSERT INTO `t_player` VALUES (641475, 0, '205895', 'guest_641475', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 17:36:39');
INSERT INTO `t_player` VALUES (641483, 0, 'uuuu', 'guest_641483', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-08 17:19:47');
INSERT INTO `t_player` VALUES (645105, 0, '123456', 'guest_645105', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-22 15:04:22');
INSERT INTO `t_player` VALUES (645194, 0, '811518', 'guest_645194', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 18:11:06');
INSERT INTO `t_player` VALUES (645648, 0, '9132', 'guest_645648', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-26 18:41:57');
INSERT INTO `t_player` VALUES (645920, 0, '623788', 'guest_645920', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 12:29:38');
INSERT INTO `t_player` VALUES (646096, 0, '123187', 'guest_646096', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-16 20:45:45');
INSERT INTO `t_player` VALUES (647176, 0, '123660', 'guest_647176', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-04 16:22:22');
INSERT INTO `t_player` VALUES (648257, 0, '195353', 'guest_648257', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 22:13:14');
INSERT INTO `t_player` VALUES (651402, 0, '232132132131', 'guest_651402', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:19:23');
INSERT INTO `t_player` VALUES (652064, 0, '367889', 'guest_652064', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 21:51:32');
INSERT INTO `t_player` VALUES (652681, 0, '956385', 'guest_652681', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-28 16:18:02');
INSERT INTO `t_player` VALUES (653971, 0, '487269', 'guest_653971', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-07 22:23:58');
INSERT INTO `t_player` VALUES (654621, 0, '22121', 'guest_654621', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 12:27:23');
INSERT INTO `t_player` VALUES (654730, 0, '213312412313', 'guest_654730', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 20:46:49');
INSERT INTO `t_player` VALUES (659162, 0, '8c21e00b6b0367ff89394e2b992fe92fea0e49ac', 'guest_659162', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-05 17:43:27');
INSERT INTO `t_player` VALUES (659532, 0, 'lz333', 'guest_659532', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-08 17:16:08');
INSERT INTO `t_player` VALUES (660734, 0, '91633', 'guest_660734', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 13:07:54');
INSERT INTO `t_player` VALUES (661060, 0, 'rong002', 'rong002', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-09 11:09:49');
INSERT INTO `t_player` VALUES (663723, 0, '728705', 'guest_663723', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 16:55:31');
INSERT INTO `t_player` VALUES (664824, 0, '3c8b58c936cdf14247ff09325c6887986efc1952', 'guest_664824', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:57:56');
INSERT INTO `t_player` VALUES (669767, 0, '457600', 'guest_669767', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 00:50:07');
INSERT INTO `t_player` VALUES (671458, 0, 'a8dc9c32971c763b534634f64e8554686530b961', '258258', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:27:57');
INSERT INTO `t_player` VALUES (674559, 0, '997342', 'guest_674559', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-09 16:30:34');
INSERT INTO `t_player` VALUES (677100, 0, '69101', 'guest_677100', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:12:21');
INSERT INTO `t_player` VALUES (678070, 0, 'lz222', 'guest_678070', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-08 10:25:08');
INSERT INTO `t_player` VALUES (678100, 0, 'd5c0b5aaa2992c451e7c4e8c4c2c6d73d5349791', '天涯', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q3auHgzwzM58dgHjV1ES9XrIibaibWYNNIsc5JanO6xc42AbqXy7bQf9nVBHSo5es32wmz1Ct2p2I2GcnmF8cJMibMrEtXthdKw/132', '', 'Android', 'ompjp1HpPKqnRZlU1RpgUNmnyS10', '0', NULL, 1, NULL, '', '2022-06-02 16:43:47');
INSERT INTO `t_player` VALUES (678385, 0, '643330', 'guest_678385', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-07 22:45:18');
INSERT INTO `t_player` VALUES (681399, 0, '711225', 'guest_681399', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 12:46:36');
INSERT INTO `t_player` VALUES (683185, 0, 'lz666', 'guest_683185', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-08 17:39:00');
INSERT INTO `t_player` VALUES (684573, 0, 'vic004', 'vic004', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 10:27:08');
INSERT INTO `t_player` VALUES (686627, 0, 'vip003', 'vip003', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 18:08:13');
INSERT INTO `t_player` VALUES (686764, 0, '286949', 'guest_686764', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:32:50');
INSERT INTO `t_player` VALUES (695434, 0, '567794', 'guest_695434', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', 0, 1, NULL, '', '2022-06-17 15:09:21');
INSERT INTO `t_player` VALUES (695682, 0, '977241', 'guest_695682', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 11:27:35');
INSERT INTO `t_player` VALUES (697431, 0, '654272', 'guest_697431', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 12:21:41');
INSERT INTO `t_player` VALUES (698680, 0, '433927', 'guest_698680', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 17:26:50');
INSERT INTO `t_player` VALUES (700139, 0, '212122', 'guest_700139', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 21:05:23');
INSERT INTO `t_player` VALUES (700744, 0, '994758', 'guest_700744', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 22:09:09');
INSERT INTO `t_player` VALUES (701579, 0, 'vic001', 'vic001', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', 0, 1, NULL, '', '2022-06-07 17:34:57');
INSERT INTO `t_player` VALUES (702757, 0, '689100', 'guest_702757', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 17:00:03');
INSERT INTO `t_player` VALUES (703123, 0, '809405', 'guest_703123', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-15 16:55:35');
INSERT INTO `t_player` VALUES (703402, 0, '571823', 'guest_703402', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:21:55');
INSERT INTO `t_player` VALUES (704039, 0, '199190', 'guest_704039', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 11:23:54');
INSERT INTO `t_player` VALUES (704837, 0, '989037', 'guest_704837', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 17:11:42');
INSERT INTO `t_player` VALUES (704946, 0, '648218', 'guest_704946', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 20:35:16');
INSERT INTO `t_player` VALUES (707218, 0, '175445', 'guest_707218', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 10:51:21');
INSERT INTO `t_player` VALUES (713117, 0, 'qs04', 'qs04', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 15:22:16');
INSERT INTO `t_player` VALUES (714157, 0, '250060', 'guest_714157', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-10 16:48:14');
INSERT INTO `t_player` VALUES (720084, 0, '82289', 'guest_720084', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 01:07:14');
INSERT INTO `t_player` VALUES (720206, 0, 'b1f796bca7141cd8312e040c9503c5a534d281f4', 'guest_720206', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-16 23:08:36');
INSERT INTO `t_player` VALUES (723059, 0, '577764', 'guest_723059', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 16:47:51');
INSERT INTO `t_player` VALUES (725921, 0, 'six002', 'guest_725921', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 18:26:43');
INSERT INTO `t_player` VALUES (729925, 0, '475781', 'guest_729925', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-13 10:01:25');
INSERT INTO `t_player` VALUES (730555, 0, '595495', 'guest_730555', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-04 12:45:23');
INSERT INTO `t_player` VALUES (731540, 0, '596263', 'guest_731540', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 21:47:39');
INSERT INTO `t_player` VALUES (732641, 0, 'caiqng006', 'guest_732641', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-25 00:01:52');
INSERT INTO `t_player` VALUES (732948, 0, '626515', 'guest_732948', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 18:45:40');
INSERT INTO `t_player` VALUES (733969, 0, '4d08687af3608631dce8af8552422d1101d39cc1', '阿奇去去去', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q3auHgzwzM7nbcKYQct8icVnsqTt7hR5ExYTM9saOa6ca9CcfltUhvg8rxAaj7ynl8z4Dj3kzemvdYAqgjAXMlEicsiaArcbn4S/132', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-09-08 11:40:29');
INSERT INTO `t_player` VALUES (741129, 0, '280978', 'guest_741129', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-12 05:48:50');
INSERT INTO `t_player` VALUES (741968, 0, '5fdf1134779ba15bb0e6fab030cde2beee2d9eb0', 'guest_741968', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 10:14:05');
INSERT INTO `t_player` VALUES (742897, 0, '797163', 'guest_742897', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:06:12');
INSERT INTO `t_player` VALUES (742950, 0, '897526', 'guest_742950', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-06 22:11:54');
INSERT INTO `t_player` VALUES (743811, 0, 'caiqing003', 'caiqing003', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:55:24');
INSERT INTO `t_player` VALUES (745754, 0, '317663', 'guest_745754', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 21:55:42');
INSERT INTO `t_player` VALUES (747520, 0, '860478', 'guest_747520', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-19 18:17:38');
INSERT INTO `t_player` VALUES (749225, 0, '594513', 'guest_749225', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:29:05');
INSERT INTO `t_player` VALUES (750731, 0, '642935', 'guest_750731', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-21 18:33:28');
INSERT INTO `t_player` VALUES (753973, 0, 'vic002', 'vic002', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 10:26:14');
INSERT INTO `t_player` VALUES (756302, 0, '168075', 'guest_756302', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-27 21:19:37');
INSERT INTO `t_player` VALUES (757072, 0, '3123123', 'guest_757072', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-19 16:51:29');
INSERT INTO `t_player` VALUES (760399, 0, '49917', 'guest_760399', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-14 21:26:48');
INSERT INTO `t_player` VALUES (760451, 0, '41066', 'guest_760451', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 12:32:01');
INSERT INTO `t_player` VALUES (761204, 0, '542167', 'guest_761204', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 20:33:23');
INSERT INTO `t_player` VALUES (761390, 0, '464280', 'guest_761390', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-28 11:16:21');
INSERT INTO `t_player` VALUES (763410, 0, '680310', 'guest_763410', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-27 12:06:53');
INSERT INTO `t_player` VALUES (766607, 0, '726e834b6f2321b29f3005971a229f19a2', 'guest_766607', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 16:39:41');
INSERT INTO `t_player` VALUES (766774, 0, '779267', 'guest_766774', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-28 16:08:56');
INSERT INTO `t_player` VALUES (767874, 0, '79919', 'guest_767874', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-01 12:49:30');
INSERT INTO `t_player` VALUES (767947, 0, '23213213213', 'guest_767947', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:50:21');
INSERT INTO `t_player` VALUES (768535, 0, '984516', 'guest_768535', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-10 18:19:58');
INSERT INTO `t_player` VALUES (772357, 0, '601248', 'guest_772357', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:05:48');
INSERT INTO `t_player` VALUES (774130, 0, '111111', 'guest_774130', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-25 21:37:46');
INSERT INTO `t_player` VALUES (776181, 0, '796765', 'guest_776181', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-14 16:49:43');
INSERT INTO `t_player` VALUES (776820, 0, '775522', 'guest_776820', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 18:01:46');
INSERT INTO `t_player` VALUES (779578, 0, '8d673e48d41c2149fe7925e18e04c23cf164e65c	', 'guest_779578', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:25:18');
INSERT INTO `t_player` VALUES (779862, 0, '294223', 'guest_779862', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:34:09');
INSERT INTO `t_player` VALUES (780508, 0, 'caiqing002', 'caiqing002', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:33:20');
INSERT INTO `t_player` VALUES (783001, 0, 'caiqing013', 'guest_783001', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-15 16:30:57');
INSERT INTO `t_player` VALUES (783467, 0, '000cbd986d452e22430a98a7c93c25277fd68f8e', 'guest_783467', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-11 15:13:04');
INSERT INTO `t_player` VALUES (784411, 0, '23133', 'guest_784411', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 19:58:36');
INSERT INTO `t_player` VALUES (792612, 0, '359105', 'guest_792612', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:15:04');
INSERT INTO `t_player` VALUES (792712, 0, '396161', 'guest_792712', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-01 10:06:16');
INSERT INTO `t_player` VALUES (797822, 0, '22222', 'guest_797822', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-25 21:31:24');
INSERT INTO `t_player` VALUES (800545, 0, 'lili007', 'guest_800545', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-19 16:22:26');
INSERT INTO `t_player` VALUES (808009, 0, 'lili005', 'guest_808009', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-31 21:25:36');
INSERT INTO `t_player` VALUES (809493, 0, '7d1336156e0deba316fcfe39fe2a67398848a972', 'guest_809493', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-21 20:52:39');
INSERT INTO `t_player` VALUES (809621, 0, '933642', 'guest_809621', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 11:26:32');
INSERT INTO `t_player` VALUES (816789, 0, '849307', 'guest_816789', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-01 12:30:29');
INSERT INTO `t_player` VALUES (816808, 0, 'caiqing012', '012_816808', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 20:17:52');
INSERT INTO `t_player` VALUES (817466, 0, '471191', 'guest_817466', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-29 21:33:11');
INSERT INTO `t_player` VALUES (819342, 0, 'xxxx', 'guest_819342', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 16:57:16');
INSERT INTO `t_player` VALUES (820629, 0, '106796', 'guest_820629', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-10 18:19:59');
INSERT INTO `t_player` VALUES (823519, 0, '472855', 'guest_823519', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-11 21:23:02');
INSERT INTO `t_player` VALUES (827090, 0, '67987b96aa9507fcd56d00ad97e882d75e6100f5', '阿奇去去去', 0, 'https://thirdwx.qlogo.cn/mmopen/vi_32/Q3auHgzwzM7nbcKYQct8icVnsqTt7hR5ExYTM9saOa6ca9CcfltUhvg8rxAaj7ynl8z4Dj3kzemvdYAqgjAXMlEicsiaArcbn4S/132', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-09-08 11:32:01');
INSERT INTO `t_player` VALUES (827293, 0, '870932', 'guest_827293', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 16:36:42');
INSERT INTO `t_player` VALUES (828113, 0, 'lili006', 'guest_828113', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-31 21:26:01');
INSERT INTO `t_player` VALUES (828407, 0, '438419', 'guest_828407', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 20:12:15');
INSERT INTO `t_player` VALUES (830308, 0, '65498798', 'guest_830308', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:13:58');
INSERT INTO `t_player` VALUES (830554, 0, 'zzzz', 'guest_830554', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-22 17:26:28');
INSERT INTO `t_player` VALUES (832506, 0, '162547', 'guest_832506', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-23 15:59:05');
INSERT INTO `t_player` VALUES (837403, 0, '134656', 'guest_837403', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-22 15:06:29');
INSERT INTO `t_player` VALUES (838031, 0, 'vip001', 'vip001', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-02 15:51:28');
INSERT INTO `t_player` VALUES (838752, 0, '180222', 'guest_838752', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-27 18:38:55');
INSERT INTO `t_player` VALUES (839524, 0, '718001', 'guest_839524', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-12 09:15:15');
INSERT INTO `t_player` VALUES (840472, 0, '728651', 'guest_840472', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-20 21:46:14');
INSERT INTO `t_player` VALUES (841251, 0, 'caiqing009', '009_841251', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 18:53:48');
INSERT INTO `t_player` VALUES (841507, 0, 'caiqing111', 'caiqing111', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-20 21:53:47');
INSERT INTO `t_player` VALUES (843691, 0, '940529', 'guest_843691', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:04:39');
INSERT INTO `t_player` VALUES (844291, 0, '3b438975a0eec46116343c34441b2366e6c59a7c', 'guest_844291', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-10 14:45:09');
INSERT INTO `t_player` VALUES (848134, 0, '31494', 'guest_848134', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:14:06');
INSERT INTO `t_player` VALUES (851333, 0, '816553', 'guest_851333', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-16 16:21:33');
INSERT INTO `t_player` VALUES (851492, 0, 'fa8002', 'guest_851492', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 11:21:04');
INSERT INTO `t_player` VALUES (852917, 0, 'd5c0b5aaa2992c451e7c4e8c4c2c6d73d5349791', 'guest_852917', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 12:20:00');
INSERT INTO `t_player` VALUES (852949, 0, 'rong004', 'rong004', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-09 11:10:02');
INSERT INTO `t_player` VALUES (853122, 0, '1fd8c70e21de5886e93f65cf268d0d99e9b11a12', 'guest_853122', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-01 11:30:04');
INSERT INTO `t_player` VALUES (854153, 0, '426127', 'guest_854153', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:14:34');
INSERT INTO `t_player` VALUES (854851, 0, '786108', 'guest_854851', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:42:33');
INSERT INTO `t_player` VALUES (856569, 0, 'xll007', 'guest_856569', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 18:55:23');
INSERT INTO `t_player` VALUES (857703, 0, '915523', 'guest_857703', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 18:22:59');
INSERT INTO `t_player` VALUES (858677, 0, '282864', 'guest_858677', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-22 10:38:35');
INSERT INTO `t_player` VALUES (863026, 0, '643601', 'guest_863026', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-10 20:49:07');
INSERT INTO `t_player` VALUES (866064, 0, '612424', 'guest_866064', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-09 11:40:58');
INSERT INTO `t_player` VALUES (867979, 0, 'sixgod002', '867979', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-15 15:09:20');
INSERT INTO `t_player` VALUES (877140, 0, '279479', 'guest_877140', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-28 16:15:31');
INSERT INTO `t_player` VALUES (878747, 0, '275336', 'guest_878747', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-21 10:12:16');
INSERT INTO `t_player` VALUES (881465, 0, '101286', 'guest_881465', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-05 05:32:59');
INSERT INTO `t_player` VALUES (881873, 0, '904383', 'guest_881873', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 12:29:26');
INSERT INTO `t_player` VALUES (882326, 0, '788869', 'guest_882326', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 17:35:40');
INSERT INTO `t_player` VALUES (887317, 0, '633094', 'guest_887317', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 21:51:45');
INSERT INTO `t_player` VALUES (888118, 0, '842093', 'guest_888118', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 22:13:57');
INSERT INTO `t_player` VALUES (892595, 0, 'p', 'guest_892595', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-28 16:02:03');
INSERT INTO `t_player` VALUES (895210, 0, '109549', 'guest_895210', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-21 17:08:58');
INSERT INTO `t_player` VALUES (895706, 0, '92742', 'guest_895706', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 17:06:52');
INSERT INTO `t_player` VALUES (897381, 0, '538310', 'guest_897381', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-12 05:49:41');
INSERT INTO `t_player` VALUES (899868, 0, '323684', 'guest_899868', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-22 15:07:09');
INSERT INTO `t_player` VALUES (903552, 0, '431328', 'guest_903552', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-25 10:11:42');
INSERT INTO `t_player` VALUES (904998, 0, 'vip002', 'vip002', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 15:51:52');
INSERT INTO `t_player` VALUES (905697, 0, '542267', 'guest_905697', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-09 20:27:54');
INSERT INTO `t_player` VALUES (906589, 0, '592082', 'guest_906589', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:44:09');
INSERT INTO `t_player` VALUES (907284, 0, 'vip004', 'vip004', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 18:09:03');
INSERT INTO `t_player` VALUES (907398, 0, '255619', 'guest_907398', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:19:17');
INSERT INTO `t_player` VALUES (909466, 0, '462880', 'guest_909466', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-07 01:14:56');
INSERT INTO `t_player` VALUES (909956, 0, '959160', 'guest_909956', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-03 23:47:49');
INSERT INTO `t_player` VALUES (911829, 0, '6d03f1b2a992395318e5f7294253c1b3656a1cf9', '阿奇去去去', 0, '', '', 'Android', 'ompjp1AJPswmv-AEu70Abq7uAonc', '0', NULL, 1, NULL, '', '2022-07-04 17:30:12');
INSERT INTO `t_player` VALUES (911922, 0, '817532', 'guest_911922', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 17:17:00');
INSERT INTO `t_player` VALUES (915282, 0, '188829', 'guest_915282', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 21:02:30');
INSERT INTO `t_player` VALUES (915598, 0, 'Vic001', 'guest_915598', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-30 17:25:08');
INSERT INTO `t_player` VALUES (915806, 0, '343012', 'guest_915806', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:00:27');
INSERT INTO `t_player` VALUES (916241, 0, '0809c0c421237c488a31307af75b0d104dc2881e', 'guest_916241', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-23 23:52:51');
INSERT INTO `t_player` VALUES (916546, 0, '825875', 'guest_916546', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-07 22:05:51');
INSERT INTO `t_player` VALUES (917128, 0, 'll666', 'guest_917128', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-14 12:42:34');
INSERT INTO `t_player` VALUES (917749, 0, '894379', 'guest_917749', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-06 22:22:56');
INSERT INTO `t_player` VALUES (918682, 0, '1212112', 'guest_918682', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-09 15:06:48');
INSERT INTO `t_player` VALUES (919794, 0, '638843', 'guest_919794', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-08 11:49:12');
INSERT INTO `t_player` VALUES (921910, 0, '98b6c599c840bd92525c2b203c9976930cc4e363', 'guest_921910', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-24 08:48:16');
INSERT INTO `t_player` VALUES (923087, 0, '550397', 'guest_923087', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 21:06:59');
INSERT INTO `t_player` VALUES (930332, 0, '835988', 'guest_930332', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-09-07 23:15:13');
INSERT INTO `t_player` VALUES (930404, 0, '794557', '随机ID', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:28:42');
INSERT INTO `t_player` VALUES (931991, 0, '711677', 'guest_931991', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-23 20:12:22');
INSERT INTO `t_player` VALUES (932729, 0, '574721', 'guest_932729', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-08 13:52:42');
INSERT INTO `t_player` VALUES (933627, 0, '671254', 'guest_933627', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-15 16:17:54');
INSERT INTO `t_player` VALUES (934563, 0, '314445', 'guest_934563', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-16 18:54:21');
INSERT INTO `t_player` VALUES (937637, 0, '356441', 'guest_937637', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 17:59:00');
INSERT INTO `t_player` VALUES (937958, 0, '124060', 'guest_937958', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 17:22:13');
INSERT INTO `t_player` VALUES (938610, 0, '812453', 'guest_938610', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-02 21:35:44');
INSERT INTO `t_player` VALUES (939159, 0, '454224', 'guest_939159', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-31 22:01:32');
INSERT INTO `t_player` VALUES (939389, 0, '915599', 'guest_939389', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-02 10:54:37');
INSERT INTO `t_player` VALUES (945623, 0, '847973', 'guest_945623', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-02 22:29:53');
INSERT INTO `t_player` VALUES (947130, 0, '12313123', 'guest_947130', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-11 12:35:43');
INSERT INTO `t_player` VALUES (949826, 0, '86574', 'guest_949826', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2023-01-04 22:05:57');
INSERT INTO `t_player` VALUES (953482, 0, '290281', 'guest_953482', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 17:07:59');
INSERT INTO `t_player` VALUES (955173, 0, '281829', 'guest_955173', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:36:25');
INSERT INTO `t_player` VALUES (961263, 0, '498817', 'guest_961263', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-17 12:46:12');
INSERT INTO `t_player` VALUES (964226, 0, 'zz666', 'guest_964226', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 20:41:10');
INSERT INTO `t_player` VALUES (968455, 0, '373658', 'guest_968455', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-07 16:31:36');
INSERT INTO `t_player` VALUES (969335, 0, '21211', 'guest_969335', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 20:00:05');
INSERT INTO `t_player` VALUES (970412, 0, '833092', 'guest_970412', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-08-29 15:42:55');
INSERT INTO `t_player` VALUES (970468, 0, '283637', 'guest_970468', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-06 21:53:31');
INSERT INTO `t_player` VALUES (978700, 0, '126987', 'guest_978700', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:19:25');
INSERT INTO `t_player` VALUES (979040, 0, '322757', 'guest_979040', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-29 20:39:21');
INSERT INTO `t_player` VALUES (982399, 0, '743964', 'guest_982399', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:08:28');
INSERT INTO `t_player` VALUES (983602, 0, '489702', 'guest_983602', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-02 10:54:34');
INSERT INTO `t_player` VALUES (986354, 0, '314771', 'guest_986354', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-27 16:24:05');
INSERT INTO `t_player` VALUES (987485, 0, '795872', 'guest_987485', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', 0, 1, NULL, '', '2022-06-17 17:15:03');
INSERT INTO `t_player` VALUES (987684, 0, 'vip01', 'guest_987684', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-11-01 17:51:32');
INSERT INTO `t_player` VALUES (992253, 0, '949019', 'guest_992253', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-06-20 10:41:40');
INSERT INTO `t_player` VALUES (993382, 0, '312311442', 'guest_993382', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 11:42:24');
INSERT INTO `t_player` VALUES (997233, 0, '649271', 'guest_997233', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-31 18:19:00');
INSERT INTO `t_player` VALUES (997385, 0, '657243', 'guest_997385', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-07-05 18:08:00');
INSERT INTO `t_player` VALUES (999386, 0, '223213213', 'guest_999386', 0, 'http://thirdwx.qlogo.cn/mmopen/vi_32/ZRXhHw2YeMsgrMBsIz2fEJJrNnga5xtjlwKdzZXeGD4QCx0ljZpBoIicIlDStHEibFic8pgkALGDScZhewwaZl83w/132', '', 'H5', '', '0', NULL, 1, NULL, '', '2022-12-21 21:07:40');

-- ----------------------------
-- Table structure for t_player_commission
-- ----------------------------
DROP TABLE IF EXISTS `t_player_commission`;
CREATE TABLE `t_player_commission`  (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `club` int(8) NOT NULL,
  `guid` int(8) NOT NULL,
  `money_id` int(4) NOT NULL,
  `commission` int(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uniq_cgm`(`club`, `guid`, `money_id`) USING HASH
) ENGINE = InnoDB AUTO_INCREMENT = 10490 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_player_commission
-- ----------------------------
INSERT INTO `t_player_commission` VALUES (10405, 66428602, 753973, 48, 0);
INSERT INTO `t_player_commission` VALUES (10407, 66428602, 684573, 48, 0);
INSERT INTO `t_player_commission` VALUES (10409, 66428602, 285541, 48, 0);
INSERT INTO `t_player_commission` VALUES (10411, 66428602, 701579, 48, 0);
INSERT INTO `t_player_commission` VALUES (10413, 66428602, 365220, 48, 0);
INSERT INTO `t_player_commission` VALUES (10415, 81378004, 365220, 56, 0);
INSERT INTO `t_player_commission` VALUES (10417, 81378004, 285541, 56, 0);
INSERT INTO `t_player_commission` VALUES (10419, 81378004, 684573, 56, 0);
INSERT INTO `t_player_commission` VALUES (10421, 81378004, 753973, 56, 0);
INSERT INTO `t_player_commission` VALUES (10423, 85665832, 701579, 55, 0);
INSERT INTO `t_player_commission` VALUES (10425, 85665832, 753973, 55, 0);
INSERT INTO `t_player_commission` VALUES (10427, 81378004, 780508, 56, 0);
INSERT INTO `t_player_commission` VALUES (10429, 88603133, 552276, 60, 0);
INSERT INTO `t_player_commission` VALUES (10431, 85665832, 661060, 55, 0);
INSERT INTO `t_player_commission` VALUES (10433, 85665832, 316760, 55, 0);
INSERT INTO `t_player_commission` VALUES (10435, 88603133, 280773, 60, 0);
INSERT INTO `t_player_commission` VALUES (10437, 88603133, 387979, 60, 0);
INSERT INTO `t_player_commission` VALUES (10439, 88603133, 140279, 60, 0);
INSERT INTO `t_player_commission` VALUES (10441, 88603133, 800545, 60, 0);
INSERT INTO `t_player_commission` VALUES (10443, 67262628, 415909, 62, 0);
INSERT INTO `t_player_commission` VALUES (10445, 67262628, 851492, 62, 0);
INSERT INTO `t_player_commission` VALUES (10447, 67262628, 160142, 62, 0);
INSERT INTO `t_player_commission` VALUES (10449, 69081204, 254139, 63, 0);
INSERT INTO `t_player_commission` VALUES (10451, 69081204, 617849, 63, 0);
INSERT INTO `t_player_commission` VALUES (10453, 69081204, 345846, 63, 0);
INSERT INTO `t_player_commission` VALUES (10455, 67262628, 326092, 62, 0);
INSERT INTO `t_player_commission` VALUES (10457, 67262628, 271686, 62, 0);
INSERT INTO `t_player_commission` VALUES (10459, 67262628, 617849, 62, 0);
INSERT INTO `t_player_commission` VALUES (10461, 67262628, 918682, 62, 0);
INSERT INTO `t_player_commission` VALUES (10463, 67262628, 361607, 62, 0);
INSERT INTO `t_player_commission` VALUES (10465, 67262628, 338663, 62, 0);
INSERT INTO `t_player_commission` VALUES (10467, 67262628, 187666, 62, 0);
INSERT INTO `t_player_commission` VALUES (10469, 67262628, 651402, 62, 0);
INSERT INTO `t_player_commission` VALUES (10471, 69793347, 998317, 36, -101);
INSERT INTO `t_player_commission` VALUES (10473, 64793141, 374654, 67, 0);
INSERT INTO `t_player_commission` VALUES (10475, 64793141, 999386, 67, 0);
INSERT INTO `t_player_commission` VALUES (10477, 64793141, 361304, 67, 0);
INSERT INTO `t_player_commission` VALUES (10479, 85389915, 123187, 64, 0);
INSERT INTO `t_player_commission` VALUES (10481, 60320931, 904998, 68, 320);
INSERT INTO `t_player_commission` VALUES (10483, 60320931, 686627, 68, 160);
INSERT INTO `t_player_commission` VALUES (10485, 60320931, 907284, 68, 0);
INSERT INTO `t_player_commission` VALUES (10487, 60320931, 838031, 68, 720);
INSERT INTO `t_player_commission` VALUES (10489, 66219171, 223429, 69, 0);

-- ----------------------------
-- Table structure for t_player_money
-- ----------------------------
DROP TABLE IF EXISTS `t_player_money`;
CREATE TABLE `t_player_money`  (
  `guid` int(8) NOT NULL COMMENT '玩家id',
  `money_id` int(4) NOT NULL DEFAULT 0 COMMENT '金钱类型 0金币 1房卡 2钻石',
  `money` bigint(8) NOT NULL DEFAULT 0 COMMENT '数量',
  `where` smallint(2) NOT NULL DEFAULT 0 COMMENT '存在哪儿 0玩家身上 1保险箱',
  PRIMARY KEY (`guid`, `money_id`, `where`) USING BTREE,
  INDEX `idx_player_money`(`guid`, `money_id`, `where`) USING BTREE,
  INDEX `idx_guid_money_id`(`guid`, `money_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '玩家金钱' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_player_money
-- ----------------------------
INSERT INTO `t_player_money` VALUES (100577, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (101021, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (105718, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (110018, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (110044, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (111351, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (113465, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (115348, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (118403, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (119700, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (119700, 62, 58600, 0);
INSERT INTO `t_player_money` VALUES (123187, 64, 496100, 0);
INSERT INTO `t_player_money` VALUES (124918, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (125746, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (126821, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (128440, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (130200, 0, 4992200, 0);
INSERT INTO `t_player_money` VALUES (130200, 69, 199698300, 0);
INSERT INTO `t_player_money` VALUES (134405, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (135856, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (136998, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (137524, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (137556, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (137913, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (138120, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (138183, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (139322, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (139340, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (139358, -1, -3000, 0);
INSERT INTO `t_player_money` VALUES (139358, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (139847, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (140279, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (140279, 60, 0, 0);
INSERT INTO `t_player_money` VALUES (141793, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (142183, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (145719, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (146448, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (151892, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (152426, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (152426, 56, -100, 0);
INSERT INTO `t_player_money` VALUES (152426, 60, 9800, 0);
INSERT INTO `t_player_money` VALUES (154400, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (155456, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (156800, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (157087, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (157190, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (158962, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (160142, 0, 222800, 0);
INSERT INTO `t_player_money` VALUES (160142, 62, 2000000, 0);
INSERT INTO `t_player_money` VALUES (164158, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (168663, 0, 400, 0);
INSERT INTO `t_player_money` VALUES (172846, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (173513, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (173724, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (174748, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (175501, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (176516, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (176516, 56, 100, 0);
INSERT INTO `t_player_money` VALUES (176516, 60, 9500, 0);
INSERT INTO `t_player_money` VALUES (177441, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (179621, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (181479, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (182233, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (182387, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (184111, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (185502, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (187666, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (187666, 62, 0, 0);
INSERT INTO `t_player_money` VALUES (189243, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (198191, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (200558, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (200558, 50, 0, 0);
INSERT INTO `t_player_money` VALUES (200558, 51, 200000000, 0);
INSERT INTO `t_player_money` VALUES (200558, 54, 200000000, 0);
INSERT INTO `t_player_money` VALUES (200558, 56, 0, 0);
INSERT INTO `t_player_money` VALUES (203700, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (203700, 56, 9600, 0);
INSERT INTO `t_player_money` VALUES (206489, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (210795, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (211389, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (211922, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (212344, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (213457, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (214356, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (215284, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (215290, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (216253, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (216294, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (216882, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (218751, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (218751, 60, 0, 0);
INSERT INTO `t_player_money` VALUES (220092, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (223429, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (223429, 69, 104800, 0);
INSERT INTO `t_player_money` VALUES (225581, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (228098, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (228620, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (228794, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (232495, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (232523, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (234923, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (236076, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (244136, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (244374, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (244423, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (249560, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (254139, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (254139, 63, 40000000, 0);
INSERT INTO `t_player_money` VALUES (254329, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (254329, 55, 1008897, 0);
INSERT INTO `t_player_money` VALUES (255411, -1, 4500, 0);
INSERT INTO `t_player_money` VALUES (255411, 0, 500, 0);
INSERT INTO `t_player_money` VALUES (255744, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (264616, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (264763, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (266472, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (266909, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (269088, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (270827, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (270827, 56, 0, 0);
INSERT INTO `t_player_money` VALUES (271686, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (271686, 62, 2500000, 0);
INSERT INTO `t_player_money` VALUES (271686, 63, 150000000, 0);
INSERT INTO `t_player_money` VALUES (278383, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (280773, -1, 3500, 0);
INSERT INTO `t_player_money` VALUES (280773, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (280773, 60, 8900, 0);
INSERT INTO `t_player_money` VALUES (281730, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (283635, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (285541, -1, -800, 0);
INSERT INTO `t_player_money` VALUES (285541, 0, 11000, 0);
INSERT INTO `t_player_money` VALUES (285541, 49, 900, 0);
INSERT INTO `t_player_money` VALUES (285541, 56, 79700, 0);
INSERT INTO `t_player_money` VALUES (286022, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (287126, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (287169, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (287763, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (288904, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (289401, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (291650, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (292011, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (293188, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (293188, 67, 0, 0);
INSERT INTO `t_player_money` VALUES (294236, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (294382, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (300530, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (302904, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (304343, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (305786, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (306970, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (308820, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (310566, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (310797, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (313594, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (313700, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (315572, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (316760, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (316760, 55, 1500, 0);
INSERT INTO `t_player_money` VALUES (316818, 36, 800, 0);
INSERT INTO `t_player_money` VALUES (316841, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (321641, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (322758, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (325649, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (325726, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (326092, -1, -300, 0);
INSERT INTO `t_player_money` VALUES (326092, 0, -200, 0);
INSERT INTO `t_player_money` VALUES (326092, 62, 246400, 0);
INSERT INTO `t_player_money` VALUES (326224, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (329643, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (330952, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (333332, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (334831, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (336015, -1, 400, 0);
INSERT INTO `t_player_money` VALUES (336015, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (338663, -1, -1000, 0);
INSERT INTO `t_player_money` VALUES (338663, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (338663, 62, 5333300, 0);
INSERT INTO `t_player_money` VALUES (340921, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (343271, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (345846, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (345846, 63, 5000000, 0);
INSERT INTO `t_player_money` VALUES (346248, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (348580, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (349020, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (349020, 64, 603600, 0);
INSERT INTO `t_player_money` VALUES (350108, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (351990, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (356115, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (357268, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (358330, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (361304, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (361304, 67, 0, 0);
INSERT INTO `t_player_money` VALUES (361607, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (361607, 62, 0, 0);
INSERT INTO `t_player_money` VALUES (361690, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (364122, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (364271, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (364602, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (364602, 56, 0, 0);
INSERT INTO `t_player_money` VALUES (365220, 0, 700, 0);
INSERT INTO `t_player_money` VALUES (365220, 55, 190000000, 0);
INSERT INTO `t_player_money` VALUES (365220, 56, 10000, 0);
INSERT INTO `t_player_money` VALUES (365852, 0, 100, 0);
INSERT INTO `t_player_money` VALUES (365852, 41, 199841000, 0);
INSERT INTO `t_player_money` VALUES (365880, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (366676, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (372031, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (372767, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (373339, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (373475, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (374004, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (374654, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (374654, 67, 1300, 0);
INSERT INTO `t_player_money` VALUES (379327, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (379559, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (380450, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (380926, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (381247, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (382611, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (382775, 36, 17998377, 0);
INSERT INTO `t_player_money` VALUES (383072, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (383251, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (387869, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (387979, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (387979, 60, 29950, 0);
INSERT INTO `t_player_money` VALUES (389967, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (390502, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (390839, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (391682, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (392024, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (392545, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (392554, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (399394, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (400276, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (402755, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (403857, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (407558, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (409024, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (409361, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (412652, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (413123, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (414948, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (415909, -1, 0, 0);
INSERT INTO `t_player_money` VALUES (415909, 0, 222200, 0);
INSERT INTO `t_player_money` VALUES (415909, 62, 2441400, 0);
INSERT INTO `t_player_money` VALUES (416961, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (420478, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (420682, 0, 200, 0);
INSERT INTO `t_player_money` VALUES (421492, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (422366, -1, -500, 0);
INSERT INTO `t_player_money` VALUES (422366, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (422575, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (423679, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (426115, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (430526, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (432125, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (433185, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (433185, 69, 0, 0);
INSERT INTO `t_player_money` VALUES (433205, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (436730, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (437358, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (438109, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (439492, -1, -1800, 0);
INSERT INTO `t_player_money` VALUES (439492, 0, 400, 0);
INSERT INTO `t_player_money` VALUES (439596, -1, 100, 0);
INSERT INTO `t_player_money` VALUES (439596, 0, 21000, 0);
INSERT INTO `t_player_money` VALUES (439596, 56, 600, 0);
INSERT INTO `t_player_money` VALUES (441423, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (441697, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (441871, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (441897, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (443589, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (443619, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (444185, -1, 100, 0);
INSERT INTO `t_player_money` VALUES (444185, 0, 108300, 0);
INSERT INTO `t_player_money` VALUES (444185, 56, 9800, 0);
INSERT INTO `t_player_money` VALUES (444185, 68, 0, 0);
INSERT INTO `t_player_money` VALUES (444507, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (444507, 61, 0, 0);
INSERT INTO `t_player_money` VALUES (444507, 68, 0, 0);
INSERT INTO `t_player_money` VALUES (444689, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (448518, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (448518, 62, 0, 0);
INSERT INTO `t_player_money` VALUES (450260, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (450392, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (451733, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (452483, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (453372, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (453372, 69, 100600, 0);
INSERT INTO `t_player_money` VALUES (454224, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (454224, 57, 199985000, 0);
INSERT INTO `t_player_money` VALUES (454224, 58, 0, 0);
INSERT INTO `t_player_money` VALUES (456551, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (456918, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (457010, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (460507, -1, 200, 0);
INSERT INTO `t_player_money` VALUES (460507, 0, 200, 0);
INSERT INTO `t_player_money` VALUES (462354, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (464371, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (464425, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (466171, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (466835, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (468083, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (468083, 56, 0, 0);
INSERT INTO `t_player_money` VALUES (468842, 0, 12800, 0);
INSERT INTO `t_player_money` VALUES (468842, 64, 196491800, 0);
INSERT INTO `t_player_money` VALUES (470005, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (471472, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (471758, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (471763, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (477990, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (478963, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (480657, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (486359, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (492105, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (493535, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (493606, -1, 600, 0);
INSERT INTO `t_player_money` VALUES (493606, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (493732, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (493732, 56, 10000, 0);
INSERT INTO `t_player_money` VALUES (500943, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (503009, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (503224, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (503419, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (505930, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (506824, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (507126, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (511985, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (511985, 56, 991600, 0);
INSERT INTO `t_player_money` VALUES (513587, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (513603, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (516748, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (520685, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (521473, 0, 400, 0);
INSERT INTO `t_player_money` VALUES (521588, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (522459, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (525382, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (525655, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (528387, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (529734, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (529785, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (533128, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (534305, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (535161, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (538096, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (538351, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (538628, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (538628, 60, 7800, 0);
INSERT INTO `t_player_money` VALUES (540943, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (542280, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (543963, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (546773, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (546824, -1, -3500, 0);
INSERT INTO `t_player_money` VALUES (546824, 0, 1800, 0);
INSERT INTO `t_player_money` VALUES (546824, 60, 199857500, 0);
INSERT INTO `t_player_money` VALUES (548694, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (548694, 69, 96300, 0);
INSERT INTO `t_player_money` VALUES (551000, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (551000, 62, 0, 0);
INSERT INTO `t_player_money` VALUES (551262, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (552045, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (552045, 64, 659400, 0);
INSERT INTO `t_player_money` VALUES (552276, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (552276, 60, 3350, 0);
INSERT INTO `t_player_money` VALUES (552840, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (552956, -1, -200, 0);
INSERT INTO `t_player_money` VALUES (552956, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (553184, -1, -700, 0);
INSERT INTO `t_player_money` VALUES (553184, 0, 0, 0);
INSERT INTO `t_player_money` VALUES (553184, 62, 184111600, 0);
INSERT INTO `t_player_money` VALUES (555313, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (557557, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (558122, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (562014, 0, 21000, 0);
INSERT INTO `t_player_money` VALUES (562263, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (567506, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (568541, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (568541, 56, 10000, 0);
INSERT INTO `t_player_money` VALUES (568541, 57, 5000, 0);
INSERT INTO `t_player_money` VALUES (570624, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (571057, -1, -200, 0);
INSERT INTO `t_player_money` VALUES (571057, 0, 21000, 0);
INSERT INTO `t_player_money` VALUES (571057, 56, 9800, 0);
INSERT INTO `t_player_money` VALUES (571335, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (571590, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (572501, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (573589, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (573589, 53, 500, 0);
INSERT INTO `t_player_money` VALUES (573589, 60, 10300, 0);
INSERT INTO `t_player_money` VALUES (574823, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (578255, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (579658, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (584333, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (584811, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (586082, -1, 600, 0);
INSERT INTO `t_player_money` VALUES (586082, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (587423, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (587423, 62, 0, 0);
INSERT INTO `t_player_money` VALUES (587846, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (588575, -1, 300, 0);
INSERT INTO `t_player_money` VALUES (588575, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (590202, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (591777, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (591867, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (592677, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (593532, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (597181, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (597380, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (598629, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (598753, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (599030, -1, -6000, 0);
INSERT INTO `t_player_money` VALUES (599030, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (600332, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (600332, 56, 9300, 0);
INSERT INTO `t_player_money` VALUES (600332, 60, 9400, 0);
INSERT INTO `t_player_money` VALUES (602388, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (604448, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (610897, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (611190, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (617767, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (617849, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (617849, 62, 193200, 0);
INSERT INTO `t_player_money` VALUES (617849, 63, 5000000, 0);
INSERT INTO `t_player_money` VALUES (617849, 64, 599700, 0);
INSERT INTO `t_player_money` VALUES (618758, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (618763, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (618763, 56, -200, 0);
INSERT INTO `t_player_money` VALUES (618763, 60, 10000, 0);
INSERT INTO `t_player_money` VALUES (619079, -1, -400, 0);
INSERT INTO `t_player_money` VALUES (619079, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (619898, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (621908, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (622560, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (623211, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (623211, 49, 1300, 0);
INSERT INTO `t_player_money` VALUES (623211, 56, 16697, 0);
INSERT INTO `t_player_money` VALUES (627003, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (627003, 64, 69000, 0);
INSERT INTO `t_player_money` VALUES (632003, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (632647, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (633655, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (636540, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (637306, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (640258, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (640567, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (641475, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (641483, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (645105, -1, 8100, 0);
INSERT INTO `t_player_money` VALUES (645105, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (645194, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (645648, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (645920, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (646096, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (647176, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (648257, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (651402, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (651402, 62, 0, 0);
INSERT INTO `t_player_money` VALUES (652064, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (652681, -1, -100, 0);
INSERT INTO `t_player_money` VALUES (652681, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (653971, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (654621, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (654730, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (659162, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (659532, -1, 700, 0);
INSERT INTO `t_player_money` VALUES (659532, 0, 31000, 0);
INSERT INTO `t_player_money` VALUES (659532, 56, 9800, 0);
INSERT INTO `t_player_money` VALUES (660734, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (661060, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (661060, 55, 0, 0);
INSERT INTO `t_player_money` VALUES (663723, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (664824, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (669767, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (671458, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (674559, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (677100, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (678070, -1, -1900, 0);
INSERT INTO `t_player_money` VALUES (678070, 0, 10100, 0);
INSERT INTO `t_player_money` VALUES (678070, 68, 0, 0);
INSERT INTO `t_player_money` VALUES (678100, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (678385, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (681399, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (683185, -1, 1300, 0);
INSERT INTO `t_player_money` VALUES (683185, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (684573, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (684573, 49, 3300, 0);
INSERT INTO `t_player_money` VALUES (684573, 56, 8883200, 0);
INSERT INTO `t_player_money` VALUES (686627, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (686627, 68, 398600, 0);
INSERT INTO `t_player_money` VALUES (686764, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (695434, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (695682, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (697431, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (698680, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (700139, 0, 200, 0);
INSERT INTO `t_player_money` VALUES (700139, 67, 199998700, 0);
INSERT INTO `t_player_money` VALUES (700744, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (701579, -1, 8600, 0);
INSERT INTO `t_player_money` VALUES (701579, 0, 9961300, 0);
INSERT INTO `t_player_money` VALUES (701579, 48, 200000000, 0);
INSERT INTO `t_player_money` VALUES (701579, 49, -3500, 0);
INSERT INTO `t_player_money` VALUES (701579, 55, 0, 0);
INSERT INTO `t_player_money` VALUES (701579, 56, 179944306, 0);
INSERT INTO `t_player_money` VALUES (702757, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (703123, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (703402, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (704039, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (704837, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (704946, -1, 200, 0);
INSERT INTO `t_player_money` VALUES (704946, 0, 600, 0);
INSERT INTO `t_player_money` VALUES (704946, 53, 199999500, 0);
INSERT INTO `t_player_money` VALUES (707218, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (713117, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (713117, 69, 0, 0);
INSERT INTO `t_player_money` VALUES (714157, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (720084, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (720206, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (723059, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (725921, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (725921, 57, 5000, 0);
INSERT INTO `t_player_money` VALUES (729925, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (730555, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (731540, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (732641, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (732948, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (733969, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (736466, -1, -4600, 0);
INSERT INTO `t_player_money` VALUES (736466, 0, 700, 0);
INSERT INTO `t_player_money` VALUES (736466, 41, 102200, 0);
INSERT INTO `t_player_money` VALUES (741129, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (741968, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (742897, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (742950, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (742950, 64, -4000, 0);
INSERT INTO `t_player_money` VALUES (743811, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (743811, 56, 2000, 0);
INSERT INTO `t_player_money` VALUES (743811, 60, 10200, 0);
INSERT INTO `t_player_money` VALUES (745754, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (745754, 64, 960000, 0);
INSERT INTO `t_player_money` VALUES (747520, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (749225, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (750731, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (753973, -1, -1800, 0);
INSERT INTO `t_player_money` VALUES (753973, 0, 400, 0);
INSERT INTO `t_player_money` VALUES (753973, 49, -2000, 0);
INSERT INTO `t_player_money` VALUES (753973, 55, 8991103, 0);
INSERT INTO `t_player_money` VALUES (753973, 56, 9979297, 0);
INSERT INTO `t_player_money` VALUES (756302, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (757072, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (760399, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (760451, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (761204, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (761390, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (763410, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (766607, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (766774, -1, 1000, 0);
INSERT INTO `t_player_money` VALUES (766774, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (767874, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (767947, -1, 2500, 0);
INSERT INTO `t_player_money` VALUES (767947, 0, 400, 0);
INSERT INTO `t_player_money` VALUES (767947, 62, 555500, 0);
INSERT INTO `t_player_money` VALUES (768535, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (772357, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (774130, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (776181, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (776820, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (779578, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (779862, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (780508, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (780508, 56, 14500, 0);
INSERT INTO `t_player_money` VALUES (780508, 60, 13300, 0);
INSERT INTO `t_player_money` VALUES (783001, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (783467, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (784411, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (784411, 65, 200000000, 0);
INSERT INTO `t_player_money` VALUES (784411, 66, 200000000, 0);
INSERT INTO `t_player_money` VALUES (792612, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (792712, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (797822, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (800545, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (800545, 60, 0, 0);
INSERT INTO `t_player_money` VALUES (808009, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (808009, 60, 10000, 0);
INSERT INTO `t_player_money` VALUES (809493, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (809621, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (816789, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (816808, 0, 5001000, 0);
INSERT INTO `t_player_money` VALUES (816808, 52, 400021000, 0);
INSERT INTO `t_player_money` VALUES (817170, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (817466, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (819342, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (820629, -1, 0, 0);
INSERT INTO `t_player_money` VALUES (820629, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (823519, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (825109, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (827090, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (827293, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (828113, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (828113, 60, 0, 0);
INSERT INTO `t_player_money` VALUES (828407, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (830308, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (830554, 0, 800, 0);
INSERT INTO `t_player_money` VALUES (832506, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (837403, -1, -1300, 0);
INSERT INTO `t_player_money` VALUES (837403, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (838031, 0, 10013400, 0);
INSERT INTO `t_player_money` VALUES (838031, 61, 0, 0);
INSERT INTO `t_player_money` VALUES (838031, 68, 199002700, 0);
INSERT INTO `t_player_money` VALUES (838031, 70, 200000000, 0);
INSERT INTO `t_player_money` VALUES (838752, -1, 900, 0);
INSERT INTO `t_player_money` VALUES (838752, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (839524, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (840472, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (841251, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (841251, 56, 10000, 0);
INSERT INTO `t_player_money` VALUES (841251, 60, 10000, 0);
INSERT INTO `t_player_money` VALUES (841507, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (841507, 59, 200000000, 0);
INSERT INTO `t_player_money` VALUES (843691, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (844291, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (848134, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (851333, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (851492, 0, 223200, 0);
INSERT INTO `t_player_money` VALUES (851492, 62, 2500000, 0);
INSERT INTO `t_player_money` VALUES (851553, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (852917, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (852949, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (852949, 55, -1500, 0);
INSERT INTO `t_player_money` VALUES (853122, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (854153, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (854851, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (856569, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (857703, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (858677, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (863026, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (866064, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (867979, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (867979, 57, 5000, 0);
INSERT INTO `t_player_money` VALUES (877140, -1, -900, 0);
INSERT INTO `t_player_money` VALUES (877140, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (878747, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (881465, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (881873, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (882326, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (887317, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (888118, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (892595, -1, 0, 0);
INSERT INTO `t_player_money` VALUES (892595, 0, 600, 0);
INSERT INTO `t_player_money` VALUES (895210, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (895706, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (897381, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (899868, -1, -3800, 0);
INSERT INTO `t_player_money` VALUES (899868, 0, 300, 0);
INSERT INTO `t_player_money` VALUES (903552, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (904998, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (904998, 64, 124400, 0);
INSERT INTO `t_player_money` VALUES (904998, 68, 499400, 0);
INSERT INTO `t_player_money` VALUES (905173, 56, 0, 0);
INSERT INTO `t_player_money` VALUES (905697, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (906589, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (907284, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (907284, 68, 98100, 0);
INSERT INTO `t_player_money` VALUES (907398, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (909466, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (909956, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (911829, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (911922, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (915282, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (915598, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (915806, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (916241, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (916546, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (917128, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (917749, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (918682, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (918682, 62, 60000, 0);
INSERT INTO `t_player_money` VALUES (919794, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (921910, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (923087, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (930332, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (930404, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (931991, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (932729, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (933627, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (934563, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (937637, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (937958, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (938385, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (938610, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (939159, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (939389, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (945623, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (947130, -1, -600, 0);
INSERT INTO `t_player_money` VALUES (947130, 0, 600, 0);
INSERT INTO `t_player_money` VALUES (949826, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (953482, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (955173, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (961263, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (964226, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (968455, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (969335, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (969335, 65, 0, 0);
INSERT INTO `t_player_money` VALUES (970412, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (970468, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (978700, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (979040, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (982399, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (983602, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (986354, -1, -200, 0);
INSERT INTO `t_player_money` VALUES (986354, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (987485, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (987684, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (992253, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (993382, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (997233, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (997385, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (998317, 0, 3500, 0);
INSERT INTO `t_player_money` VALUES (998317, 36, 180000624, 0);
INSERT INTO `t_player_money` VALUES (999386, 0, 1000, 0);
INSERT INTO `t_player_money` VALUES (999386, 67, 0, 0);

-- ----------------------------
-- Table structure for t_team_money
-- ----------------------------
DROP TABLE IF EXISTS `t_team_money`;
CREATE TABLE `t_team_money`  (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) NULL DEFAULT NULL,
  `money` bigint(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `guid`(`guid`, `club`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 129175 CHARACTER SET = utf8mb3 COLLATE = utf8mb3_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_team_money
-- ----------------------------

-- ----------------------------
-- Table structure for t_team_player_count
-- ----------------------------
DROP TABLE IF EXISTS `t_team_player_count`;
CREATE TABLE `t_team_player_count`  (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `guid` int(4) NOT NULL,
  `club` int(8) NULL DEFAULT NULL,
  `count` int(4) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `guid`(`guid`, `club`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 129175 CHARACTER SET = utf8mb3 COLLATE = utf8mb3_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_team_player_count
-- ----------------------------

-- ----------------------------
-- Table structure for t_template
-- ----------------------------
DROP TABLE IF EXISTS `t_template`;
CREATE TABLE `t_template`  (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `description` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `club` int(4) NOT NULL,
  `rule` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `game_id` int(4) NOT NULL,
  `status` int(1) NOT NULL DEFAULT 0,
  `created_time` int(8) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_club`(`club`, `game_id`, `created_time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4230 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of t_template
-- ----------------------------
INSERT INTO `t_template` VALUES (270, '托管血战', 66428602, '{\"union\":{\"tax\":{\"fixed_commission\":false,\"min_ensurance\":200,\"big_win\":[[9999900,200]],\"percentage_commission\":true},\"entry_score\":200,\"score_rate\":2},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"fan\":{\"max_option\":3},\"play\":{\"men_qing\":true,\"zi_mo_jia_fan\":true,\"hu_tips\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"da_dui_zi_fan_2\":true,\"guo_shou_peng\":false,\"exchange_tips\":false,\"dgh_zi_mo\":false,\"yao_jiu\":true,\"ready_timeout_option\":0,\"cha_da_jiao\":true,\"tian_di_hu\":true,\"zi_mo_jia_di\":false,\"dgh_dian_pao\":true},\"option\":{\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"huan\":{},\"round\":{\"option\":0}}', 200, 0, 1654655676);
INSERT INTO `t_template` VALUES (271, '斗牛', 66428602, '{\"trustee\":{\"second_opt\":0,\"type_opt\":0},\"union\":{\"tax\":{\"fixed_commission\":false,\"percentage_commission\":true,\"min_ensurance\":300,\"big_win\":[[9999900,400]]},\"score_rate\":1,\"entry_score\":1000},\"play\":{\"continue_game\":true,\"an_pai_option\":2,\"banker_take_turn\":false,\"base_score\":[10,20],\"ready_timeout_option\":0,\"call_banker_times\":4,\"no_banker_compare\":false,\"ox_times\":{\"11\":4,\"21\":5,\"25\":6,\"24\":6,\"23\":5,\"22\":5,\"28\":10,\"10\":3,\"26\":7,\"27\":8,\"2\":1,\"3\":1,\"4\":1,\"5\":1,\"6\":1,\"7\":1,\"8\":2,\"9\":2},\"call_banker\":true},\"option\":{\"block_join_when_gaming\":false,\"gps_distance\":-1,\"block_voice\":false,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"room\":{\"owner_start\":true,\"min_gamer_count\":0,\"dismiss_all_agree\":true,\"player_count_option\":0},\"pay\":{\"option\":2,\"money_type\":1},\"round\":{\"option\":0}}', 310, 0, 1654655884);
INSERT INTO `t_template` VALUES (272, '斗地主', 66428602, '{\"round\":{\"option\":0},\"play\":{\"random_call\":true,\"ready_timeout_option\":0,\"san_da_must_call\":true,\"call_score\":false,\"max_times\":2,\"san_dai_er\":false,\"san_zhang\":false,\"si_dai_er\":false,\"call_landlord\":true},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"request_dismiss\":true,\"gps_distance\":-1},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"entry_score\":203,\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"fixed_commission\":false,\"big_win\":[[100,100],[200,201],[300,202],[9999900,203]],\"min_ensurance\":200}},\"trustee\":{\"second_opt\":0,\"type_opt\":0}}', 220, 0, 1654658580);
INSERT INTO `t_template` VALUES (273, ' 卡五星', 66428602, '{\"union\":{\"tax\":{\"fixed_commission\":false,\"min_ensurance\":500,\"big_win\":[[9999900,500]],\"percentage_commission\":true},\"entry_score\":500,\"score_rate\":3},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"fan\":{\"max_option\":3},\"play\":{\"men_qing\":false,\"zi_mo_jia_fan\":true,\"hu_tips\":false,\"hu_at_least_2\":true,\"cha_xiao_jiao\":false,\"dgh_dian_pao\":true,\"jia_xin_5\":false,\"guo_zhuang_hu\":true,\"da_dui_zi_fan_2\":true,\"dgh_zi_mo\":false,\"exchange_tips\":false,\"yao_jiu\":true,\"ready_timeout_option\":0,\"tian_di_hu\":true,\"zi_mo_jia_di\":false,\"cha_da_jiao\":true},\"option\":{\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"huan\":{},\"round\":{\"option\":0}}', 202, 0, 1654659836);
INSERT INTO `t_template` VALUES (274, '托管血战', 813402, '{\"pay\":{\"money_type\":1,\"option\":2},\"huan\":{},\"play\":{\"men_qing\":true,\"zi_mo_jia_fan\":true,\"hu_tips\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"da_dui_zi_fan_2\":true,\"guo_shou_peng\":false,\"exchange_tips\":false,\"dgh_zi_mo\":false,\"yao_jiu\":true,\"ready_timeout_option\":0,\"cha_da_jiao\":true,\"tian_di_hu\":true,\"zi_mo_jia_di\":false,\"dgh_dian_pao\":true},\"round\":{\"option\":0},\"option\":{\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0}}', 200, 0, 1654675904);
INSERT INTO `t_template` VALUES (275, '1底血战到底', 63162504, '{\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"fan\":{\"max_option\":0},\"round\":{\"option\":1},\"play\":{\"yao_jiu\":false,\"cha_xiao_jiao\":false,\"ready_timeout_option\":0,\"guo_shou_peng\":false,\"hu_tips\":false,\"exchange_tips\":false,\"zi_mo_jia_fan\":true,\"dgh_dian_pao\":true,\"cha_da_jiao\":true,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_di\":false,\"guo_zhuang_hu\":false,\"tian_di_hu\":false,\"men_qing\":false,\"dgh_zi_mo\":false},\"huan\":{},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true,\"fixed_commission\":false},\"entry_score\":0},\"option\":{\"ip_stop_cheat\":true,\"block_hu_dong\":false,\"gps_distance\":-1,\"hand_ready\":true,\"owner_kickout_player\":true,\"request_dismiss\":true}}', 200, 0, 1655692731);
INSERT INTO `t_template` VALUES (276, '1底血战到底', 63162504, '{\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"fan\":{\"max_option\":0},\"round\":{\"option\":1},\"play\":{\"yao_jiu\":false,\"cha_xiao_jiao\":false,\"ready_timeout_option\":0,\"guo_shou_peng\":false,\"hu_tips\":false,\"exchange_tips\":false,\"zi_mo_jia_fan\":true,\"dgh_dian_pao\":true,\"cha_da_jiao\":true,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_di\":false,\"guo_zhuang_hu\":false,\"tian_di_hu\":false,\"men_qing\":false,\"dgh_zi_mo\":false},\"huan\":{},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"option\":{\"ip_stop_cheat\":true,\"block_hu_dong\":false,\"gps_distance\":-1,\"hand_ready\":true,\"owner_kickout_player\":true,\"request_dismiss\":true}}', 200, 0, 1655692810);
INSERT INTO `t_template` VALUES (277, 'pdk2', 85665832, '{\"trustee\":{},\"option\":{\"block_hu_dong\":false,\"request_dismiss\":true,\"hand_ready\":true,\"owner_kickout_player\":true},\"pay\":{\"option\":2,\"money_type\":1},\"room\":{\"player_count_option\":0},\"round\":{\"option\":0},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"play\":{\"zhuang\":{\"normal_round\":0,\"first_round\":3},\"card_num\":16,\"fan_chun\":true,\"bomb_score\":5,\"must_discard\":false,\"AAA_is_bomb\":false,\"ready_timeout_option\":0,\"plane_with_mix\":true,\"abandon_3_4\":false,\"lastone_not_consume\":false,\"si_dai_san\":false,\"si_dai_er\":false,\"san_dai_yi\":false}}', 210, 0, 1655974394);
INSERT INTO `t_template` VALUES (278, 'xzmj', 81378004, '{\"trustee\":{\"second_opt\":0,\"type_opt\":0},\"play\":{\"exchange_tips\":false,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true,\"yao_jiu\":false,\"men_qing\":false,\"guo_shou_peng\":false,\"guo_zhuang_hu\":true,\"ready_timeout_option\":1,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_di\":false,\"tian_di_hu\":false,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true,\"hu_tips\":true},\"pay\":{\"option\":2,\"money_type\":1},\"round\":{\"option\":0},\"option\":{\"request_dismiss\":true,\"ip_stop_cheat\":false,\"gps_distance\":-1,\"block_hu_dong\":false,\"owner_kickout_player\":true,\"hand_ready\":true},\"fan\":{\"max_option\":0},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"huan\":{\"count_opt\":0,\"type_opt\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false,\"auto_dismiss\":{\"trustee_round\":2}}}', 200, 0, 1657709446);
INSERT INTO `t_template` VALUES (279, '3r2f', 81378004, '{\"play\":{\"cha_da_jiao\":true,\"tian_di_hu\":false,\"yao_jiu\":false,\"hu_at_least_2\":false,\"guo_zhuang_hu\":false,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true,\"da_dui_zi_fan_2\":false,\"exchange_tips\":false,\"zi_mo_jia_di\":false,\"dgh_zi_mo\":false,\"jia_xin_5\":false,\"ready_timeout_option\":0,\"men_qing\":false,\"hu_tips\":false},\"union\":{\"entry_score\":0,\"tax\":{\"big_win\":[[9999900,0]],\"fixed_commission\":false,\"percentage_commission\":true,\"min_ensurance\":0},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 202, 0, 1657710112);
INSERT INTO `t_template` VALUES (280, '4r2f', 81378004, '{\"play\":{\"cha_da_jiao\":true,\"tian_di_hu\":false,\"yao_jiu\":true,\"hu_tips\":true,\"tile_count\":13,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true,\"zhuan_gang\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"men_qing\":true,\"ka_er_tiao\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"si_dui\":false},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 201, 0, 1657710142);
INSERT INTO `t_template` VALUES (281, '2r3f', 81378004, '{\"huan\":{},\"trustee\":{},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"option\":{\"hand_ready\":true,\"request_dismiss\":false,\"owner_kickout_player\":true,\"block_hu_dong\":true},\"pay\":{\"option\":2,\"money_type\":1},\"round\":{\"option\":0},\"union\":{\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0,\"score_rate\":1},\"play\":{\"da_dui_zi_fan_2\":true,\"men_qing\":true,\"hu_tips\":true,\"jia_xin_5\":true,\"exchange_tips\":true,\"ready_timeout_option\":0,\"dgh_dian_pao\":true,\"dgh_zi_mo\":false,\"cha_da_jiao\":true,\"yao_jiu\":true,\"tian_di_hu\":true,\"hu_at_least_2\":true,\"zi_mo_jia_di\":false,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true}}', 203, 0, 1657710207);
INSERT INTO `t_template` VALUES (282, '2r2f', 81378004, '{\"huan\":{},\"trustee\":{},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"block_hu_dong\":false},\"pay\":{\"option\":2,\"money_type\":1},\"round\":{\"option\":0},\"union\":{\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0,\"score_rate\":1},\"play\":{\"exchange_tips\":false,\"men_qing\":false,\"hu_tips\":true,\"dgh_zi_mo\":false,\"da_dui_zi_fan_2\":false,\"ready_timeout_option\":0,\"dgh_dian_pao\":true,\"cha_da_jiao\":true,\"tian_di_hu\":false,\"yao_jiu\":false,\"hu_at_least_2\":false,\"zi_mo_jia_di\":false,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true}}', 204, 0, 1657710266);
INSERT INTO `t_template` VALUES (283, 'niuniu', 81378004, '{\"room\":{\"owner_start\":true,\"dismiss_all_agree\":true,\"player_count_option\":0,\"min_gamer_count\":0},\"round\":{\"option\":0},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"union\":{\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"score_rate\":1},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"gps_distance\":-1,\"block_voice\":false,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_join_when_gaming\":false,\"block_hu_dong\":false},\"play\":{\"an_pai_option\":0,\"call_banker\":true,\"continue_game\":true,\"banker_take_turn\":false,\"base_score\":[5,10],\"ready_timeout_option\":0,\"ox_times\":{\"27\":8,\"28\":10,\"26\":7,\"25\":0,\"24\":6,\"23\":5,\"2\":1,\"5\":1,\"10\":3,\"3\":1,\"8\":2,\"7\":1,\"6\":1,\"9\":2,\"4\":1,\"11\":4,\"21\":5,\"22\":5},\"call_banker_times\":3,\"no_banker_compare\":false}}', 310, 1, 1657715132);
INSERT INTO `t_template` VALUES (284, 'yjmj', 81378004, '{\"play\":{\"cha_da_jiao\":true,\"tian_di_hu\":false,\"guo_zhuang_hu\":false,\"jin_gou_gou\":false,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false,\"hai_di\":false,\"zi_mo_jia_fan\":true,\"exchange_tips\":false,\"zi_mo_jia_di\":false,\"men_qing\":true,\"hu_tips\":false,\"ready_timeout_option\":0,\"zhong_zhang\":true,\"dgh_zi_mo\":false},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 230, 0, 1657715310);
INSERT INTO `t_template` VALUES (285, '发反反复复', 81378004, '{\"play\":{\"cha_da_jiao\":true,\"tian_di_hu\":false,\"yao_jiu\":false,\"hu_at_least_2\":false,\"guo_zhuang_hu\":false,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true,\"da_dui_zi_fan_2\":false,\"exchange_tips\":false,\"zi_mo_jia_di\":false,\"dgh_zi_mo\":false,\"jia_xin_5\":false,\"ready_timeout_option\":0,\"men_qing\":false,\"hu_tips\":false},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 202, 0, 1657790472);
INSERT INTO `t_template` VALUES (286, '血战麻将', 67975768, '{\"play\":{\"cha_da_jiao\":true,\"tian_di_hu\":true,\"yao_jiu\":true,\"da_dui_zi_fan_2\":true,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true,\"guo_zhuang_hu\":true,\"exchange_tips\":true,\"zi_mo_jia_di\":false,\"dgh_zi_mo\":false,\"guo_shou_peng\":true,\"ready_timeout_option\":0,\"men_qing\":true,\"hu_tips\":true},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":false,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{\"second_opt\":0,\"type_opt\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0}}', 200, 0, 1657794825);
INSERT INTO `t_template` VALUES (287, '斗地主', 67975768, '{\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"play\":{\"random_call\":false,\"si_dai_er\":false,\"max_times\":0,\"san_zhang\":false,\"san_da_must_call\":false,\"call_score\":false,\"ready_timeout_option\":0,\"san_dai_er\":false,\"call_landlord\":true},\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 220, 0, 1657868509);
INSERT INTO `t_template` VALUES (288, '四人两房', 67975768, '{\"play\":{\"cha_da_jiao\":true,\"tian_di_hu\":false,\"yao_jiu\":false,\"hu_tips\":false,\"tile_count\":13,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true,\"zhuan_gang\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"men_qing\":false,\"ka_er_tiao\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"si_dui\":false},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"gps_distance\":-1,\"request_dismiss\":true,\"owner_kickout_player\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 201, 0, 1657868536);
INSERT INTO `t_template` VALUES (289, '恶人一方', 67975768, '{\"play\":{\"tile_men\":0,\"tian_di_hu\":false,\"dgh_dian_pao\":true,\"jia_xin_5\":false,\"tile_count\":13,\"zi_mo_jia_di\":false,\"dgh_zi_mo\":false,\"ready_timeout_option\":0,\"yao_jiu\":false,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"si_dui\":false,\"cha_da_jiao\":true,\"da_dui_zi_fan_2\":false,\"hu_tips\":false,\"men_qing\":false,\"zi_mo_jia_fan\":true,\"qing_yi_se_fan\":0},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"fan\":{\"max_option\":0},\"round\":{\"option\":0},\"huan\":{},\"option\":{\"owner_kickout_player\":true,\"hand_ready\":true,\"block_hu_dong\":false,\"request_dismiss\":true},\"trustee\":{},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0}}', 205, 0, 1657868636);
INSERT INTO `t_template` VALUES (290, 'paodek ', 67975768, '{\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"play\":{\"must_discard\":false,\"si_dai_san\":false,\"si_dai_er\":false,\"abandon_3_4\":false,\"san_dai_yi\":false,\"plane_with_mix\":true,\"fan_chun\":true,\"zhuang\":{\"normal_round\":0,\"first_round\":3},\"AAA_is_bomb\":false,\"card_num\":16,\"ready_timeout_option\":0,\"bomb_score\":5,\"lastone_not_consume\":false},\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"option\":{\"owner_kickout_player\":true,\"hand_ready\":true,\"block_hu_dong\":false,\"request_dismiss\":true},\"trustee\":{},\"room\":{\"player_count_option\":0}}', 210, 0, 1657869366);
INSERT INTO `t_template` VALUES (291, 'xzmj', 68057792, '{\"round\":{\"option\":0},\"play\":{\"tian_di_hu\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"zi_mo_jia_di\":false,\"hu_tips\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"guo_shou_peng\":false,\"exchange_tips\":false,\"da_dui_zi_fan_2\":false,\"ready_timeout_option\":0,\"cha_da_jiao\":true,\"cha_xiao_jiao\":false,\"men_qing\":false,\"dgh_zi_mo\":false},\"huan\":{},\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"gps_distance\":-1,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"request_dismiss\":true},\"pay\":{\"option\":2,\"money_type\":1},\"fan\":{\"max_option\":1},\"trustee\":{},\"union\":{\"entry_score\":0,\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 200, 1, 1658325425);
INSERT INTO `t_template` VALUES (292, 'aqqq', 68057792, '{\"round\":{\"option\":0},\"play\":{\"tian_di_hu\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"zi_mo_jia_di\":false,\"hu_tips\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"guo_shou_peng\":false,\"exchange_tips\":false,\"da_dui_zi_fan_2\":false,\"ready_timeout_option\":0,\"cha_da_jiao\":true,\"cha_xiao_jiao\":false,\"men_qing\":false,\"dgh_zi_mo\":false},\"huan\":{},\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"gps_distance\":-1,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"request_dismiss\":true},\"pay\":{\"option\":2,\"money_type\":1},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 200, 0, 1658325617);
INSERT INTO `t_template` VALUES (293, '2r3f血战', 63162504, '{\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"request_dismiss\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"owner_kickout_player\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"zi_mo_jia_di\":false,\"dgh_zi_mo\":false,\"jia_xin_5\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"hu_at_least_2\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 203, 0, 1658918579);
INSERT INTO `t_template` VALUES (294, '2pdkt3', 81378004, '{\"room\":{\"auto_dismiss\":{\"trustee_round\":3},\"player_count_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"play\":{\"san_dai_yi\":false,\"abandon_3_4\":false,\"lastone_not_consume\":false,\"si_dai_san\":false,\"si_dai_er\":false,\"ready_timeout_option\":0,\"fan_chun\":true,\"AAA_is_bomb\":false,\"bomb_score\":5,\"must_discard\":false,\"zhuang\":{\"first_round\":3,\"normal_round\":0},\"plane_with_mix\":true,\"card_num\":16},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"request_dismiss\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"owner_kickout_player\":true},\"trustee\":{\"type_opt\":0,\"second_opt\":0}}', 210, 0, 1659088597);
INSERT INTO `t_template` VALUES (295, '2pdkt4', 81378004, '{\"room\":{\"auto_dismiss\":{\"trustee_round\":4},\"player_count_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"play\":{\"san_dai_yi\":false,\"abandon_3_4\":false,\"lastone_not_consume\":false,\"si_dai_san\":false,\"si_dai_er\":false,\"ready_timeout_option\":0,\"fan_chun\":true,\"AAA_is_bomb\":false,\"bomb_score\":5,\"must_discard\":false,\"zhuang\":{\"first_round\":3,\"normal_round\":0},\"plane_with_mix\":true,\"card_num\":16},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"request_dismiss\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"owner_kickout_player\":true},\"trustee\":{\"type_opt\":0,\"second_opt\":0}}', 210, 0, 1659088670);
INSERT INTO `t_template` VALUES (296, 'xzmj_gzh', 88603133, '{\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"play\":{\"zi_mo_jia_di\":false,\"cha_da_jiao\":true,\"cha_xiao_jiao\":false,\"dgh_zi_mo\":false,\"hu_tips\":true,\"guo_shou_peng\":true,\"zi_mo_jia_fan\":true,\"guo_zhuang_hu\":true,\"exchange_tips\":false,\"men_qing\":true,\"yao_jiu\":true,\"da_dui_zi_fan_2\":true,\"dgh_dian_pao\":true,\"ready_timeout_option\":2,\"tian_di_hu\":true},\"pay\":{\"money_type\":1,\"option\":2},\"huan\":{},\"trustee\":{},\"fan\":{\"max_option\":0},\"union\":{\"entry_score\":0,\"tax\":{\"min_ensurance\":0,\"percentage_commission\":true,\"fixed_commission\":false,\"big_win\":[[9999900,0]]},\"score_rate\":1},\"option\":{\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"request_dismiss\":true},\"round\":{\"option\":0}}', 200, 0, 1659704662);
INSERT INTO `t_template` VALUES (297, '12423423', 81378004, '{\"room\":{\"dismiss_all_agree\":true,\"min_gamer_count\":0,\"player_count_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"play\":{\"men_turn_option\":0,\"bonus_bao_zi\":false,\"bonus_shunjin\":false,\"baozi_less_than_235\":true,\"ready_timeout_option\":0,\"trustee_drop\":true,\"trustee_follow\":false,\"small_A23\":true,\"lose_compare_first\":true,\"color_compare\":false,\"chip_score\":[2,3,4],\"continue_game\":true,\"base_men_score\":1,\"can_add_score_in_men_turns\":true,\"double_compare\":false,\"show_card\":false,\"base_score\":5,\"max_turn_option\":0},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"request_dismiss\":true,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_join_when_gaming\":false,\"block_voice\":false},\"trustee\":{}}', 300, 0, 1659759728);
INSERT INTO `t_template` VALUES (298, 'ddz1', 81378004, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"play\":{\"san_zhang\":false,\"call_score\":false,\"san_da_must_call\":false,\"si_dai_er\":false,\"ready_timeout_option\":0,\"random_call\":false,\"max_times\":0,\"san_dai_er\":false,\"call_landlord\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"trustee\":{}}', 220, 0, 1659760129);
INSERT INTO `t_template` VALUES (299, 'ddzroom', 65882523, '{\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"request_dismiss\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"owner_kickout_player\":true},\"play\":{\"hu_tips\":false,\"tile_count\":13,\"tile_men\":0,\"ready_timeout_option\":0,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"si_dui\":false,\"tian_di_hu\":false,\"dgh_zi_mo\":false,\"jia_xin_5\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"cha_da_jiao\":true,\"hu_at_least_2\":false,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"qing_yi_se_fan\":0,\"zi_mo_jia_di\":false},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 205, 1, 1660042026);
INSERT INTO `t_template` VALUES (300, '2pdk', 813402, '{\"room\":{\"player_count_option\":0},\"play\":{\"san_dai_yi\":false,\"abandon_3_4\":false,\"lastone_not_consume\":false,\"si_dai_san\":false,\"si_dai_er\":false,\"ready_timeout_option\":0,\"fan_chun\":true,\"AAA_is_bomb\":false,\"bomb_score\":5,\"must_discard\":false,\"zhuang\":{\"first_round\":3,\"normal_round\":0},\"plane_with_mix\":true,\"card_num\":16},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"request_dismiss\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"owner_kickout_player\":true},\"trustee\":{\"type_opt\":0,\"second_opt\":0}}', 210, 0, 1660744331);
INSERT INTO `t_template` VALUES (301, '111', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916766);
INSERT INTO `t_template` VALUES (302, '222', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"zi_mo_jia_di\":false,\"zhuan_gang\":false,\"dgh_zi_mo\":false,\"ka_er_tiao\":false,\"men_qing\":false,\"tile_count\":13,\"cha_xiao_jiao\":false,\"da_dui_zi_fan_2\":false,\"ready_timeout_option\":0,\"si_dui\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 201, 1, 1660916802);
INSERT INTO `t_template` VALUES (303, '333', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"zi_mo_jia_di\":false,\"guo_zhuang_hu\":false,\"dgh_zi_mo\":false,\"jia_xin_5\":false,\"exchange_tips\":false,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"da_dui_zi_fan_2\":false,\"ready_timeout_option\":0,\"men_qing\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 202, 1, 1660916818);
INSERT INTO `t_template` VALUES (304, '444', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916862);
INSERT INTO `t_template` VALUES (305, '555', 65882523, '{\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"request_dismiss\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"owner_kickout_player\":true},\"play\":{\"hu_tips\":false,\"tile_count\":13,\"tile_men\":0,\"ready_timeout_option\":0,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"si_dui\":false,\"tian_di_hu\":false,\"dgh_zi_mo\":false,\"jia_xin_5\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"cha_da_jiao\":true,\"hu_at_least_2\":false,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"qing_yi_se_fan\":0,\"zi_mo_jia_di\":false},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 205, 1, 1660916879);
INSERT INTO `t_template` VALUES (306, '666', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916895);
INSERT INTO `t_template` VALUES (307, '777', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916903);
INSERT INTO `t_template` VALUES (308, '888', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916909);
INSERT INTO `t_template` VALUES (309, 'aaa', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916950);
INSERT INTO `t_template` VALUES (310, 'bbb', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660916975);
INSERT INTO `t_template` VALUES (311, 'ggg', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917000);
INSERT INTO `t_template` VALUES (312, 'uuu', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917193);
INSERT INTO `t_template` VALUES (313, 'yyy', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917200);
INSERT INTO `t_template` VALUES (314, 'ccc', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917210);
INSERT INTO `t_template` VALUES (315, 'ttt', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917219);
INSERT INTO `t_template` VALUES (316, 'ccc', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917242);
INSERT INTO `t_template` VALUES (317, 'fffc', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917257);
INSERT INTO `t_template` VALUES (318, 'zzz', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917279);
INSERT INTO `t_template` VALUES (319, 'ccfdfsfw', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917290);
INSERT INTO `t_template` VALUES (320, '读书的根深蒂固', 65882523, '{\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"huan\":{},\"trustee\":{},\"option\":{\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"request_dismiss\":true},\"play\":{\"hu_tips\":false,\"tian_di_hu\":false,\"guo_shou_peng\":false,\"dgh_zi_mo\":false,\"zi_mo_jia_di\":false,\"exchange_tips\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"guo_zhuang_hu\":false,\"ready_timeout_option\":0,\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"yao_jiu\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true},\"round\":{\"option\":0},\"pay\":{\"option\":2,\"money_type\":1}}', 200, 1, 1660917321);
INSERT INTO `t_template` VALUES (321, '0.5米血战', 88603133, '{\"round\":{\"option\":0},\"huan\":{},\"pay\":{\"option\":2,\"money_type\":1},\"trustee\":{},\"fan\":{\"max_option\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"union\":{\"score_rate\":0.5,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"fixed_commission\":false,\"min_ensurance\":0,\"big_win\":[[9999900,0]]}},\"option\":{\"gps_distance\":-1,\"hand_ready\":true,\"request_dismiss\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"block_hu_dong\":false},\"play\":{\"guo_shou_peng\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"hu_tips\":true,\"exchange_tips\":true,\"yao_jiu\":true,\"tian_di_hu\":true,\"da_dui_zi_fan_2\":true,\"cha_da_jiao\":true,\"guo_zhuang_hu\":true,\"men_qing\":true,\"zi_mo_jia_fan\":true,\"zi_mo_jia_di\":false,\"dgh_dian_pao\":true,\"cha_xiao_jiao\":false}}', 200, 0, 1662089852);
INSERT INTO `t_template` VALUES (322, '1米血战', 88603133, '{\"play\":{\"tian_di_hu\":true,\"da_dui_zi_fan_2\":true,\"dgh_zi_mo\":false,\"cha_da_jiao\":true,\"yao_jiu\":true,\"dgh_dian_pao\":true,\"men_qing\":true,\"ready_timeout_option\":0,\"guo_zhuang_hu\":true,\"zi_mo_jia_di\":false,\"exchange_tips\":true,\"guo_shou_peng\":true,\"hu_tips\":true,\"zi_mo_jia_fan\":true,\"cha_xiao_jiao\":false},\"huan\":{\"count_opt\":0,\"type_opt\":1},\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"big_win\":[[9999900,0]],\"min_ensurance\":0,\"fixed_commission\":false,\"percentage_commission\":true}},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{\"type_opt\":0,\"second_opt\":1},\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"request_dismiss\":true,\"ip_stop_cheat\":false,\"gps_distance\":-1,\"owner_kickout_player\":true}}', 200, 0, 1662112255);
INSERT INTO `t_template` VALUES (323, '3r2f5米血战', 88603133, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"gps_distance\":-1},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":5,\"tax\":{\"min_ensurance\":0,\"big_win\":[[9999900,0]],\"percentage_commission\":true,\"fixed_commission\":false},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"play\":{\"jia_xin_5\":true,\"zi_mo_jia_di\":false,\"zi_mo_jia_fan\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":true,\"da_dui_zi_fan_2\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 202, 0, 1662112299);
INSERT INTO `t_template` VALUES (324, '2r2f1米血战', 88603133, '{\"huan\":{},\"trustee\":{\"second_opt\":0,\"type_opt\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"fan\":{\"max_option\":0},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"block_hu_dong\":false},\"pay\":{\"option\":2,\"money_type\":1},\"round\":{\"option\":0},\"union\":{\"tax\":{\"big_win\":[[9999900,0]],\"min_ensurance\":0,\"percentage_commission\":true,\"fixed_commission\":false},\"entry_score\":0,\"score_rate\":1},\"play\":{\"exchange_tips\":true,\"men_qing\":true,\"hu_tips\":true,\"dgh_zi_mo\":false,\"da_dui_zi_fan_2\":true,\"ready_timeout_option\":0,\"dgh_dian_pao\":true,\"cha_da_jiao\":true,\"tian_di_hu\":true,\"yao_jiu\":true,\"hu_at_least_2\":true,\"zi_mo_jia_di\":false,\"cha_xiao_jiao\":false,\"zi_mo_jia_fan\":true}}', 204, 0, 1662112347);
INSERT INTO `t_template` VALUES (325, '2rpdk', 88603133, '{\"play\":{\"si_dai_san\":false,\"ready_timeout_option\":0,\"must_discard\":false,\"plane_with_mix\":true,\"bomb_score\":5,\"san_dai_yi\":false,\"si_dai_er\":false,\"lastone_not_consume\":false,\"card_num\":16,\"abandon_3_4\":false,\"AAA_is_bomb\":false,\"zhuang\":{\"normal_round\":0,\"first_round\":3},\"fan_chun\":true},\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"owner_kickout_player\":true,\"request_dismiss\":true},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"big_win\":[[9999900,0]],\"min_ensurance\":0,\"fixed_commission\":false,\"percentage_commission\":true}},\"room\":{\"player_count_option\":0},\"trustee\":{},\"round\":{\"option\":0}}', 210, 0, 1662112375);
INSERT INTO `t_template` VALUES (326, 'pdk', 88603133, '{\"play\":{\"si_dai_san\":false,\"bomb_score\":5,\"ready_timeout_option\":0,\"bao_dan_discard_max\":false,\"plane_with_mix\":true,\"must_discard\":false,\"san_dai_yi\":false,\"si_dai_er\":false,\"first_discard\":{\"with_3\":false},\"AAA_is_bomb\":false,\"lastone_not_consume\":false,\"card_num\":16,\"zhuang\":{\"normal_round\":2,\"first_round\":2},\"fan_chun\":true},\"option\":{\"gps_distance\":-1,\"block_hu_dong\":false,\"request_dismiss\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"hand_ready\":true},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"round\":{\"option\":0}}', 211, 0, 1662112395);
INSERT INTO `t_template` VALUES (327, 'scpdk', 88603133, '{\"play\":{\"bomb_score\":[5,10],\"zi_mei_dui\":false,\"ready_timeout_option\":0,\"special_score\":0,\"bomb_type_option\":0,\"lai_zi\":false,\"first_discard\":{\"with_5\":false},\"que_yi_se\":false,\"lastone_not_consume\":false,\"fan_chun\":true,\"zhuang\":{\"normal_round\":2},\"zha_niao\":false},\"option\":{\"gps_distance\":-1,\"block_hu_dong\":false,\"request_dismiss\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"hand_ready\":true},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"round\":{\"option\":0}}', 212, 0, 1662112413);
INSERT INTO `t_template` VALUES (328, '斗地主', 88603133, '{\"play\":{\"call_landlord\":true,\"random_call\":false,\"san_zhang\":false,\"san_dai_er\":false,\"san_da_must_call\":false,\"max_times\":0,\"si_dai_er\":false,\"call_score\":false,\"ready_timeout_option\":0},\"option\":{\"gps_distance\":-1,\"block_hu_dong\":false,\"request_dismiss\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"hand_ready\":true},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"round\":{\"option\":0}}', 220, 0, 1662112440);
INSERT INTO `t_template` VALUES (329, '幺鸡麻将', 88603133, '{\"play\":{\"tian_di_hu\":true,\"dgh_zi_mo\":false,\"cha_da_jiao\":true,\"hu_tips\":true,\"dgh_dian_pao\":true,\"ready_timeout_option\":0,\"zi_mo_jia_fan\":true,\"zhong_zhang\":true,\"exchange_tips\":false,\"zi_mo_jia_di\":false,\"hai_di\":true,\"guo_zhuang_hu\":true,\"jin_gou_gou\":true,\"cha_xiao_jiao\":false,\"men_qing\":true},\"huan\":{},\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"request_dismiss\":true,\"ip_stop_cheat\":false,\"gps_distance\":-1,\"owner_kickout_player\":true}}', 230, 0, 1662112476);
INSERT INTO `t_template` VALUES (330, '三张牌', 88603133, '{\"trustee\":{},\"room\":{\"dismiss_all_agree\":true,\"min_gamer_count\":0,\"player_count_option\":0},\"option\":{\"gps_distance\":-1,\"block_hu_dong\":false,\"block_voice\":false,\"ip_stop_cheat\":false,\"block_join_when_gaming\":false,\"owner_kickout_player\":true,\"request_dismiss\":true},\"union\":{\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0,\"score_rate\":1},\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"play\":{\"baozi_less_than_235\":false,\"men_turn_option\":4,\"lose_compare_first\":true,\"trustee_follow\":false,\"bonus_shunjin\":false,\"max_turn_option\":0,\"ready_timeout_option\":0,\"trustee_drop\":true,\"base_score\":1,\"double_compare\":false,\"small_A23\":false,\"base_men_score\":1,\"chip_score\":[2,3,4],\"can_add_score_in_men_turns\":true,\"color_compare\":false,\"continue_game\":true,\"bonus_bao_zi\":false,\"show_card\":false}}', 300, 0, 1662123423);
INSERT INTO `t_template` VALUES (331, '拼十', 88603133, '{\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"round\":{\"option\":0},\"room\":{\"player_count_option\":1,\"min_gamer_count\":3,\"dismiss_all_agree\":true},\"play\":{\"no_banker_compare\":false,\"call_banker\":true,\"banker_take_turn\":false,\"ready_timeout_option\":0,\"continue_game\":true,\"ox_times\":{\"11\":4,\"21\":5,\"2\":1,\"3\":1,\"4\":1,\"5\":1,\"6\":1,\"7\":1,\"8\":2,\"9\":2,\"26\":7,\"27\":8,\"28\":10,\"10\":3,\"23\":5,\"22\":5,\"25\":6,\"24\":6},\"an_pai_option\":0,\"call_banker_times\":2,\"base_score\":[1,2]},\"option\":{\"block_hu_dong\":false,\"gps_distance\":-1,\"owner_kickout_player\":true,\"block_voice\":false,\"ip_stop_cheat\":false,\"block_join_when_gaming\":false},\"pay\":{\"money_type\":1,\"option\":2}}', 310, 0, 1662123444);
INSERT INTO `t_template` VALUES (332, 'scpdkt30', 85665832, '{\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"play\":{\"lastone_not_consume\":false,\"zi_mei_dui\":false,\"special_score\":0,\"ready_timeout_option\":0,\"fan_chun\":true,\"zhuang\":{\"normal_round\":2},\"bomb_score\":[5,10],\"bomb_type_option\":0,\"first_discard\":{\"with_5\":false},\"que_yi_se\":false,\"zha_niao\":false,\"lai_zi\":false},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{\"second_opt\":0,\"type_opt\":0},\"option\":{\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"block_hu_dong\":false,\"hand_ready\":true,\"gps_distance\":-1,\"request_dismiss\":true},\"round\":{\"option\":0}}', 212, 0, 1662692964);
INSERT INTO `t_template` VALUES (333, '四人两房', 690812, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"gps_distance\":-1},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"zi_mo_jia_di\":false,\"da_dui_zi_fan_2\":false,\"dgh_dian_pao\":true,\"zi_mo_jia_fan\":true,\"dgh_zi_mo\":false,\"ready_timeout_option\":0,\"tian_di_hu\":false,\"hu_tips\":false,\"cha_xiao_jiao\":false,\"ka_er_tiao\":false,\"si_dui\":false,\"zhuan_gang\":false,\"men_qing\":false,\"tile_count\":13,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 201, 0, 1667297721);
INSERT INTO `t_template` VALUES (334, '三人两房', 690812, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"gps_distance\":-1},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"trustee\":{},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"jia_xin_5\":false,\"zi_mo_jia_di\":false,\"zi_mo_jia_fan\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"da_dui_zi_fan_2\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 202, 0, 1667297791);
INSERT INTO `t_template` VALUES (335, '两人三房', 690812, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"owner_kickout_player\":true,\"request_dismiss\":true,\"block_hu_dong\":false},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":true},\"trustee\":{},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"jia_xin_5\":false,\"zi_mo_jia_di\":false,\"zi_mo_jia_fan\":true,\"dgh_zi_mo\":false,\"ready_timeout_option\":0,\"dgh_dian_pao\":true,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"da_dui_zi_fan_2\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 203, 0, 1667297807);
INSERT INTO `t_template` VALUES (336, '两人两房', 690812, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"owner_kickout_player\":true,\"request_dismiss\":true,\"block_hu_dong\":false},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":true},\"trustee\":{},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"zi_mo_jia_di\":false,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"zi_mo_jia_fan\":true,\"dgh_dian_pao\":true,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"da_dui_zi_fan_2\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 204, 0, 1667297823);
INSERT INTO `t_template` VALUES (337, '二人一房', 690812, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"owner_kickout_player\":true,\"request_dismiss\":true,\"block_hu_dong\":false},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":true},\"trustee\":{},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"ready_timeout_option\":0,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"tile_count\":13,\"yao_jiu\":false,\"jia_xin_5\":false,\"zi_mo_jia_di\":false,\"hu_at_least_2\":false,\"dgh_zi_mo\":false,\"qing_yi_se_fan\":0,\"si_dui\":false,\"tile_men\":0,\"da_dui_zi_fan_2\":false,\"men_qing\":false,\"zi_mo_jia_fan\":true,\"dgh_dian_pao\":true,\"cha_da_jiao\":true}}', 205, 0, 1667297838);
INSERT INTO `t_template` VALUES (338, '拼十', 690812, '{\"option\":{\"gps_distance\":-1,\"block_voice\":false,\"owner_kickout_player\":true,\"block_join_when_gaming\":false,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0,\"owner_start\":true,\"min_gamer_count\":0},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"no_banker_compare\":false,\"base_score\":[1,2],\"ready_timeout_option\":0,\"call_banker_times\":2,\"call_banker\":true,\"banker_take_turn\":false,\"continue_game\":true,\"an_pai_option\":0,\"ox_times\":{\"3\":1,\"2\":1,\"5\":1,\"4\":1,\"7\":1,\"6\":1,\"9\":2,\"8\":2,\"21\":5,\"11\":4,\"10\":3,\"25\":6,\"24\":6,\"27\":8,\"26\":7,\"23\":5,\"28\":10,\"22\":5}}}', 310, 0, 1667297859);
INSERT INTO `t_template` VALUES (339, '2', 69793347, '{\"option\":{\"hand_ready\":true,\"block_hu_dong\":false,\"request_dismiss\":true,\"owner_kickout_player\":true},\"trustee\":{},\"room\":{\"player_count_option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"card_num\":16,\"must_discard\":false,\"ready_timeout_option\":0,\"zhuang\":{\"first_round\":3,\"normal_round\":0},\"abandon_3_4\":false,\"si_dai_er\":false,\"bomb_score\":5,\"AAA_is_bomb\":false,\"fan_chun\":true,\"lastone_not_consume\":false,\"san_dai_yi\":false,\"plane_with_mix\":true,\"si_dai_san\":false}}', 210, 0, 1667567989);
INSERT INTO `t_template` VALUES (340, '4人', 69793347, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":1,\"tax\":{\"min_ensurance\":0,\"big_win\":[[9999900,0]],\"percentage_commission\":true,\"fixed_commission\":false},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"play\":{\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"guo_shou_peng\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"zi_mo_jia_di\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 200, 0, 1667568651);
INSERT INTO `t_template` VALUES (341, '三人两房', 67262628, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"gps_distance\":-1},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"play\":{\"jia_xin_5\":false,\"zi_mo_jia_di\":false,\"zi_mo_jia_fan\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"hu_at_least_2\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"da_dui_zi_fan_2\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 202, 0, 1667968130);
INSERT INTO `t_template` VALUES (342, '斗地主', 67262628, '{\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"gps_distance\":-1},\"trustee\":{},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"max_times\":0,\"ready_timeout_option\":0,\"san_zhang\":false,\"random_call\":false,\"si_dai_er\":false,\"call_landlord\":true,\"call_score\":false,\"san_dai_er\":false,\"san_da_must_call\":false}}', 220, 0, 1667968152);
INSERT INTO `t_template` VALUES (343, '麻将', 67262628, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":2,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"play\":{\"zi_mo_jia_di\":false,\"ready_timeout_option\":0,\"zi_mo_jia_fan\":true,\"dgh_zi_mo\":false,\"hai_di\":false,\"guo_zhuang_hu\":false,\"zhong_zhang\":true,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"men_qing\":true,\"exchange_tips\":false,\"tian_di_hu\":false,\"jin_gou_gou\":false,\"dgh_dian_pao\":true,\"cha_da_jiao\":true}}', 230, 0, 1667968843);
INSERT INTO `t_template` VALUES (344, '牛牛1', 81378004, '{\"option\":{\"gps_distance\":-1,\"block_voice\":false,\"owner_kickout_player\":true,\"block_join_when_gaming\":false,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0,\"owner_start\":true,\"min_gamer_count\":0},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"no_banker_compare\":false,\"base_score\":[1,2],\"ready_timeout_option\":0,\"call_banker_times\":2,\"call_banker\":true,\"banker_take_turn\":false,\"continue_game\":true,\"an_pai_option\":0,\"ox_times\":{\"3\":1,\"2\":1,\"5\":1,\"4\":1,\"7\":1,\"6\":1,\"9\":2,\"8\":2,\"21\":5,\"11\":4,\"10\":3,\"25\":6,\"24\":6,\"27\":8,\"26\":7,\"23\":5,\"28\":10,\"22\":5}}}', 310, 1, 1667982120);
INSERT INTO `t_template` VALUES (345, 'niuniu3', 81378004, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":1,\"tax\":{\"min_ensurance\":100,\"big_win\":[[9999900,0]],\"percentage_commission\":true,\"fixed_commission\":false},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"play\":{\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"guo_shou_peng\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"zi_mo_jia_di\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 200, 1, 1668162577);
INSERT INTO `t_template` VALUES (346, 'niuniu', 81378004, '{\"option\":{\"gps_distance\":-1,\"block_voice\":false,\"owner_kickout_player\":true,\"block_join_when_gaming\":false,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"room\":{\"dismiss_all_agree\":true,\"owner_start\":true,\"player_count_option\":0,\"min_gamer_count\":0},\"union\":{\"score_rate\":2,\"tax\":{\"percentage_commission\":true,\"AA\":0,\"fixed_commission\":false},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"no_banker_compare\":false,\"base_score\":[1,2],\"ready_timeout_option\":0,\"call_banker_times\":2,\"call_banker\":true,\"banker_take_turn\":false,\"an_pai_option\":0,\"continue_game\":true,\"ox_times\":{\"3\":1,\"2\":1,\"5\":1,\"4\":1,\"7\":1,\"6\":1,\"9\":2,\"8\":2,\"21\":5,\"11\":4,\"10\":3,\"25\":6,\"24\":6,\"27\":8,\"26\":7,\"23\":5,\"28\":10,\"22\":5}}}', 310, 0, 1668163008);
INSERT INTO `t_template` VALUES (347, 'niuniu1', 81378004, '{\"option\":{\"gps_distance\":-1,\"block_voice\":false,\"owner_kickout_player\":true,\"block_join_when_gaming\":false,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0,\"owner_start\":true,\"min_gamer_count\":0},\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0,\"fixed_commission\":false},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"no_banker_compare\":false,\"base_score\":[1,2],\"ready_timeout_option\":0,\"call_banker_times\":2,\"call_banker\":true,\"banker_take_turn\":false,\"continue_game\":true,\"an_pai_option\":0,\"ox_times\":{\"3\":1,\"2\":1,\"5\":1,\"4\":1,\"7\":1,\"6\":1,\"9\":2,\"8\":2,\"21\":5,\"11\":4,\"10\":3,\"25\":6,\"24\":6,\"27\":8,\"26\":7,\"23\":5,\"28\":10,\"22\":5}}}', 310, 0, 1668163405);
INSERT INTO `t_template` VALUES (348, 'niuniu2', 81378004, '{\"huan\":{},\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"ip_stop_cheat\":false},\"fan\":{\"max_option\":0},\"trustee\":{},\"union\":{\"score_rate\":1,\"tax\":{\"min_ensurance\":0,\"big_win\":[[9999900,0]],\"percentage_commission\":true,\"fixed_commission\":false},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"play\":{\"da_dui_zi_fan_2\":false,\"zi_mo_jia_fan\":true,\"ready_timeout_option\":0,\"dgh_zi_mo\":false,\"dgh_dian_pao\":true,\"guo_zhuang_hu\":false,\"guo_shou_peng\":false,\"cha_xiao_jiao\":false,\"hu_tips\":false,\"tian_di_hu\":false,\"exchange_tips\":false,\"men_qing\":false,\"zi_mo_jia_di\":false,\"yao_jiu\":false,\"cha_da_jiao\":true}}', 200, 0, 1668163525);
INSERT INTO `t_template` VALUES (349, '测试几人跑得快', 69793347, '{\"option\":{\"hand_ready\":true,\"request_dismiss\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"block_hu_dong\":false,\"gps_distance\":-1},\"trustee\":{},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"play\":{\"card_num\":16,\"must_discard\":false,\"ready_timeout_option\":0,\"zhuang\":{\"first_round\":2,\"normal_round\":2},\"plane_with_mix\":true,\"bomb_score\":5,\"si_dai_er\":false,\"first_discard\":{\"with_3\":false},\"AAA_is_bomb\":false,\"bao_dan_discard_max\":false,\"lastone_not_consume\":false,\"san_dai_yi\":false,\"fan_chun\":true,\"si_dai_san\":false}}', 211, 0, 1668702248);
INSERT INTO `t_template` VALUES (350, '33333', 81378004, '{\"pay\":{\"money_type\":1,\"option\":2},\"option\":{\"ip_stop_cheat\":false,\"gps_distance\":-1,\"owner_kickout_player\":true,\"block_voice\":false,\"request_dismiss\":true,\"block_hu_dong\":false,\"block_join_when_gaming\":false},\"round\":{\"option\":0},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0},\"trustee\":{},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":true,\"min_gamer_count\":0},\"play\":{\"trustee_follow\":false,\"bonus_bao_zi\":false,\"bonus_shunjin\":false,\"baozi_less_than_235\":false,\"can_add_score_in_men_turns\":true,\"base_men_score\":1,\"lose_compare_first\":true,\"men_turn_option\":0,\"show_card\":false,\"max_turn_option\":0,\"color_compare\":false,\"small_A23\":false,\"base_score\":1,\"double_compare\":false,\"chip_score\":[2,3,4],\"trustee_drop\":true,\"ready_timeout_option\":0,\"continue_game\":true}}', 300, 0, 1670992347);
INSERT INTO `t_template` VALUES (351, 'zu', 85389915, '{\"round\":{\"option\":0},\"piao\":{\"piao_option\":0},\"play\":{\"bao_jiao\":true,\"guo_shou_peng\":false,\"zi_mo_jia_di\":false,\"jin_gou_gou\":false,\"hu_tips\":false,\"ready_timeout_option\":0,\"guo_zhuang_hu\":false,\"bo_zi_mo\":false,\"zi_mo_jia_fan\":false,\"zi_mo_bu_jia\":true,\"dgh_dian_pao\":true,\"lai_zi\":false,\"dgh_zi_mo\":false},\"fan\":{\"max_option\":0},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"luobo\":{\"luobo_option\":1},\"union\":{\"entry_score\":0,\"score_rate\":1,\"tax\":{\"AA\":0,\"percentage_commission\":true}},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{},\"option\":{\"request_dismiss\":true,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"block_hu_dong\":false,\"ip_stop_cheat\":false}}', 260, 1, 1671286527);
INSERT INTO `t_template` VALUES (352, 'jiji01', 88603133, '{\"huan\":{},\"pay\":{\"option\":2,\"money_type\":1},\"play\":{\"dgh_zi_mo\":false,\"ready_timeout_option\":0,\"zhong_zhang\":true,\"men_qing\":true,\"dgh_dian_pao\":true,\"exchange_tips\":false,\"zi_mo_jia_di\":false,\"guo_zhuang_hu\":false,\"jin_gou_gou\":false,\"cha_da_jiao\":true,\"cha_xiao_jiao\":false,\"tian_di_hu\":false,\"hai_di\":false,\"zi_mo_jia_fan\":true,\"hu_tips\":false},\"option\":{\"request_dismiss\":true,\"gps_distance\":-1,\"ip_stop_cheat\":false,\"hand_ready\":true,\"owner_kickout_player\":true,\"block_hu_dong\":false},\"trustee\":{},\"fan\":{\"max_option\":0},\"room\":{\"player_count_option\":2,\"dismiss_all_agree\":false},\"round\":{\"option\":0},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true}}}', 230, 0, 1671346863);
INSERT INTO `t_template` VALUES (353, '自贡麻将', 88603133, '{\"luobo\":{\"luobo_option\":1},\"play\":{\"dgh_zi_mo\":false,\"zi_mo_bu_jia\":false,\"lai_zi\":false,\"guo_shou_peng\":true,\"dgh_dian_pao\":true,\"jin_gou_gou\":true,\"guo_zhuang_hu\":true,\"ready_timeout_option\":0,\"bao_jiao\":true,\"bo_zi_mo\":false,\"zi_mo_jia_di\":true,\"zi_mo_jia_fan\":false,\"hu_tips\":true},\"round\":{\"option\":0},\"trustee\":{},\"fan\":{\"max_option\":2},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true}},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"request_dismiss\":true,\"gps_distance\":-1,\"ip_stop_cheat\":false,\"hand_ready\":true,\"owner_kickout_player\":true,\"block_hu_dong\":false},\"piao\":{\"piao_option\":0}}', 260, 0, 1671544315);
INSERT INTO `t_template` VALUES (354, 'jjj', 65882523, '{\"trustee\":{},\"pay\":{\"option\":2,\"money_type\":1},\"option\":{\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_voice\":false,\"ip_stop_cheat\":false,\"request_dismiss\":true,\"block_join_when_gaming\":false,\"block_hu_dong\":false},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0,\"min_gamer_count\":0},\"play\":{\"small_A23\":false,\"ready_timeout_option\":0,\"max_turn_option\":0,\"base_score\":1,\"trustee_drop\":true,\"baozi_less_than_235\":false,\"continue_game\":true,\"bonus_bao_zi\":false,\"double_compare\":false,\"base_men_score\":1,\"bonus_shunjin\":false,\"color_compare\":false,\"show_card\":false,\"chip_score\":[2,3,4],\"men_turn_option\":0,\"trustee_follow\":false,\"lose_compare_first\":true,\"can_add_score_in_men_turns\":true},\"round\":{\"option\":0},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true}}}', 300, 1, 1671612301);
INSERT INTO `t_template` VALUES (355, '自贡', 64793141, '{\"trustee\":{},\"fan\":{\"max_option\":0},\"union\":{\"score_rate\":1,\"entry_score\":0,\"tax\":{\"percentage_commission\":true,\"AA\":0}},\"play\":{\"hu_tips\":false,\"guo_zhuang_hu\":false,\"zi_mo_jia_di\":true,\"ready_timeout_option\":0,\"jin_gou_gou\":false,\"zi_mo_jia_fan\":false,\"dgh_dian_pao\":true,\"lai_zi\":false,\"bo_zi_mo\":false,\"dgh_zi_mo\":false,\"bao_jiao\":false,\"guo_shou_peng\":false,\"zi_mo_bu_jia\":false},\"pay\":{\"money_type\":1,\"option\":2},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"luobo\":{\"luobo_option\":0},\"round\":{\"option\":0},\"option\":{\"gps_distance\":-1,\"block_hu_dong\":false,\"request_dismiss\":true,\"hand_ready\":true,\"owner_kickout_player\":true,\"ip_stop_cheat\":false}}', 260, 0, 1671628030);
INSERT INTO `t_template` VALUES (356, '自贡', 85389915, '{\"union\":{\"tax\":{\"percentage_commission\":true,\"AA\":0},\"score_rate\":1,\"entry_score\":0},\"trustee\":{},\"fan\":{\"max_option\":0},\"play\":{\"bo_zi_mo\":false,\"hu_tips\":false,\"jin_gou_gou\":false,\"ready_timeout_option\":0,\"dgh_dian_pao\":true,\"zi_mo_bu_jia\":false,\"guo_shou_peng\":false,\"guo_zhuang_hu\":false,\"dgh_zi_mo\":false,\"bao_jiao\":false,\"lai_zi\":false,\"zi_mo_jia_di\":true,\"zi_mo_jia_fan\":false},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"option\":{\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"hand_ready\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"request_dismiss\":true},\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"luobo\":{\"luobo_option\":0},\"piao\":{\"piao_option\":0}}', 260, 1, 1671764081);
INSERT INTO `t_template` VALUES (357, '自贡麻将', 60320931, '{\"round\":{\"option\":0},\"piao\":{\"piao_option\":0},\"play\":{\"bao_jiao\":true,\"guo_shou_peng\":false,\"zi_mo_jia_di\":true,\"jin_gou_gou\":true,\"hu_tips\":true,\"ready_timeout_option\":0,\"guo_zhuang_hu\":false,\"bo_zi_mo\":false,\"zi_mo_jia_fan\":false,\"zi_mo_bu_jia\":false,\"dgh_dian_pao\":true,\"lai_zi\":true,\"dgh_zi_mo\":false},\"fan\":{\"max_option\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0},\"luobo\":{\"luobo_option\":1},\"union\":{\"entry_score\":1000,\"tax\":{\"big_win\":[[9900,600],[9999900,1000]],\"fixed_commission\":false,\"min_ensurance\":200,\"percentage_commission\":true},\"score_rate\":1},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{},\"option\":{\"request_dismiss\":true,\"hand_ready\":true,\"gps_distance\":-1,\"owner_kickout_player\":true,\"block_hu_dong\":false,\"ip_stop_cheat\":false}}', 260, 0, 1671868281);
INSERT INTO `t_template` VALUES (358, '四川跑得快全', 60320931, '{\"round\":{\"option\":0},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"play\":{\"bomb_type_option\":0,\"zi_mei_dui\":false,\"lastone_not_consume\":false,\"zhuang\":{\"normal_round\":2},\"zha_niao\":false,\"que_yi_se\":false,\"first_discard\":{\"with_5\":false},\"special_score\":10,\"lai_zi\":false,\"ready_timeout_option\":0,\"bomb_score\":[5,10],\"fan_chun\":true},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"option\":{\"request_dismiss\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false}}', 212, 0, 1671869073);
INSERT INTO `t_template` VALUES (359, '跑的快', 85389915, '{\"round\":{\"option\":0},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"play\":{\"bomb_type_option\":0,\"zi_mei_dui\":false,\"lastone_not_consume\":false,\"zhuang\":{\"normal_round\":2},\"zha_niao\":false,\"que_yi_se\":false,\"first_discard\":{\"with_5\":false},\"special_score\":0,\"lai_zi\":false,\"ready_timeout_option\":0,\"bomb_score\":[5,10],\"fan_chun\":true},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"option\":{\"request_dismiss\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false}}', 212, 1, 1671870091);
INSERT INTO `t_template` VALUES (360, 'pdk2', 60320931, '{\"round\":{\"option\":0},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"play\":{\"bomb_type_option\":0,\"zi_mei_dui\":true,\"lastone_not_consume\":false,\"zhuang\":{\"normal_round\":2},\"zha_niao\":true,\"que_yi_se\":false,\"first_discard\":{\"with_5\":false},\"special_score\":10,\"lai_zi\":true,\"ready_timeout_option\":0,\"bomb_score\":[5,10],\"fan_chun\":true},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":2},\"option\":{\"request_dismiss\":true,\"hand_ready\":true,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"gps_distance\":-1,\"block_hu_dong\":false}}', 212, 0, 1671870169);
INSERT INTO `t_template` VALUES (361, '三张', 85389915, '{\"round\":{\"option\":0},\"union\":{\"entry_score\":0,\"tax\":{\"AA\":0,\"percentage_commission\":true},\"score_rate\":1},\"play\":{\"can_add_score_in_men_turns\":true,\"base_score\":1,\"lose_compare_first\":true,\"bonus_shunjin\":false,\"trustee_drop\":true,\"baozi_less_than_235\":false,\"show_card\":false,\"max_turn_option\":0,\"base_men_score\":1,\"color_compare\":false,\"ready_timeout_option\":0,\"men_turn_option\":0,\"bonus_bao_zi\":false,\"small_A23\":false,\"continue_game\":true,\"double_compare\":false,\"trustee_follow\":false,\"chip_score\":[2,3,4]},\"pay\":{\"money_type\":1,\"option\":2},\"trustee\":{},\"room\":{\"dismiss_all_agree\":true,\"min_gamer_count\":0,\"player_count_option\":0},\"option\":{\"ip_stop_cheat\":false,\"request_dismiss\":true,\"block_join_when_gaming\":false,\"gps_distance\":-1,\"block_voice\":false,\"block_hu_dong\":false,\"owner_kickout_player\":true}}', 300, 1, 1671875891);
INSERT INTO `t_template` VALUES (362, '二人长牌', 85389915, '{\"trustee\":{\"second_opt\":0,\"type_opt\":0},\"fan\":{\"chaoFan\":2,\"max_option\":1},\"round\":{\"option\":0},\"play\":{\"ready_timeout_option\":0,\"chi_piao\":true},\"option\":{\"gps_distance\":-1,\"hand_ready\":true,\"block_hu_dong\":false,\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"request_dismiss\":true},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"tax\":{\"fixed_commission\":false,\"percentage_commission\":true,\"AA\":0},\"score_rate\":2,\"entry_score\":0},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":1}}', 350, 0, 1672473526);
INSERT INTO `t_template` VALUES (363, '自贡长牌2人', 60320931, '{\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0,\"score_rate\":1},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":1},\"option\":{\"owner_kickout_player\":true,\"gps_distance\":-1,\"ip_stop_cheat\":false,\"hand_ready\":true,\"request_dismiss\":true,\"block_hu_dong\":false},\"trustee\":{},\"fan\":{\"chaoFan\":2,\"max_option\":1},\"play\":{\"chi_piao\":true,\"ready_timeout_option\":0}}', 350, 0, 1672477433);
INSERT INTO `t_template` VALUES (364, '长牌3人', 66219171, '{\"fan\":{\"chaoFan\":2,\"max_option\":1},\"option\":{\"block_hu_dong\":false,\"ip_stop_cheat\":false,\"gps_distance\":-1,\"owner_kickout_player\":true,\"hand_ready\":true,\"request_dismiss\":true},\"union\":{\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0,\"score_rate\":1},\"pay\":{\"option\":2,\"money_type\":1},\"room\":{\"player_count_option\":0,\"dismiss_all_agree\":false},\"play\":{\"ready_timeout_option\":0,\"chi_piao\":true},\"round\":{\"option\":0},\"trustee\":{}}', 350, 0, 1672479922);
INSERT INTO `t_template` VALUES (365, '长牌2人', 66219171, '{\"fan\":{\"chaoFan\":2,\"max_option\":1},\"option\":{\"block_hu_dong\":false,\"ip_stop_cheat\":false,\"gps_distance\":-1,\"owner_kickout_player\":true,\"hand_ready\":true,\"request_dismiss\":true},\"union\":{\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0,\"score_rate\":1},\"pay\":{\"option\":2,\"money_type\":1},\"room\":{\"player_count_option\":1,\"dismiss_all_agree\":false},\"play\":{\"ready_timeout_option\":0,\"chi_piao\":true},\"round\":{\"option\":0},\"trustee\":{}}', 350, 0, 1672479954);
INSERT INTO `t_template` VALUES (366, '自贡长牌3人', 60320931, '{\"round\":{\"option\":0},\"pay\":{\"money_type\":1,\"option\":2},\"union\":{\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0,\"score_rate\":1},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0},\"option\":{\"owner_kickout_player\":true,\"gps_distance\":-1,\"ip_stop_cheat\":false,\"hand_ready\":true,\"request_dismiss\":true,\"block_hu_dong\":false},\"trustee\":{},\"fan\":{\"chaoFan\":2,\"max_option\":1},\"play\":{\"chi_piao\":true,\"ready_timeout_option\":0}}', 350, 0, 1672629265);
INSERT INTO `t_template` VALUES (367, '自贡长牌', 68705185, '{\"option\":{\"hand_ready\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"ip_stop_cheat\":false,\"owner_kickout_player\":true,\"request_dismiss\":true},\"union\":{\"tax\":{\"AA\":0,\"percentage_commission\":true},\"entry_score\":0,\"score_rate\":1},\"play\":{\"chi_piao\":true,\"ready_timeout_option\":0},\"fan\":{\"chaoFan\":2,\"max_option\":1},\"round\":{\"option\":0},\"trustee\":{},\"pay\":{\"option\":2,\"money_type\":1},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":1}}', 350, 0, 1672842314);
INSERT INTO `t_template` VALUES (368, 'Uj', 85389915, '{\"union\":{\"score_rate\":1,\"tax\":{\"percentage_commission\":true,\"AA\":0},\"entry_score\":0},\"trustee\":{},\"fan\":{\"max_option\":0},\"play\":{\"tian_di_hu\":false,\"ready_timeout_option\":0,\"hu_tips\":false,\"da_dui_zi_fan_2\":false,\"cha_da_jiao\":true,\"exchange_tips\":false,\"hu_at_least_2\":false,\"dgh_dian_pao\":true,\"zi_mo_jia_fan\":true,\"zi_mo_jia_di\":false,\"dgh_zi_mo\":false,\"men_qing\":false,\"cha_xiao_jiao\":false,\"yao_jiu\":false},\"huan\":{},\"option\":{\"owner_kickout_player\":true,\"block_hu_dong\":false,\"request_dismiss\":true,\"hand_ready\":true},\"pay\":{\"money_type\":1,\"option\":2},\"round\":{\"option\":0},\"room\":{\"dismiss_all_agree\":true,\"player_count_option\":0}}', 204, 1, 1673059946);
INSERT INTO `t_template` VALUES (369, '三人长牌', 85389915, '{\"play\":{\"ready_timeout_option\":0,\"chi_piao\":false},\"fan\":{\"max_option\":0,\"chaoFan\":0},\"union\":{\"score_rate\":1,\"tax\":{\"AA\":0,\"fixed_commission\":false,\"percentage_commission\":true},\"entry_score\":0},\"pay\":{\"money_type\":1,\"option\":2},\"option\":{\"owner_kickout_player\":true,\"ip_stop_cheat\":false,\"hand_ready\":true,\"gps_distance\":-1,\"block_hu_dong\":false,\"request_dismiss\":true},\"round\":{\"option\":0},\"trustee\":{\"type_opt\":0,\"second_opt\":0},\"room\":{\"dismiss_all_agree\":false,\"player_count_option\":0}}', 350, 0, 1673339961);

SET FOREIGN_KEY_CHECKS = 1;
