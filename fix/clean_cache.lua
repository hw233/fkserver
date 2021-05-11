local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local command = _P.lua.command

local getupvals = getupvalue(command.get)

local fnupvals = getupvalue(getupvals.fn)

local cache = fnupvals.cache

local key = ...

if not key or key == "" then
	print("key can not be nil:",key)
	return
end

dump(print,cache[key])

cache[key] = nil

print(string.format("clean %s success!",key))