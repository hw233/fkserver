local redisopt = require "redisopt"

local reddb = redisopt.default

local club_table_template = {}

setmetatable(club_table_template,{
    __index = function(t,club_id)
        local tts = {}
        local ttids = reddb:smembers(string.format("club:table_template:%d",club_id))
        for _,ttid in pairs(ttids) do
            tts[tonumber(ttid)] = true
        end

        t[club_id] = tts

        return ttids
    end
})


return club_table_template