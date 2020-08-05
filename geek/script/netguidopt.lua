local log = require "log"
local redisopt = require "redisopt"
local channel = require "channel"

local reddb = redisopt.default


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

function onlineguid.send(guids,msgname,msg)
    msg = msg or {}
    local function guidsend(player_or_guid,msgname,msg)
        local guid = type(player_or_guid) == "table" and player_or_guid.guid or player_or_guid
        local s = onlineguid[guid]
        if not s or not s.gate then 
            log.warning("send2guid %d not online.",guid)
            return
        end
  
        channel.publish("gate."..s.gate,"client",guid,"forward",msgname,msg)
    end

    if type(guids) == "number" then
        guidsend(guids,msgname,msg)
        return
    end

    for _,guid in pairs(guids) do
        guidsend(guid,msgname,msg)
    end
end

function onlineguid.control(player_or_guid,msgname,msg)
    local guid = type(player_or_guid) == "table" and player_or_guid.guid or player_or_guid
    local s = onlineguid[guid]
    if not s or not s.gate then 
        log.warning("control2guid %d not online.",guid)
        return
    end

    log.info("onlineguid.control %s %s %s",guid,msgname,msg)

    channel.publish("gate."..s.gate,"client",guid,"lua",msgname,msg)
end

function onlineguid.broadcast(guids,msgname,msg)
    local gateguids = {}
    for _,guid in pairs(guids) do
        local s = onlineguid[guid]
        if s and s.gate then
            gateguids[s.gate] = gateguids[s.gate] or {}
            table.insert(gateguids[s.gate],guid)
        end
    end

    for gate,gguids in pairs(gateguids) do
        channel.publish("gate."..gate,"client",gguids,"broadcast",msgname,msg)
    end
end

return onlineguid