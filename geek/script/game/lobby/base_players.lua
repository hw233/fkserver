local redisopt = require "redisopt"

local base_player = require "game.lobby.base_player"

local timermgr = require "timermgr"

local log = require "log"

local reddb = redisopt.default

local unused_player_info_elapsed = 30

local player_manager = {}

setmetatable(player_manager,{
	__index = function(t,guid)
        if type(guid) ~= "number" then
            return
        end
		
		local p = reddb:hgetall(string.format("player:info:%d",math.floor(guid)))
		if not p then
			return nil
		end

		p = table.nums(p) > 0 and p or nil
		if p then
			setmetatable(p,{__index = base_player})
		end

		t[guid] = p
		return p
	end,
})

function player_manager.foreach(func)
	for _, player in pairs(player_manager) do
		func(player)
	end
end

-- 广播所有人消息
function player_manager.broadcast2client_pb(msg_name, pb)
	for guid, player in pairs(player_manager) do
		if player.online then
			send2client_pb(player, msg_name, pb)
		end
	end
end

timermgr:loop(unused_player_info_elapsed,function()
	for guid,info in pairs(player_manager) do
		if type(guid) == "number" then
			info:lockcall(function() 
				if 	not info.online and 
					not info.table_id and 
					not info.chair_id 
				then
					log.info("clean unused player info %s",guid)
					player_manager[guid] = nil
				end
			end)
		end
	end
end)

return player_manager