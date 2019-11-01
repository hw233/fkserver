local skynet = require "skynet"
local service = require "nameservice"

local protocol = ...
protocol = protocol or "ws"

skynet.start(function() 
    local loginservice = skynet.newservice("gate.logind")
    local gate = service.new("gate.1","gate.gated",loginservice,protocol)
end)