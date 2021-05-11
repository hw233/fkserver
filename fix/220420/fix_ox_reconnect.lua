local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local ox_table = require "game.ox.table"

local define = require "game.ox.define"

local table = table

local TABLE_STATUS = define.STATUS
local PLAYER_STATUS = define.PLAYER_STATUS

local log = require "log"

function ox_table:reconnect(player)
	log.info("fix ox_table:reconnect %s %s",self:id(),player.guid)
	local chair_id = player.chair_id
	local msg = {
		banker = self.banker,
		status = self.status or TABLE_STATUS.FREE,
		round = self:gaming_round(),
		players = table.map(self.gamers,function(p,chair)
			return chair,{
				chair_id = chair,
				guid = p.guid,
				call_banker_times = p.callbanker or -1,
				status = p.status or PLAYER_STATUS.WATCHER,
				total_score = p.total_score,
				total_money = p.total_money,
				score = p.bet_score,
				cards_pair = table.series(p.cards_pair or {},function(p) return {cards = p} end),
			}
		end),
		pstatus_list = table.map(self.players,function(p,chair)
			return chair,p.status or  PLAYER_STATUS.WATCHER
		end)
	}
	if not msg.players[chair_id] or (player.status and player.status == PLAYER_STATUS.BANKRUPTCY ) then 
		send2client(player,"SC_OxTableInfo",msg) 
		return 
	end 
	if self.status == TABLE_STATUS.CALLBANKER then
		local p = msg.players[chair_id]
		p.cards = self:get_an_cards(player.cards)
 		send2client(player,"SC_OxTableInfo",msg)
		self:on_reconnect_when_callbanker(player)
	elseif self.status == TABLE_STATUS.BET then
		local p = msg.players[chair_id]
		p.cards = self:get_an_cards(player.cards)
		send2client(player,"SC_OxTableInfo",msg)
		self:on_reconnect_when_bet(player)
	elseif self.status == TABLE_STATUS.SPLIT then
		local p = msg.players[chair_id]
		p.cards = player.cards
		send2client(player,"SC_OxTableInfo",msg)
		self:on_reconnect_when_split_cards(player)
	else
		send2client(player,"SC_OxTableInfo",msg)
	end

	if self.auto_timer then
		self:begin_clock(self.auto_timer.remainder,player)
	end
end
