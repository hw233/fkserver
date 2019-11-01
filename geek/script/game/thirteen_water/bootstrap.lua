
local pb = require "pb_files"

local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

local function boot(conf)
    require "game.thirteen_water.register"
    pb.loadfile("gamingcity/pb/common_msg_thirteen_water.proto")
    local room = require "game.thirteen_water.thirteen_room"
    
    room:init(conf, 4, GAME_READY_MODE_PART)
    return room
end


return boot