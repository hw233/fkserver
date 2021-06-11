
require "game.zhajinhua.register"

local function boot(conf)
    local room = require "game.zhajinhua.zhajinhua_room"
    
    room:init(conf)
    return room
end

return boot