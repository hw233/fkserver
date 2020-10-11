local redisopt = require "redisopt"

local reddb = redisopt.default

local player_mail = {}

setmetatable(player_mail,{
    __index = function(t,guid)
        local mail_ids = reddb:smembers(string.format("player:mail:%d",guid))
        t[guid] = mail_ids
        return mail_ids
    end
})

return player_mail