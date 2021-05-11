local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local CMD = _P.lua.CMD
local command = CMD.command

local upvals = getupvalue(command)

local getupvals = getupvalue(upvals.command.get)

local fnupvals = getupvalue(getupvals.fn)

local cache = fnupvals.cache

local key = ...

if not key or key == "" then
	print("key can not be nil:",key)
	return
end

dump(print,cache[key])