local skynet = require "skynetproto"
local channel = require "channel"
local queue = require "skynet.queue"
local log = require "log"
local redisopt = require "redisopt"
local g_common = require "common"
local enum = require "pb_enums"

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

		log.info("S %s %p",guid,...)

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

		log.info("C %s %p",guid,...)

		return channel.call("service." .. s.server,...)
	end,...)
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
	local l = queues[guid]
	return l(function()
		log.info("Login %s %s",guid,gate)
		local s = rawget(sessions,guid)
		if s then
			local old_gate = s.gate
			if old_gate and old_gate ~= gate then
				channel.call("gate."..tostring(old_gate),"lua","kickout",guid)
			end

			local all_lobby = g_common.all_game_server(1)
			if s.server and not all_lobby[s.server] then
				s.gate = gate
				reddb:hset(strfmt("player:online:guid:%d",guid),"gate",gate)
				local _,reconnect =  channel.call("game."..s.server,"msg","LS_LoginNotify",guid,true,gate)
				if reconnect then
					return enum.ERROR_NONE,true,s.server
				end
			end
		end

		local server = g_common.lobby_id(guid)
		s = sessions[guid]
		local result = channel.call("game."..server,"msg","LS_LoginNotify",guid,false,gate)
		if result == enum.ERROR_NONE then
			reddb:hset(strfmt("player:online:guid:%d",guid),"gate",gate)
			s.gate = gate
			s.server = server
		end

		return result,false,server
	end)
end

function CMD.Quit(guid)
	log.info("Quit %s",guid)
	local s = rawget(sessions,guid)
	if not s then
		log.error("Exit got nil session,%s",guid)
		return
	end

	sessions[guid] = nil
	reddb:del(strfmt("player:online:guid:%d",guid))
end

function CMD.GoServer(guid,to)
	log.info("GoServer %s %s",guid,to)

	local s = rawget(sessions,guid)
	if not s then
		log.error("Go Server %s,%s got nil session",guid,to)
		return
	end

	s.server = to
	reddb:hset(strfmt("player:online:guid:%d",guid),"server",to)
end

function CMD.ForceExitRoom(guid,reason)
	local l = queues[guid]
	return l(function()
		local s = rawget(sessions,guid)
		if s and s.server then
			return channel.call("game."..s.server,"msg","QS_ForceExitRoom",guid,reason)
		else
			log.error("sessions %s got nil session",guid)
			return enum.ERROR_PLAYER_NOT_EXIS
		end
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