local skynet = require "skynet"
local channel = require "channel"
local cluster = require "skynet.cluster"
require "functions"

local service = {}
function service.unique(id,name,...)
    log.info("unique service:",id)
    local handle = skynet.uniqueservice(name,...)
    local node = channel.query(id)
    if not node then
        channel.subscribe(id,handle)
        cluster.register(id,handle)
    end
    return handle
end

function service.new(id,name,...)
    log.info("new service:",id)
    local handle = skynet.newservice(name,...)
    local node = channel.query(id)
    if not node then
        channel.subscribe(id,handle)
        cluster.register(id,handle)
    end
    return handle
end

return service