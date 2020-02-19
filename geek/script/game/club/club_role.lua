
local redisopt = require "redisopt"
local reddb = redisopt.default

local function get_role(t,guid)
    local role = reddb:hget("club:role:"..tostring(t.club),guid)
    if not role or role == "" then
        return nil
    end
    role = tonumber(role)
    t[guid] = role
    return role
end

local club_role = {}

setmetatable(club_role,{
    __index = function(t,club_id)
        local roles = setmetatable({club = club_id},{__index = get_role})
        -- t[club_id] = roles
        return roles
    end
})

return club_role