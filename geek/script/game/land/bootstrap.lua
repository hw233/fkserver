
local pb = require "pb_files"

local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

local function boot(conf)
    require "game.land.register"
    pb.loadfile("gamingcity/pb/common_msg_land.proto")
    local room = require "game.land.land_room"
    
    room:init(conf, 3, GAME_READY_MODE_ALL)
    return room
end


return boot