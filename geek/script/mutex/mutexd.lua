
local skynet = require "skynet"
local log = require "log"
local timer = require "timer"
require "functions"


local table = table
local tinsert = table.insert
local tremove = table.remove
local coroutine = coroutine

LOG_NAME = "mutex"

local thread_queue = {}

local batch_queue = {}

local CMD = {}

local function aquire(id)
	local queue = thread_queue[id]
	if queue then
		local co = coroutine.running()
		tinsert(queue.threads,co)
		skynet.wait(co)
	else
		queue = { threads = {},}
		thread_queue[id] = queue
	end
end

local function release(id)
	local queue = thread_queue[id]
	if not queue then
		log.error("release mutex %s, queue is nil",id)
		return true
	end

	local co = tremove(queue.threads,1)
	if co then
		skynet.wakeup(co)
	else
		thread_queue[id] = nil
	end

	return true
end

local function aquire_batch(...)
	local co = coroutine.running()
	local wait = 0

	for _,id in pairs({...}) do
		local q = batch_queue[id]
		if not q then
			q = { threads = {} }
			batch_queue[id] = q
		else
			table.insert(q.threads,co)
			wait = wait + 1
		end
	end

	for _ = 1,wait do
		skynet.wait(co)
	end
end

local function release_batch(...)
	for _,id in pairs({...}) do
		local q = batch_queue[id]
		assert(q)
		local co = table.remove(q.threads,1)
		if co then
			skynet.wakeup(co)
		else
			batch_queue[id] = nil
		end
	end
end

function CMD.aquire(id)
	return aquire(id)
end

function CMD.release(id)
	return release(id)
end

function CMD.aquire_batch(...)
	return aquire_batch(...)
end

function CMD.release_batch(...)
	return release_batch(...)
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