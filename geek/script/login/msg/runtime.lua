
local channel = require "channel"
local nameservice = require "nameservice"
local serviceconf = require "serviceconf"

function find_a_default_lobby()
    local services = channel.list()
    for sid,_ in pairs(services) do
        local id = sid:match("service%.(%d+)")
        if id then
            id = tonumber(id)
            local conf = serviceconf[id]
            if conf and (conf.name == nameservice.TNGAME or conf.type == nameservice.TIDGAME) then
                local gameconf = conf.conf
                if gameconf and gameconf.first_game_type and gameconf.first_game_type == 1 then
                    return tonumber(sid:match("service%.(%d+)"))
                end
            end
        end
    end
end