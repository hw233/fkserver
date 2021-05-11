local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local timer = require "timer"
local log = require "log"

local CMD = _P.lua.CMD
local command = CMD.command

local upvals = getupvalue(command)

local getupvals = getupvalue(upvals.command.get)

local fnupvals = getupvalue(getupvals.fn)

local cache = fnupvals.cache

local pushupvals = getupvalue(fnupvals.cache_push)

local default_elapsed_time = 5

local tremove = table.remove
local tinsert = table.insert

-- for k,c in pairs(cache) do
--   if c.value == "57990a4cf2c8d2b4229adc23981208e2b7521552" then
--      dump(print,k)
--      cache[k] = nil
--   end
  --if k == "player:account:57990a4cf2c8d2b4229adc23981208e2b7521552" then
  --   dump(print,c.value)
  --   cache[k] = nil
  --end
-- end

local queuelock = fnupvals.queuelock
local do_redis_command = fnupvals.do_redis_command

local function string_set(db,cmd,key,val)
	return queuelock(key,function()
		local c = cache[key]
		if c then
			c.value = val
		end
		return do_redis_command(db,cmd,key,val)
	end)
end

upvals.command.set = function(db,...)
  return string_set(db,"set",...)
end

dump(print,upvals.command)
