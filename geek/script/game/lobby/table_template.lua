
local redisopt = require "redisopt"

local reddb = redisopt.default

local table_template = {}

local function metafn(t,ttid)
    local temp = reddb:hgetall("template:"..tostring(ttid))
    if not temp or table.nums(temp) == 0 then
        return nil
    end
    t[ttid] = temp
    return temp
end

setmetatable(table_template,{
    __index = metafn
})


local timer_task = require "timer_task"

local function guard()
    table_template = setmetatable({},{
        __index = metafn,
    })
end 

timer_task.exec(2,guard)

local m = {}

setmetatable(m,{
    __index = function(t,club_id)
        return table_template[club_id]
    end,
    _newindex = function(t,club_id,value)
        if value == nil then 
            table_template[club_id] = nil 
        end 
    end,
})
return m 