
local channel = require "channel"
local dump = require "fix.dump"

local param = ...
if param and param == "reload" then
	channel.call("config.?","msg","reload_global")
else
	local global_conf = channel.call("config.?","msg","global_conf")

	_P.debug["_ENV"].global_conf = global_conf
	dump(print,global_conf)
end

