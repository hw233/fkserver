
local pb = require "pb_files"

local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

local function boot(conf)
    pb.loadfile("gamingcity/pb/common_msg_multi_showhand.proto")
    local room = require "game.multi_showhand.multi_showhand_room"
    
    room:init(conf, 5, GAME_READY_MODE_PART)
    return room
end


return boot