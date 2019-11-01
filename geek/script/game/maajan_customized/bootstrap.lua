
local pb = require "pb_files"

local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")

require "game.maajan_customized.register"

local function boot(conf)
    pb.loadfile("gamingcity/pb/common_msg_maajan.proto")
    local room = require "game.maajan_customized.maajan_room"
    
    room:init(conf, 4, GAME_READY_MODE_ALL)
    return room
end

return boot