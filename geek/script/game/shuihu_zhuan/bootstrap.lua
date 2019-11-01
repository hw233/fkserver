
local pb = require "pb_files"

local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

local function boot(conf)
    require "game.shuihu_zhuan.register"
    local game_rooms = require("game/shuihu_zhuan/game_rooms")
    local manager = require("game/shuihu_zhuan/game_manager")
    manager.init(1, 300, 1)
    local mgr = game_rooms:new()
    room:init(conf, 1, GAME_READY_MODE_NONE)
    return room
end


return boot