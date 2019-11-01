-- 注册消息

local pb = require "pb_files"
local protoc = require "protoc"

protoc.loadfile("../pb/common_msg_shuihu_zhuan.proto")

-- 消息函数

local game_manager = require("game/shuihu_zhuan/game_manager")

function on_cs_rotate_pattern(player, msg)
    game_manager.on_cs_rotate_pattern(player, msg)
end

function on_cs_compare_dice(player, msg)
    game_manager.on_cs_compare_dice(player, msg)
end

function on_cs_rotate_bonus(player, msg)
    game_manager.on_cs_rotate_bonus(player, msg)
end

function on_cs_collect_score(player, msg)
    game_manager.on_cs_collect_score(player, msg)
end

-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_RotatePattern",on_cs_rotate_pattern)
register_dispatcher("CS_CompareDice",on_cs_compare_dice)
register_dispatcher("CS_RotateBonus",on_cs_rotate_bonus)
register_dispatcher("CS_CollectScore",on_cs_collect_score)
