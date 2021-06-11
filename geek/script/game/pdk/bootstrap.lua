require "game.pdk.register"

local function boot(conf)
    local room = require "game.pdk.pdk_room"
    
    room:init(conf)
    return room
end

return boot