
local enum = require "pb_enums"

require "game.maajan_liangfang.register"

local function boot(conf)
    local room = require "game.maajan_liangfang.maajan_room"
    
    room:init(conf)
    return room
end

return boot