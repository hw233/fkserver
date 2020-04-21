local skynet = require "skynetproto"

local log_name_files = {}
local service_file = {}

os.execute([[
	if [ ! -d "./log" ];then
		mkdir ./log
	fi
	]])

local CMD = {}

local function log_file(service)
	local filename = string.format("./log/%s_%s.log",service,os.date("%Y-%m-%d"))
	if not log_name_files[filename] then
		if service_file[service] then io.close(service_file[service]) end
		local f = io.open(filename,"a+")
		log_name_files[filename] = f
		service_file[service] =f
	end
    return log_name_files[filename]
end

function CMD.do_log(servicename,log)
    local file = log_file(servicename)
    file:write(log.."\n")
    file:flush()
end

skynet.start(function()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			error("unknown cmd:"..cmd)
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