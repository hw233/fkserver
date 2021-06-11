
require "game.ox.register"

local function boot(conf)
    local room = require "game.ox.room"
    
    room:init(conf)
    
    return room
end

return boot