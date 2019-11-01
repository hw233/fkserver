local skynet = require "skynet"
local httpd = require "gm.httpd"
require "table_func"
local service = require "nameservice"

local agent_count = ...
agent_count = agent_count and tonumber(agent_count) or 1

skynet.start(function() 
    local agents = {}
    for i = 1,agent_count do
        agents[i] = service.new("gm.agentd."..tostring(i),"gm.agentd","http")
    end

    local balance = 1

    httpd.start(function(fd,addr) 
        skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agents[balance]))
        skynet.send(agents[balance],"lua",fd,addr)
        balance = balance + 1
        if balance > #agents then
            balance = 1
        end
    end)
end)