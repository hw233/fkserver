local skynet = require "skynet"

local senderd

local channel = {}

function channel.call(id,...)
    log.info("channel.call",id,...)
    local ret = skynet.call(senderd,"lua","call",id,"lua",...) 
    dump(ret)
    return ret
end

function channel.publish(id,...)
    return skynet.send(senderd,"lua","send",id,"lua",...)
end

function channel.subscribe(id,addr,iscluster)
    return skynet.call(senderd,"lua","register",id,addr,iscluster)
end

function channel.localservice()
    local address = channel.query()
    local localaddress = {}
    for id,conf in pairs(address) do
        if not conf.iscluster then
            localaddress[id] = conf
        end
    end

    return localaddress
end

function channel.query(id)
    return skynet.call(senderd,"lua","query",id)
end

skynet.init(function() 
    senderd = skynet.uniqueservice("service/senderd")
end)

return channel