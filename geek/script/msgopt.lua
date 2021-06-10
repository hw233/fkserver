local function on_msg(self,msgid,...)
    local f = rawget(self,msgid)
    if not f then
        error(string.format("unkonw msgid,%s",msgid))
        return
    end

    return f(...)
end

local function reg(self,msgid,handle)
    local t = type(msgid)
    if t == "table" then
        for id,h in pairs(msgid) do
            reg(self,id,h)
        end
        return
    end

    assert(t == "number" or t == "string")
    assert(handle)
    rawset(self,msgid,handle)
end

return setmetatable({},{
    __call = on_msg,
    __newindex = reg,
    __index = {
        reg = reg,
    }
})