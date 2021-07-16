local skynet = require "skynet"
local chronos = require "chronos"

local log_name_files = {}
local service_file = {}

local string = string
local strfmt = string.format
local math = math
local mfloor = math.floor
local mceil = math.ceil
local os = os

os.execute([[
	if [ ! -d "./log" ];then
		mkdir ./log
	fi
	]])

local function log_file(service)
	local filename = strfmt("./log/%s_%s.log",service,os.date("%Y-%m-%d"))
	if not log_name_files[filename] then
		if service_file[service] then io.close(service_file[service]) end
		local f = io.open(filename,"a+")
		log_name_files[filename] = f
		service_file[service] =f
	end
    	return log_name_files[filename]
end

local function do_log(_,_,servicename,log)
    local file = log_file(servicename)
    file:write(log.."\n")
    file:flush()
end

local function log_text(_, address, msg)
	local time = chronos.nanotime()
	local strtime = strfmt("[%s.%03d]",os.date("%Y-%m-%d %H:%M:%S",mfloor(time)),mceil((time % 1) * 1000))
	local log = strfmt("%s %-8s%08x: %s",strtime,"SYSTEM ",address, msg)
	local file = log_file("system")
	file:write(log.."\n")
	file:flush()
	print(log)
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = log_text,
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function(_,address)
		local channel = require "channel"
		log_text(_,address,"TERM")
		local ok,err = pcall(channel.term)
		if not ok then
			log_text(_,address,err)
		end
		require "skynet.manager"
		skynet.abort()
		log_text(_,address,"TERM END,ABORTED")
	end
}

skynet.dispatch("lua",do_log)

skynet.start(function()
	
end)



