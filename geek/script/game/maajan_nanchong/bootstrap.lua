
require "game.maajan_nanchong.register"

local function boot(conf)
    local room = require "game.maajan_nanchong.maajan_room"

    room:init(conf)
    return room
end

return boot