local skynet = require "skynetproto"
local channel = require "channel"
local queue = require "skynet.queue"
local log = require "log"
local redisopt = require "redisopt"
local g_common = require "common"

local reddb = redisopt.default

local string = string
local strfmt = string.format

LOG_NAME = "queue"

local session = {}

function session:lockcall(fn,...)
	self.lock = self.lock or queue()
	return self.lock(fn,...)
end

local sessions = setmetatable({},{
	__index = function(t,guid)
		local s = setmetatable({},{__index = session})
		t[guid] = s
		return s
	end,
})

local queues = setmetatable({},{
	__index = function(t,guid)
		local l = queue()
		t[guid] = l
		return l
	end
})

local CMD = {}

 -- SEND
function CMD.S(guid,...)
	local l = queues[guid]
	local s = rawget(sessions,guid)
	if not s then
		log.error("send nil session,%s",guid)
		return
	end
	
	if not s.server then
		log.error("call nil session server,%s",guid)
		return
	end

	return l(channel.call,"service." .. s.server,...)
end

 --CALL
function CMD.C(guid,...)
	local l = queues[guid]
	local s = rawget(sessions,guid)
	if not s then
		log.error("call nil session,%s",guid)
		return
	end

	if not s.server then
		log.error("call nil session server,%s",guid)
		return
	end

	return l(channel.call,"service." .. s.server,...)
end

 --BROKER
function CMD.B(guid,...)
	local l = queues[guid]
	return l(channel.call,...)
end

--PUBLISH
function CMD.P(...)
	channel.publish(...)
end

function CMD.Login(guid,gate)
	local s = rawget(sessions,guid)
	if s then
		local old_gate = s.gate
		if old_gate and old_gate ~= gate then
			channel.call("gate."..tostring(old_gate),"lua","kickout",guid)
		end

		if s.server then
			local reconnect = s:lockcall(function()
				-- Quit already
				if not rawget(sessions,guid) then
					log.warning("Login reconnecting double check got nil session,Quit already,%s",guid)
					return false
				end

				s.gate = gate
				reddb:hset(strfmt("player:online:guid:%d",guid),"gate",gate)
				local l = queues[guid]
				return l(channel.call,"game."..s.server,"msg","LS_LoginNotify",guid,true,gate)
			end)

			if reconnect then
				return true,s.server
			end
		end
	end

	local server = g_common.lobby_id(guid)
	local s = sessions[guid]
	return s:lockcall(function()
		local l = queues[guid]
		-- double check
		if not rawget(sessions,guid) then
			s = sessions[guid]
			return s:lockcall(function()
				reddb:hmset(strfmt("player:online:guid:%d",guid),{
					server = server,
					gate = gate
				})

				l(channel.call,"game."..s.server,"msg","LS_LoginNotify",guid,false,gate)
				s.gate = gate
				s.server = server
				return false,server
			end)
		end

		reddb:hmset(strfmt("player:online:guid:%d",guid),{
			server = server,
			gate = gate
		})

		l(channel.call,"game."..server,"msg","LS_LoginNotify",guid,false,gate)
		s.gate = gate
		s.server = server

		return false,server
	end)
end

function CMD.Quit(guid)
	local s = rawget(sessions,guid)
	if not s then
		log.error("Exit got nil session,%s",guid)
		return
	end

	sessions[guid] = nil
	reddb:del(strfmt("player:online:guid:%d",guid))
end

function CMD.GoServer(guid,to)
	local s = rawget(sessions,guid)
	if not s then
		log.error("Go Server %s,%s got nil session",guid,to)
		return
	end

	s:lockcall(function()
		s.server = to
		reddb:hset(strfmt("player:online:guid:%d",guid),"server",to)
	end)
end

local function checkloginconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkloginconf(conf)
    LOG_NAME = "queue."..conf.id
end

skynet.start(function()
	skynet.dispatch("lua",function(_,_,cmd,...)
		local f = CMD[cmd]
		if not f then
			log.error("unkown cmd %s",cmd)
			skynet.retpack()
			return
		end
		
		skynet.retpack(f(...))
	end)
end)