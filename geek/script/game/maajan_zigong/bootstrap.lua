
require "game.maajan_zigong.register"

local function boot(conf)
    local room = require "game.maajan_zigong.room"

    room:init(conf)
    return room
end

return boot