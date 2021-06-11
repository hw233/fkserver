require "game.pdk_sc.register"

local function boot(conf)
    local room = require "game.pdk_sc.room"
    
    room:init(conf)
    return room
end

return boot