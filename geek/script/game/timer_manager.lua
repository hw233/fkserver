require "functions"
local log = require "log"

timer_manager = timer_manager or {
	last_tick = os.clock(),
	timers = {},
	pool_timers = {},
	named_timers = {}
}

local timer = class("timer")

function timer:ctor(id,time,func,name,is_repeat,init_pause)
	if not id or type(id) ~= "number" or not time or type(time) ~= "number" or not func or type(func) ~= "function" then  return end
    self.id = id
    self.remainder = time
	self.name = name
    self.interval = time
    self.callback = func
    self.repeated = is_repeat
    self.paused = init_pause
end

function timer:pause()
	if not self.paused then return end
    self.paused = true
end

function timer:resume()
	if not self.id or not self.remainder then return end

    self.paused = false
end

function timer:restart(func)
    if not self.id or not self.interval then return end
	if func and type(func) == "function" then self.callback = func end

    self.paused = false
    self.remainder = self.interval

    if timer_manager:get_timer(self.id) ~= self then
		self.id = timer_manager:generate_id()
		timer_manager.pool_timers[self.id] = self 
	end
end

function timer:kill()
	if not self.id or not timer_manager.timers[self.id] then return end
    timer_manager:kill_timer(self)
end


function timer_manager:new_timer(time,func,name,is_repeat,init_pause)
    if not time or type(time) ~= "number" or time <= 0 or type(func) ~= "function" then  return nil end
	
	if name and self.named_timers[name] then 
		log.error("new timer error,name [%s] already exists",name)
		return false 
	end

    local id = self:generate_id()
    local timer = timer.new(id,time,func,name,is_repeat,init_pause)
    self.pool_timers[id] = timer
	if name and type(name) == "string" then
		self.named_timers[name] = timer
	end

	return timer
end

function timer_manager:generate_id()
	self.current_id = self.current_id or 0
	repeat 
		self.current_id = self.current_id + 1
		if self.current_id > 100000000 then self.current_id = 1 end
	until not self.timers[self.current_id]  and not self.pool_timers[self.current_id]
	return self.current_id
end

function timer_manager:kill_timer(name_or_id_or_timer)
	if not name_or_id_or_timer then return end

	local timer = self:get_timer(name_or_id_or_timer)
	if not timer then return end

	if timer.id then 
		self.timers[timer.id] = nil 
		self.pool_timers[timer.id] = nil 
	end

	if timer.name then 
		self.named_timers[timer.name] = nil 
	end
end


function timer_manager:get_timer(name_or_id_or_timer)
	if type(name_or_id_or_timer) == "string" then 
		if not self.named_timers[name_or_id_or_timer] then return nil 
		else return self.named_timers[name_or_id_or_timer] end
	end

	if type(name_or_id_or_timer) == "number" then
		if not self.timers[name_or_id_or_timer] and not self.pool_timers[name_or_id_or_timer] then return nil
		elseif self.timers[name_or_id_or_timer] then return self.timers[name_or_id_or_timer] 
		elseif self.pool_timers[name_or_id_or_timer] then return self.pool_timers[name_or_id_or_timer] end
	end
	
	if type(name_or_id_or_timer) == "table" then 
		return name_or_id_or_timer
	end

	return nil
end

function timer_manager:tick()
    local now_second = os.clock()
    local delta = now_second - self.last_tick
    self.last_tick = now_second
    for i,timer in pairs(self.timers) do
        if timer and not timer.paused then
            timer.remainder = timer.remainder - delta
            if timer.remainder <= 0 then 
				timer.callback() 
				if timer.repeated then  timer.remainder = timer.interval
				else  
					if timer.name then self.named_timers[timer.name] = nil end
					self.timers[i] = nil  
				end
			end
        end
    end

	table.mergeto(self.timers,self.pool_timers,function(_,r) return r end)
	self.pool_timers = {}
end

function timer_manager:calllater(s,func)
	self:new_timer(s,func)
end

return timer_manager
