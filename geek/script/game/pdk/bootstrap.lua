local enum = require "pb_enums"
require "game.pdk.register"

local function boot(conf)
    local room = require "game.pdk.pdk_room"
    
    room:init(conf, 2, enum.GAME_READY_MODE_ALL)
    return room
end

return boot