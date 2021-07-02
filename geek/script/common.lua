
local redisopt = require "redisopt"
local reddb  = redisopt.default

local common = {}

function common.is_in_maintain()
    local v = reddb:get("runtime_conf:global:maintain_switch")
    return (v and v == "true") and true or nil
end

function common.find_lightest_weight_game_server(first_game_type,second_game_type)
    local key = second_game_type and 
        string.format("player:online:count:%d:%d",first_game_type,second_game_type) or 
        string.format("player:online:count:%d",first_game_type)

    local scores = reddb:zrangebyscore(key,"-inf","+inf","LIMIT","0","1")
    if #scores > 0 then
        return tonumber(scores[1])
    end
end


local log = require "log"
function common.all_game_server(first_game_type,second_game_type)
    local key = second_game_type and 
        string.format("player:online:count:%d:%d",first_game_type,second_game_type) or 
        string.format("player:online:count:%d",first_game_type)

    local list = reddb:zrangebyscore(key,"-inf","+inf","withscores")
    local room_weights = {}
	for i = 1,#list,2 do
		local roomid = tonumber(list[i])
		local score = tonumber(list[i + 1])
		room_weights[roomid] = score
	end

	return room_weights
end

return common