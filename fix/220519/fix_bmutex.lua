
local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
require "functions"

local skynet = require "skynet"

local upvals = getupvalue(_P.lua.CMD.aquire_batch)
local ab_upvals = getupvalue(upvals.aquire_batch)

local batch_queue = ab_upvals.batch_queue

dump(print,batch_queue)

-- local function aquire_batch(...)
-- 	local co = coroutine.running()
-- 	local wait = 0

-- 	for _,id in pairs({...}) do
-- 		local q = batch_queue[id]
-- 		if not q then
-- 			q = { threads = {} }
-- 			batch_queue[id] = q
-- 		else
-- 			table.insert(q.threads,co)
-- 			wait = wait + 1
-- 		end
-- 	end

-- 	for _ = 1,wait do
-- 		skynet.wait(co)
-- 	end
-- end

local function release_batch(...)
	for _,id in pairs({...}) do
		local q = batch_queue[id]
		assert(q)
		local co = table.remove(q.threads,1)
		if co then
			skynet.wakeup(co)
		else
			batch_queue[id] = nil
		end
	end
end

-- _P.lua.CMD.aquire_batch = function(...) return aquire_batch(...) end
-- _P.lua.CMD.release_batch = function(...) return release_batch(...) end
-- print("fix success")

release_batch("action_81093320_682620","action_81093320_203440")
release_batch("action_81093320_581428","action_81093320_203440")

dump(print,batch_queue)