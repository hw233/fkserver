local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local pdk_table = require "game.pdk.pdk_table"

local cards_util = require "game.pdk.cards_util"

local CARD_TYPE = cards_util.PDK_CARD_TYPE

local log = require "log"

function pdk_table:next_player_is_single()
	local play = self.rule and self.rule.play
	if not play then return end

	-- 下家报单必出最大单牌
	if play.bao_dan_discard_max then
		local next_player = self.players[self:next_chair()]
		if table.nums(next_player.hand_cards) == 1   then
			return true 
		end
	end
	return false 
end

function pdk_table:begin_discard()
	self:broadcast2client("SC_PdkDiscardRound",{
		chair_id = self.cur_discard_chair
	})

	local function auto_discard(player)
		if not self.last_discard then
			local cards = cards_util.seek_greatest(player.hand_cards,self.rule,self.first_discard)
			assert(cards and #cards > 0)
			if #cards==1 and self:next_player_is_single() then 
				local card,_ = table.max(player.hand_cards,function(_,c) return cards_util.value(c) end)
				self:do_action_discard(player,{card},true)
			else
				self:do_action_discard(player,cards,true)
			end 
			
		else
			if self:next_player_is_single() and self.last_discard.type == CARD_TYPE.SINGLE then 
				local card,hand_max_value = table.max(player.hand_cards,function(_,c) return cards_util.value(c) end)
				if hand_max_value > self.last_discard.value then 
					self:do_action_discard(player,{card},true)
				else
					self:do_action_pass(player,true)
				end 
			else 
				local cards = cards_util.seek_great_than(player.hand_cards,self.last_discard.type,self.last_discard.value,self.last_discard.count,self.rule)
				if not cards then
					self:do_action_pass(player,true)
				else
					assert(cards and #cards > 0)
					self:do_action_discard(player,cards,true)
				end
			end 
		end
	end

	local trustee_type,trustee_seconds = self:get_trustee_conf()
	if trustee_type and trustee_seconds then
		local player = self:cur_player()
		self:begin_clock_timer(trustee_seconds,function()
			auto_discard(player)
			self:set_trusteeship(player,true)
		end)

		if player.trustee then
			self:begin_discard_timer(math.random(1,2),function()
				auto_discard(player)
			end)
		end		
	end
end
