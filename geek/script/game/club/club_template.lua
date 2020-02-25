local redisopt = require "redisopt"

local reddb = redisopt.default

local club_template = {}

setmetatable(club_template,{
    __index = function(t,club_id)
        local tts = {}
        local ttids = reddb:smembers(string.format("club:template:%d",club_id))
        for _,ttid in pairs(ttids) do
            tts[tonumber(ttid)] = true
        end

        -- t[club_id] = tts

        return tts
    end
})


return club_template