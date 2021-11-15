local skynet = require "skynet"

local math = math
local random = math.random

local redis = {}

local redismgrd

local redisds

local function redisd()
	redisds = redisds or skynet.call(redismgrd,"lua","service")
	return redisds[random(1,#redisds)]
end

function redis.close()
	for _,redisd in pairs(redisds) do
		skynet.send(redisd,"lua","close")
	end
end

function redis.command(db,cmd,...)
	return skynet.call(redisd(),"lua","command",db,cmd,...)
end

skynet.init(function()
	redismgrd = skynet.uniqueservice("redismgrd")
end)

return redis

