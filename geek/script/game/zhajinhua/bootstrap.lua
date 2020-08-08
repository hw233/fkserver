
local enum = require "pb_enums"

require "game.zhajinhua.register"

local function boot(conf)
    local room = require "game.zhajinhua.zhajinhua_room"
    
    room:init(conf, 8, enum.GAME_READY_MODE_PART)
    return room
end

return boot