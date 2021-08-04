
local redopt = require "redisopt"

local reddb = redopt.default

local log = require "log"

local private_fee_switch = setmetatable({},{
    __index = function(_,money_id)
        local v = reddb:get(string.format("runtime_conf:private_fee:%s",money_id))
        log.dump(v)
        return (not v or tonumber(v) ~= 0) and true or false
    end,
})

local private_fee_club_switch = setmetatable({},{
    __index = function(_,club_id)
        local v = reddb:hget("runtime_conf:private_fee:club",club_id)
        return (not v or tonumber(v) < os.time()) and true or false
    end,
})

local private_fee_agency_switch = setmetatable({},{
    __index = function(_,guid)
        local v = reddb:hget("runtime_conf:private_fee:agency",guid)
        return (not v or tonumber(v) < os.time()) and true or false
    end,
})

local global = setmetatable({},{
    __index = function(_,key)
        local v = reddb:get(string.format("runtime_conf:global:%s",key))
        return (not v or tonumber(v) ~= 0) and true or false
    end,
})

local channel_games = setmetatable({},{
    __index = function(_,channel)
        local v = reddb:smembers(string.format("runtime_conf:channel_game:%s",channel))
        return v and table.keys(v) or nil
    end,
})

local promoter_games = setmetatable({},{
    __index = function(_,promoter)
        local v = reddb:smembers(string.format("runtime_conf:promoter_game:%s",promoter))
        return v and table.keys(v) or nil
    end,
})

local club_games = setmetatable({},{
    __index = function(_,club_id)
        local v = reddb:smembers(string.format("runtime_conf:club_game:%s",club_id))
        return v and table.keys(v) or nil
    end,
})

local function get_game_conf(channel,promoter,club_id)
    local club_key = (club_id and club_id ~= 0) and string.format("runtime_conf:club_game:%s",club_id) or nil
    if club_key then
        local ids = table.keys(reddb:smembers(club_key))
        if #ids > 0 then
            return ids
        end
    end

    local promoter_key = (promoter and promoter ~= 0) and string.format("runtime_conf:promoter_game:%s",promoter) or nil
    if promoter_key then
        local ids = table.keys(reddb:smembers(promoter_key))
        if #ids > 0 then
            return ids
        end
    end

    local channel_key = string.format("runtime_conf:channel_game:%s",(channel and channel ~= "") and channel or "default")
    local ids = table.keys(reddb:smembers(channel_key))
    if #ids > 0 then
        return ids
    end
end

local function is_in_maintain(gametype)
    local key = gametype and string.format("runtime_conf:game_maintain_switch:%s",gametype) or "runtime_conf:global:maintain_switch"
    local v = reddb:get(key)
    return (v and v == "true") and true or nil
end

return {
    private_fee_switch = private_fee_switch,
    private_fee_club_switch = private_fee_club_switch,
    private_fee_agency_switch = private_fee_agency_switch,
    global = global,
    channel_game = channel_games,
    prmoter_game = promoter_games,
    club_game = club_games,
    get_game_conf = get_game_conf,
    is_in_maintain = is_in_maintain,
}
