local skynet = require "skynetproto"

local log_name_files = {}

os.execute([[
	if [ ! -d "./log" ];then
		mkdir ./log
	fi
	]])

local CMD = {}

local function log_file(filename)
    log_name_files[filename] = log_name_files[filename] or io.open(filename,"a+")
    return log_name_files[filename]
end

function CMD.do_log(servicename,log)
    local filename = string.format("./log/%s_%s.log",servicename,os.date("%Y-%m-%d"))
    local file = log_file(filename)
    file:write(log.."\n")
    file:flush()
end

skynet.start(function()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			log.error("unknown cmd:"..cmd)
			skynet.retpack(nil)
		end
	end)

	require "skynet.manager"
	local handle = skynet.localname ".logd"
	if handle then
		skynet.exit()
		return handle
	end

	skynet.register ".logd"
end)