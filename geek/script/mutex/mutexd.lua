
local skynet = require "skynet"
local log = require "log"

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
	local ids = {...}
	local co = coroutine.running()
	for _,id in pairs(ids) do
		batch_queue[id] = batch_queue[id] or {
			threads = {},
			current_thread = co,
		}

		local q = batch_queue[id]
		if co ~= q.current_thread then
			table.insert(q.threads,co)
		end
	end

	local function all_wakeup()
		for _,id in pairs(ids) do
			local q = batch_queue[id]
			if q.current_thread ~= co then
				return false
			end
		end

		return true
	end

	while true do
		if all_wakeup() then
			break
		end

		skynet.wait(co)
	end
end

local function release_batch(...)
	for _,id in pairs({...}) do
		local q = batch_queue[id]
		local co = table.remove(q.threads,1)
		if co then
			q.current_thread = co
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