local skynet = require "skynetproto"
local httpd = require "gm.httpd"
require "table_func"
local log = require "log"
local msgopt = require "msgopt"

local sconf
local agentcount
local agents = {}
local balance = 1

local CMD = {}

local function checkgmconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
    assert(conf.conf)
    local gmconf = conf.conf
    assert(gmconf.agentcount)
    assert(gmconf.host)
end

local function dispatch(fd,addr)
    log.info("%s connected, pass it to agent :%08x", addr, agents[balance])
    skynet.send(agents[balance],"lua",fd,addr)
    balance = balance + 1
    if balance > #agents then
        balance = 1
    end
end

function CMD.start(conf)
    checkgmconf(conf)
    sconf = conf
    agentcount = conf.conf.agentcount or 1

    for i = 1,agentcount do
        agents[i] = skynet.newservice("gm.agentd","http")
    end

    httpd.open(sconf.conf,dispatch)
end

function CMD.close()
    httpd.close()
end

skynet.start(function()
    skynet.dispatch("lua", function (_, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            log.error("invalid cmd,%s",cmd)
        end
    end)

    skynet.dispatch("msg",function(_,_,cmd,...)
        skynet.retpack(msgopt.on_msg(cmd,...))
	end)
end)