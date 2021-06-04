local enum = require "pb_enums"
require "game.pdk_sc.register"

local function boot(conf)
    local room = require "game.pdk_sc.room"
    
    room:init(conf, 3, enum.GAME_READY_MODE_ALL)
    return room
end

return boot