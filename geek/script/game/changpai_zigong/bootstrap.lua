
require "game.changpai_zigong.register"

local function boot(conf)
    local room = require "game.changpai_zigong.changpai_room"

    room:init(conf)
    return room
end

return boot