local skynet = require "skynet"
local cluster = require "han"
local channel = require "channel"

local handshake = {}

function handshake.send(nodename)
    cluster.send(nodename,"handshake","lua","handshake",channel.localservice())
end

skynet.start(function()
    local handle = skynet.uniqueservice("service/handshaked")
    cluster.register("handshake",handle)
end)

return handshake