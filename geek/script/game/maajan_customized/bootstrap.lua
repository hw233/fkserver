
local pb = require "pb_files"
local enum = require "pb_enums"

require "game.maajan_customized.register"

local function boot(conf)
    pb.loadfile("gamingcity/pb/common_msg_maajan.proto")
    local room = require "game.maajan_customized.maajan_room"
    
    room:init(conf, 4, enum.GAME_READY_MODE_ALL)
    return room
end

return boot