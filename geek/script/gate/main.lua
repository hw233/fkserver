local skynet = require "skynetproto"
local channel = require "channel"
local msgopt = require "msgopt"
require "functions"
local log = require "log"

local sconf 
local gateid
local gateconf
protocol = nil

local CMD = {}

local function checkgateconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkgateconf(conf)
    sconf = conf
    gateid = conf.id

    if not sconf or sconf.is_launch == 0 or not sconf.conf then
        log.error("launch a unconfig or unlaunch gate service,service:%d.",gateid)
        return
    end

    gateconf = sconf.conf
    protocol = gateconf.protocol

    local host,port = gateconf.host,gateconf.port
    if not port then
        host,port = host:match("([^:]+):(%d+)")
        port = tonumber(port)
    end

    local loginservice = skynet.newservice("gate.logind",gateid,protocol)
    local gate = skynet.newservice("gate.gated",loginservice,gateid,protocol)
    skynet.call(gate,"lua","open",{
        host = host,
        port = port,
    })
end

function CMD.forward(who,proto,...)
    channel.publish(who,proto,...)
end

local CONTROL = {}

function CONTROL.forward(who,...)
    channel.publish(who,...)
end

skynet.start(function()
    local handle = skynet.localname ".gate"
    if handle then
        log.error("same cluster launch too many gate service,exit service:%d",gateid)
        skynet.exit()
        return handle
    end

    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
			log.error("unknow cmd:%s",cmd)
			skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        unpack = skynet.unpack,
        pack = skynet.pack,
    }

    skynet.dispatch("client",function(_,_,guid,...)
        channel.publish("guid."..tostring(guid),...)
    end)
end)