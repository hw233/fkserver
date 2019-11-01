local msgopt = require "msgopt"
local socketdriver = require "skynet.socketdriver"
local log = require "log"

local onlineguid = {}

function onlineguid.login(guid,session)
    onlineguid[guid] = session
end

function onlineguid.logout(guid)
    onlineguid[guid] = nil
end

function onlineguid.send(guids,msgname,msg)
    local function guidsend(guid,msgname,msg)
        local guid = guids
        if not onlineguid[guid] then 
            log.warning("......")
            return 
        end

        local agent = onlineguid[guid].addr
        if not agent then
            log.warning("......")
            return 
        end

        skynet.send(agent,"lua","push",msgname,msg)
    end

    if type(guids) == "number" then
        guidsend(guids,msgname,msg)
        return
    end

    for _,guid in pairs(guids) do
        guidsend(guid,msgname,msg)
    end
end

sendpb2guid = onlineguid.sendpb

return onlineguid