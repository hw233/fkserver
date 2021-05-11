local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local base_table = require "game.lobby.base_table"
local enum = require "pb_enums"
local log = require "log"

function base_table:check_kickout_no_ready()
	log.info("base_table:check_kickout_no_ready")
	self:lockcall(function() 
		if not self:is_round_free() then
			return
		end

		local ready_count = table.sum(self.players,function(p) 
			return self.ready_list[p.chair_id] and 1 or 0 
		end)

		local player_count = table.nums(self.players)
		if player_count - ready_count ~= 1 or player_count ~= self.start_count then
			self:cancel_kickout_no_ready_timer()
			return
		end

		local trustee,seconds = self:get_trustee_conf()
		if trustee and seconds > 0 then
			self:begin_kickout_no_ready_timer(seconds,function()
				self:foreach(function(p)
					if not self.ready_list[p.chair_id] then
						p:force_exit(enum.STANDUP_REASON_NO_READY_TIMEOUT)
					end
				end)
			end)
		end
	end)
end