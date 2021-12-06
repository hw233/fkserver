local skynet = require "skynetproto"
local log = require "log"

local channeld = ".channeld"

local max_ttl = 5

local channel = {}

function channel.call(id,proto,cmd,...)
    if id:match("%*") then
        log.error("channel.call id include '*' to call multi target,id:%s",id)
        return nil
    end
    local now = skynet.time()
    local rets = {skynet.call(channeld,"lua","call",id,proto,cmd,...)}
    local deltatime = skynet.time() - now
    if deltatime > max_ttl then
        log.warning("channel.call %s,%s,%s time > max_ttl %s",id,proto,cmd,deltatime)
    end
    return table.unpack(rets)
end

function channel.pcall(id,proto,cmd,...)
    if id:match("%*") then
        log.error("channel.pcall id include '*' to call multi target,id:%s",id)
        return nil
    end
    local now = skynet.time()
    local rets = {pcall(skynet.call,channeld,"lua","call",id,proto,cmd,...)}
    local deltatime = skynet.time() - now
    if deltatime > max_ttl then
        log.warning("channel.pcall %s,%s,%s time > max_ttl %s",id,proto,cmd,deltatime)
    end
    return table.unpack(rets)
end

function channel.publish(id,proto,...)
    return skynet.send(channeld,"lua","publish",id,proto,...)
end

function channel.subscribe(service,handle,remote)
    return skynet.call(channeld,"lua","subscribe",service,handle,remote)
end

function channel.unsubscribe(service,remote)
    return skynet.call(channeld,"lua","unsubscribe",service,remote)
end

function channel.localprovider(name)
    return skynet.call(channeld,"lua","localprovider",name)
end

function channel.list()
    return skynet.call(channeld,"lua","query")
end

function channel.query(id)
    return skynet.call(channeld,"lua","query",id)
end

function channel.kill(id)
    return skynet.call(channeld,"lua","kill",id)
end

function channel.warmdead(id)
    return skynet.call(channeld,"lua","warmdead",id)
end

function channel.term()
    return skynet.call(channeld,"lua","term")
end

function channel.load_service(clusters)
    return skynet.call(channeld,"lua","load_service",clusters)
end

skynet.init(function()
    channeld = skynet.uniqueservice("service.channeld")
end)

return channel