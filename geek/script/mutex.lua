
local channel = require "channel"
local timer = require "timer"
local skynet = require "skynet"

local xpcall = xpcall
local traceback = debug.traceback

local mutexd = "mutex.?"

local function gen_req(id)
	return tostring(id) .. tostring(timer.milliseconds_time()) .. "." .. tostring(math.random(1000000))
end

local function release_ret(id,req,ok,...)
	local release_ok,succ,q = channel.pcall(mutexd,"lua","release",id,req)
	assert(release_ok and succ and q == req)
	return ok,...
end

return function(id,fn,...)
		local req = gen_req(id)
		local ok = channel.pcall(mutexd,"lua","aquire",id,req)
		assert(ok)
		return release_ret(id,req,xpcall(fn,traceback,...))
	end