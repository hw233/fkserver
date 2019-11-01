local skynet = require "skynet"

local processor = {}

function processor:call(...)
    return skynet.call(self.s,self.p,self.m,...)
end

function processor:send(...)
    return skynet.send(self.s,self.p,self.m,...)
end

local method = {}

setmetatable(method,{__index = function(t,k) 
    local f = setmetatable({s = t.s,p = t.p,m = k},{__index = proccessor,})

    t[k] = f
    return f
end,})

local protocol = {}

setmetatable(protocol,{__index = function(t,k)
    local p = setmetatable({p = k,s = t.s,},{__index = method})
    t[k] = p
    return p
end,})

local lpc = {}

setmetatable(lpc,{__index = function(t,k)
    local service = setmetatable({s = k,},{__index = protocol,})
    t[k] = service
    return service
end,})

return lpc