local enum = require "pb_enums"

local function boot(conf)
    local room = require "game.maajan.maajan_room"
    
    room:init(conf, 4, enum.GAME_READY_MODE_ALL)
    return room
end

return boot