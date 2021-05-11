local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local base_player = require "game.lobby.base_player"
local queue = require "skynet.queue"

function base_player:lockcall(fn,...)
	self.lock = self.lock or queue()
	return self.lock(fn,...)
end

