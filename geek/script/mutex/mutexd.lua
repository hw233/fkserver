
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
	local co = coroutine.running()
	thread_queue[id] = thread_queue[id] or {
		threads = {},
		current_thread = co,
	}

	local queue = thread_queue[id]
	local threads = queue.threads
	if co ~= queue.current_thread then
		tinsert(threads,co)
		skynet.wait(co)
	end

	queue.current_thread = co
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
			q = {}
			batch_queue[id] = q
		else
			table.insert(q,co)
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
		local co = table.remove(q,1)
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