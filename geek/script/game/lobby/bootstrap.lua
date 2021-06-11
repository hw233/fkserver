
local enum = require "pb_enums"

local function boot(gameconf)
    local room = require "game.lobby.base_room"
    
    room:init(gameconf)
    return room
end


return boot