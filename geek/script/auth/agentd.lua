
local skynet = require "skynet"
local agent = require "auth.agent"
local authd = require "auth.authd"

local protocol = ...
protocol = protocol or "http"

skynet.start(function()
    agent.start(protocol,function(request,response)
        
    end)
end)