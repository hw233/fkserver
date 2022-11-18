
require "game.maajan_hongzhong.register"

local function boot(conf)
    local room = require "game.maajan_hongzhong.room"

    room:init(conf)
    return room
end

return boot