
require "game.maajan_menhu.register"

local function boot(conf)
    local room = require "game.maajan_menhu.maajan_room"
    
    room:init(conf)
    return room
end

return boot