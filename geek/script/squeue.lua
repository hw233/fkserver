local m = {}

local skynet = require "skynet"
local log = require "log"

local table = table
local tinsert = table.insert
local tremove = table.remove
local coroutine = coroutine

function m:aquire()
	local co = coroutine.running()
	if self.current_thread and co ~= self.current_thread then
		tinsert(self.thread_queue,co)
		skynet.wait(co)
	end

	self.ref = self.ref + 1
	self.current_thread = co
end

function m:release()
	self.ref = self.ref - 1
	
	if self.ref == 0 then
		local co = tremove(self.thread_queue,1)
		if co then
			skynet.wakeup(co)
		end
		self.current_thread = nil
	end
end

return function()
	local o = {
		ref = 0,
		thread_queue = {}
	}

	setmetatable(o,{__index = m})

	return o
end