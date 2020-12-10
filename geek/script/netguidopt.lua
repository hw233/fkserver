local log = require "log"
local redisopt = require "redisopt"
local channel = require "channel"
local allonlineguid = require "allonlineguid"

local reddb = redisopt.default

local table = table
local string = string
local tinsert = table.insert

local onlineguid = setmetatable({},{
    __index = function(t,guid)
        local session = reddb:hgetall("player:online:guid:"..tostring(guid))
        if not session then
            return nil
        end

        -- t[k] = session
        return session
    end
})

function onlineguid.send(guid,msgname,msg)
    msg = msg or {}
    guid = type(guid) == "table" and guid.guid or guid
    local s = onlineguid[guid]
    if not s or not s.gate then 
        log.warning("send2guid %d not online.",guid)
        return
    end

    channel.publish("gate."..s.gate,"client",guid,"forward",msgname,msg)
end

function onlineguid.control(player_or_guid,msgname,msg)
    local guid = type(player_or_guid) == "table" and player_or_guid.guid or player_or_guid

    if not allonlineguid[guid] then
        log.warning("send2guid %d not online.",guid)
        return
    end

    local s = onlineguid[guid]
    if not s or not s.gate then 
        log.warning("control2guid %d not online.",guid)
        return
    end

    log.info("onlineguid.control %s %s %s",guid,msgname,msg)

    channel.call("gate."..s.gate,"client",guid,"lua",msgname,msg)
end

function onlineguid.broadcast(guids,msgname,msg)
    local gateguids = {}
    for _,guid in pairs(guids) do
        local s = allonlineguid[guid] and onlineguid[guid]
        if s and s.gate then
            gateguids[s.gate] = gateguids[s.gate] or {}
            tinsert(gateguids[s.gate],guid)
        end
    end

    for gate,gguids in pairs(gateguids) do
        channel.publish("gate."..gate,"client",gguids,"broadcast",msgname,msg)
    end
end

return onlineguid