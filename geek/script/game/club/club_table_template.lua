local redisopt = require "redisopt"
local table_template = require "game.club.table_template"

local reddb = redisopt.default


local club_table_template = {}


setmetatable(club_table_template,{
    __index = function(t,club_id)
        local ids = reddb:smembers("club:"..tostring(club_id).."table:template")
        local templates = {}
        for _,id in pairs(ids) do
            id = tonumber(id)
            templates[id] = table_template[id]
        end

        t[club_id] = templates
        
        return templates
    end
})


return club_table_template