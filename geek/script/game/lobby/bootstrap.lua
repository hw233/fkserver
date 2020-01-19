
local enum = require "pb_enums"

local function boot(gameconf,conf)
    local room = require "game.lobby.base_room"
    
    room:init(gameconf, 2, enum.GAME_READY_MODE_NONE, conf)
    return room
end


return boot