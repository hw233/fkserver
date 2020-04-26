local skynet = require "skynet"

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

local function log_text_dispatch(_, address, msg)
	local time = skynet.time()
	local strtime = string.format("[%s.%03d]",os.date("%Y-%m-%d %H:%M:%S",math.floor(time)),math.ceil((time % 1) * 1000))
	local log = string.format("%s %-8s%08x: %s",strtime,"SYSTEM ",address, msg)
	local file = log_file("system")
	file:write(log.."\n")
	file:flush()
	print(log)
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = log_text_dispatch,
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function()
		print("SIGHUP")
	end
}

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
end)



