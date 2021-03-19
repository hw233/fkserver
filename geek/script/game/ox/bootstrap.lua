
local enum = require "pb_enums"

require "game.ox.register"

local function boot(conf)
    local room = require "game.ox.room"
    
    room:init(conf, 6, enum.GAME_READY_MODE_PART)
    
    return room
end

return boot