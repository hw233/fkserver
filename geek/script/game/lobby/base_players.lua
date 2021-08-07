local redisopt = require "redisopt"

local base_player = require "game.lobby.base_player"

local timermgr = require "timermgr"

local log = require "log"

local reddb = redisopt.default

local table = table

local tinsert = table.insert
local tremove = table.remove

local unused_player_info_elapsed = 30

local queue = require "skynet.queue"

local infolock = setmetatable({},{
	__index = function(t,guid)
		local lock = queue()
		t[guid] = lock
		return lock
	end,
})

local alivetime = {}

local mgr = {}

setmetatable(mgr,{
	__index = function(t,guid)
        if type(guid) ~= "number" then
            return
        end
		local lock = infolock[guid]
		return lock(function()
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


local readwriter = setmetatable({},{
	__index = function(_,guid)
		return mgr[guid]
	end,
	__newindex = function(_,guid,v)
		if v == nil then
			mgr[guid] = nil
			infolock[guid] = nil
		end
	end
})

timermgr:loop(unused_player_info_elapsed,function()
	local deadguid = {}
	for guid,p in pairs(mgr) do
		if 	not p.online and
			not p.table_id and
			not p.chair_id
		then
			log.info("collect guid:%s",guid)
			tinsert(deadguid,guid)
		end
	end

	local guid
	repeat
		guid = tremove(deadguid,1)
		if not guid then break end
		
		local p = mgr[guid]
		if p then
			p:lockcall(function()
				-- double check
				if 	not p.online and
					not p.table_id and
					not p.chair_id
				then
					log.info("clean guid info: %s",guid)
					readwriter[guid] = nil
				end
			end)
		end
	until not guid
end)

return readwriter