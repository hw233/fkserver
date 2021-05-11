
local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local redisopt = require "redisopt"

local reddb = redisopt.default

local key = ...
if not key then
	print("unkown key",key)
	return
end

reddb:del(key)

print("success!")