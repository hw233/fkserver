
require "game.maajan_xuezhan.register"

local function boot(conf)
    local room = require "game.maajan_xuezhan.maajan_room"

    room:init(conf)
    return room
end

return boot