local skynet = require "skynet"
local channel = require "channel"
local cluster = require "cluster"
require "functions"
local log = require "log"

local nameservice = {
    TNCONFIG = "config",
    TNGAME = "game",
    TNDB = "db",
    TNGM = "gm",
    TNGATE = "gate",
    TNLOGIN = "login",
    TNSTATISTICS = "statistics",
    TIDDB = 1,
    TIDCONFIG = 2,
    TIDLOGIN = 3,
    TIDGM = 4,
    TIDGATE = 5,
    TIDGAME = 6,
    TIDSTATISTICS = 7,
}

function nameservice.unique(id,name,...)
    local handle = skynet.uniqueservice(name,...)
    log.info("unique service,id:%s,handle:%s",tostring(id),tostring(handle))
    channel.subscribe(id,handle)
    cluster.register(id,handle)
    return handle
end

function nameservice.new(id,name,...)
    local handle = skynet.newservice(name,...)
    log.info("new service,id:%s,handle:%s",tostring(id),tostring(handle))
    channel.subscribe(id,handle)
    cluster.register(id,handle)
    return handle
end

return nameservice