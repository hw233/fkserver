
local channel = require "channel"
local timer = require "timer"
local skynet = require "skynet"

local xpcall = xpcall
local traceback = debug.traceback

local mutexd = "mutex.?"

local function release_ret(ids,ok,...)
	local release_ok = channel.pcall(mutexd,"lua","release_batch",table.unpack(ids))
	assert(release_ok)
	return ok,...
end

return function(ids,fn,...)
		assert(type(ids) == "table")
		local ok = channel.pcall(mutexd,"lua","aquire_batch",table.unpack(ids))
		assert(ok)
		return release_ret(ids,xpcall(fn,traceback,...))
	end