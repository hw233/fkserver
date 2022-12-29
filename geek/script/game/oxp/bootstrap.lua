
require "game.oxp.register"

local function boot(conf)
    local room = require "game.oxp.room"
    
    room:init(conf)
    
    return room
end

return boot