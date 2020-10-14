
local enum = require "pb_enums"

require "game.maajan_liangfang.register"

local function boot(conf)
    local room = require "game.maajan_liangfang.maajan_room"
    
    room:init(conf, 4, enum.GAME_READY_MODE_ALL)
    return room
end

return boot