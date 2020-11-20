require "functions"
local log = require "log"
local skynet = require "skynet"

local timer_manager = {}

local swap = {}
local timers = {}
local nametimers = {}
local last_tick = skynet.time()
local current_id = 0

local function generate_id()
	repeat 
		current_id = (current_id % 100000000) + 1
	until not timers[current_id]  and not swap[current_id]
	return current_id
end

local function gettimer(timer_or_id)
	if type(timer_or_id) == "string" then 
		return nametimers[timer_or_id]
	end

	if type(timer_or_id) == "number" then
		return timers[timer_or_id]
	end
	
	if type(timer_or_id) == "table" then
		return timer_or_id
	end
end

local timer = {}

function createtimer(id,time,func,name,is_repeat,init_pause)
	if  not time or 
		type(time) ~= "number" or
		not func or 
		type(func) ~= "function" 
	then  
		return
	end

	return setmetatable({
		id = id or generate_id(),
		remainder = time,
		name = name,
		interval = time,
		callback = func,
		repeated = is_repeat,
		paused = init_pause,
	},{
		__index = timer,
	})
end

function timer:pause()
	if not self.paused then return end
    self.paused = true
end

function timer:resume()
	if not self.id or not self.remainder then return end

    self.paused = nil
end

function timer:restart(func)
    if not self.id or not self.interval then return end
	if func and type(func) == "function" then self.callback = func end

    self.paused = nil
    self.remainder = self.interval

    if timer_manager:get_timer(self.id) ~= self then
		self.id = generate_id()
		swap[self.id] = self 
	end
end

function timer:kill()
    timer_manager:kill_timer(self)
end

function timer_manager:new_timer(time,func,name,is_repeat,init_pause)
	if not time or 
		type(time) ~= "number" or 
		time < 0 or 
		type(func) ~= "function" 
	then  
		return nil 
	end

	if time == 0 then
		skynet.fork(func)
		return
	end
	
	if name and nametimers[name] then 
		log.error("new timer error,name [%s] already exists",name)
		return false 
	end

    local id = generate_id()
	local timer = createtimer(id,time,func,name,is_repeat,init_pause)
    swap[id] = timer
	if name and type(name) == "string" then
		nametimers[name] = timer
	end

	return timer
end



function timer_manager:kill_timer(timer_or_id)
	if not timer_or_id then
		log.warning("timer_manager:kill_timer got nil timer id.")
		return 
	end

	local timer = gettimer(timer_or_id)
	if not timer then 
		log.warning("timer_manager:kill_timer no timer id:%s.",timer_or_id)
		return 
	end

	local id = timer.id
	local name = timer.name
	if id then 
		timers[id] = nil
		swap[id] = nil
	end

	if name then 
		nametimers[name] = nil 
	end
end


function timer_manager:get_timer(timer_or_id)
	return gettimer(timer_or_id)
end

function timer_manager:tick()
    local now_second = skynet.time()
    local delta = now_second - last_tick
    last_tick = now_second
	for i,timer in pairs(timers) do
		repeat 
			if timer.paused then break end

			timer.remainder = timer.remainder - delta

			if timer.remainder > 0 then break end

			skynet.fork(timer.callback) 
			if timer.repeated then  
				timer.remainder = timer.interval
			else  
				if timer.name then nametimers[timer.name] = nil end
				timers[i] = nil
			end
		until true
	end

	for id,t in pairs(swap) do
		timers[id] = t
	end

	swap = {}
end

function timer_manager:calllater(s,func)
	return self:new_timer(s,func)
end

function timer_manager:loop(time,func)
	return self:new_timer(time,func,nil,true)
end

local function on_tick()
	timer_manager:tick()
	skynet.timeout(5,on_tick)
end

skynet.timeout(5,on_tick)

return timer_manager
