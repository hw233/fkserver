local enum = require "pb_enums"
require "game.land.register"

local function boot(conf)
    local room = require "game.land.land_room"
    
    room:init(conf)
    return room
end

return boot