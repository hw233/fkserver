local redisopt = require "redisopt"
local base_notice = require "game.notice.base_notice"

local reddb = redisopt.default

local function load_notice(id)
        local c = reddb:hgetall(string.format("notice:%s",id))
        if not c or table.nums(c) == 0 then
                return nil
        end

        setmetatable(c,{__index = base_notice})
        return c
end

local base_notices = setmetatable({},{
        __index = function(t,id)
                if id == "*" then
                        for _,nid in pairs(reddb:keys("notice:*") or {}) do
                                t[id] = load_notice(nid)
                        end
                        return t
                end

                local c = load_notice(id)
                t[id] = load_notice(id)
                return c
        end
})

return base_notices