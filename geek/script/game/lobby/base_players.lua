local redisopt = require "redisopt"

local base_player = require "game.lobby.base_player"

local timermgr = require "timermgr"

local log = require "log"

local reddb = redisopt.default

local unused_player_info_elapsed = 30

local queue = require "skynet.queue"

local infolock = setmetatable({},{
	__index = function(t,guid)
		local lock = queue()
		t[guid] = lock
		return lock
	end,
})

local player_manager = {}

setmetatable(player_manager,{
	__index = function(t,guid)
        if type(guid) ~= "number" then
            return
        end
		return infolock[guid](function()
			-- double check
			local p = rawget(t,guid)
			if p then
				return p
			end

			p = reddb:hgetall(string.format("player:info:%d",math.floor(guid)))
			if not p then
				return nil
			end

			p = table.nums(p) > 0 and p or nil
			if p then
				setmetatable(p,{__index = base_player})
			end

			t[guid] = p
			return p
		end)
	end,
})

timermgr:loop(unused_player_info_elapsed,function()
	for guid,p in pairs(player_manager) do
		p:lockcall(function()
			if 	not p.online and 
				not p.table_id and 
				not p.chair_id 
			then
				log.info("clean unused player info %s",guid)
				player_manager[guid] = nil
				infolock[guid] = nil 
			end
		end)
	end
end)

return player_manager