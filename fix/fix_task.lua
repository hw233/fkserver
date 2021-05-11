local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

require "functions"
local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local base_players = require "game.lobby.base_players"

local meta = getmetatable(base_players)

local upvals = getupvalue(meta.__index)

local mgr = upvals.mgr

local locks = {}

local queue = require "skynet.queue"

for guid,p in pairs(mgr) do
 if p.lock then
   locks[guid] = locks[guid] or {}
   local lockupvals = getupvalue(p.lock)
   local thread_queue = lockupvals.thread_queue
   if #thread_queue > 10 then
      for _,thread in pairs(thread_queue) do
	 --skynet.killthread(thread)
      end

      --p.lock = queue()
   end
   table.insert(locks[guid],thread_queue)
 end
end

dump(print,locks)
