
require "game.maajan_mianyang.register"

local function boot(conf)
    local room = require "game.maajan_mianyang.maajan_room"

    room:init(conf)
    return room
end

return boot