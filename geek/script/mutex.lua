
local channel = require "channel"
local timer = require "timer"
local skynet = require "skynet"

local xpcall = xpcall
local traceback = debug.traceback

local mutexd = "mutex.?"

local function release_ret(id,ok,...)
	local release_ok,succ = channel.pcall(mutexd,"lua","release",id)
	assert(release_ok and succ)
	return ok,...
end

return function(id,fn,...)
		local ok = channel.pcall(mutexd,"lua","aquire",id)
		assert(ok)
		return release_ret(id,xpcall(fn,traceback,...))
	end