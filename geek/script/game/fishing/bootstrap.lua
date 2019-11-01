
local pb = require "pb_files"

local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

require "functions"

local function boot(conf)
    require "game.fishing.register"
    pb.loadfile("gamingcity/pb/common_msg_fishing.proto")
    local room = require "game.fishing.fishing_room"
    room:init(conf, 4, GAME_READY_MODE_ALL)
    return room
end


return boot