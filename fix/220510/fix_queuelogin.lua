
local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local log = require "log"
local channel = require "channel"
local redisopt = require "redisopt"
local g_common = require "common"
local enum = require "pb_enums"

local reddb = redisopt.default

local strfmt = string.format

local upvals = getupvalue(_P.lua.CMD.Login)

dump(print,upvals)

local queues = upvals.queues
local sessions = upvals.sessions

local function Login(guid,gate)
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

_P.lua.CMD.Login = Login