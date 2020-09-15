
local redopt = require "redisopt"

local reddb = redopt.default

local log = require "log"

local private_fee_switch = setmetatable({},{
    __index = function(_,money_id)
        local v = reddb:get(string.format("runtime_conf:private_fee:%s",money_id))
        return (not v or tonumber(v) ~= 0) and true or false
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
        return v and table.series(v,function(gid) tonumber(gid) end) or nil
    end,
})

local promoter_games = setmetatable({},{
    __index = function(_,promoter)
        local v = reddb:smembers(string.format("runtime_conf:promoter_game:%s",promoter))
        return v and table.series(v,function(gid) tonumber(gid) end) or nil
    end,
})

local club_games = setmetatable({},{
    __index = function(_,club_id)
        local v = reddb:smembers(string.format("runtime_conf:club_game:%s",club_id))
        return v and table.series(v,function(gid) tonumber(gid) end) or nil
    end,
})

local function get_game_conf(channel,promoter,club_id)
    local channel_key = channel and string.format("runtime_conf:channel_game:%s",channel) or nil
    local promoter_key = promoter and string.format("runtime_conf:promoter_game:%s",promoter) or nil
    local club_key = club_id and string.format("runtime_conf:club_game:%s",club_id) or nil
    local keys = table.values({channel_key,promoter_key,club_key})
    local game_ids = reddb:sinter(table.unpack(keys))
    return table.series(game_ids,function(gid) return tonumber(gid) end)
end

return {
    private_fee_switch = private_fee_switch,
    global = global,
    channel_game = channel_games,
    prmoter_game = promoter_games,
    get_game_conf = get_game_conf,
}
