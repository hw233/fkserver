
local skynet = require "skynet"
local log = require "log"

local table = table
local tinsert = table.insert
local tremove = table.remove
local coroutine = coroutine
local traceback = debug.traceback

local m = {}

function m:lock()
	local co = coroutine.running()
	if self.current_thread and co ~= self.current_thread then
		tinsert(self.thread_queue,co)
		skynet.wait(co)
		assert(self.ref == 0)
	end
	
	self.current_thread = co
	self.ref = self.ref + 1
end

function m:unlock()
	self.ref = self.ref - 1
	
	if self.ref == 0 then
		local co = tremove(self.thread_queue,1)
		if co then
			skynet.wakeup(co)
		end
		self.current_thread = nil
	end
end

local function xpcall_ret(t,ok,...)
	t:unlock()
	assert(ok, (...))
	return ...
end

local function call(t,fn,...)
	t:lock()
	return xpcall_ret(t,xpcall(fn,traceback,...))
end

return function()
	local o = {
		ref = 0,
		thread_queue = {}
	}

	setmetatable(o,{
		__index = m,
		__call = call
	})

	return o
end