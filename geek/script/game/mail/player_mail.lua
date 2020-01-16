local redisopt = require "redisopt"

local reddb = redisopt.default

local player_mail = {}

setmetatable(player_mail,{
    __index = function(t,guid)
        local mids = reddb:smembers(string.format("player:mail:%d",guid))
        local mail_ids = {}
        for _,mail_id in pairs(mids) do
            mail_ids[mail_id] = true
        end
        t[guid] = mail_ids
        return mids
    end
})

return player_mail