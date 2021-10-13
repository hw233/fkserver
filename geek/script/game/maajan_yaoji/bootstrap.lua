
require "game.maajan_yaoji.register"

local function boot(conf)
    local room = require "game.maajan_yaoji.room"

    room:init(conf)
    return room
end

return boot