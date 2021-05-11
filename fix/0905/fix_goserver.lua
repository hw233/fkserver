local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local redisopt = require "redisopt"
local log = require "log"
local channel = require "channel"

local CMD = _P.lua.CMD

local Login = CMD.Login

local upvals = getupvalue(Login)

local sessions = upvals.sessions
local queues = upvals.queues

local reddb = redisopt.reddb

local strfmt = string.format

dump(print,upvals,1)
dump(print,sessions,1)
dump(print,queues,1)


 -- SEND
 function CMD.S(guid,...)
	local l = queues[guid]
	return l(function(...)
		-- dobule check
		local s = rawget(sessions,guid)
		if not s then
			log.error("send nil session,%s",guid)
			return
		end
		
		if not s.server then
			log.error("send nil session server,%s",guid)
			return
		end

		return channel.call("service." .. s.server,...)
	end,...)
end

 --CALL
function CMD.C(guid,...)
	local l = queues[guid]
	return l(function(...)
		-- dobule check
		local s = rawget(sessions,guid)
		if not s then
			log.error("call nil session,%s",guid)
			return
		end

		if not s.server then
			log.error("call nil session server,%s",guid)
			return
		end

		return channel.call("service." .. s.server,...)
	end,...)
end

function CMD.GoServer(guid,to)
	local s = rawget(sessions,guid)
	if not s then
		log.error("Go Server %s,%s got nil session",guid,to)
		return
	end
	
	s.server = to
	reddb:hset(strfmt("player:online:guid:%d",guid),"server",to)
end