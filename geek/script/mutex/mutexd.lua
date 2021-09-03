
local skynet = require "skynet"
local log = require "log"

local table = table
local tinsert = table.insert
local tremove = table.remove
local coroutine = coroutine

LOG_NAME = "mutex"

local thread_queue = {}

local CMD = {}

function CMD.aquire(id,req)
	thread_queue[id] = thread_queue[id] or {
		threads = {},
		curreq = req,
		ref = 0,
	}
	local queue = thread_queue[id]
	local threads = queue.threads

	if req ~= queue.curreq then
		local co = coroutine.running()
		tinsert(threads,co)
		skynet.wait(co)
	end

	queue.curreq = req
	queue.ref = queue.ref + 1
end

function CMD.release(id,req)
	local queue = thread_queue[id]
	if not queue then
		log.error("release lock %s,%s queue is nil",id,req)
		return true
	end

	if req ~= queue.curreq then
		log.error("release lock %s,%s not current req",id,req)
		return false,queue.curreq
	end

	queue.ref = queue.ref - 1
	
	if queue.ref == 0 then
		local co = tremove(queue.threads,1)
		if co then
			skynet.wakeup(co)
		else
			thread_queue[id] = nil
		end
	end

	return true,req
end

function CMD.start()
	
end

function CMD.term()
	
end

skynet.start(function()
	skynet.dispatch("lua",function(_,_,cmd,...)
		local fn = CMD[cmd]
		assert(fn)
		skynet.retpack(fn(...))
	end)
end)