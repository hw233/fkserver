local skynet = require "skynetproto"
local channel = require "channel"
local queue = require "skynet.queue"
local log = require "log"

LOG_NAME = "queue"

local queues = setmetatable({},{
	__index = function(t,guid)
		local l = queue()
		t[guid] = l
		return l
	end
})

local CMD = {}

function CMD.S(guid,...)
	local l = queues[guid]
	return l(channel.call,...)
end

function CMD.C(guid,...)
	local l = queues[guid]
	return l(channel.call,...)
end

function CMD.P(...)
	channel.publish(...)
end

function CMD.D(guid)
	
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