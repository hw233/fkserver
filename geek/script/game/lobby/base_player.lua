-- game player

local pb = require "pb_files"
require "functions"
local base_character = require "game.lobby.base_character"
require "game.lobby.base_android"
local log  = require "log"
local enum = require "pb_enums"
require "data.item_details_table"
local channel = require "channel"
local item_details_table = item_details_table
local base_active_android = base_active_android

require "game.net_func"
require "table_func"
local send2client_pb = send2client_pb
local redisopt = require "redisopt"
local reddb = redisopt.default

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local ITEM_PRICE_TYPE_ROOM_CARD = pb.enum("ITEM_PRICE_TYPE","ITEM_PRICE_TYPE_ROOM_CARD")
local ITEM_PRICE_TYPE_DIAMOND = pb.enum("ITEM_PRICE_TYPE","ITEM_PRICE_TYPE_DIAMOND")

-- enum ITEM_TYPE 
local ITEM_TYPE_MONEY = pb.enum("ITEM_TYPE", "ITEM_TYPE_MONEY")
local ITEM_TYPE_BOX = pb.enum("ITEM_TYPE", "ITEM_TYPE_BOX")

-- enum LOG_MONEY_OPT_TYPE
local LOG_MONEY_OPT_TYPE_BOX = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BOX")

-- 玩家
local base_player = setmetatable({
	player_count = 0,
},{
	__index = base_character,
})

-- 初始化
function base_player:init(guid_, account_, nickname_)
	base_character.init(self,guid_,account_,nickname_)
	self.online = true
	self.in_game = true
	self.game_end_event = {}
	log.info("set player[%d] in_game true" ,self.guid)
	self.player_count = self.player_count + 1
end

function base_player:has_club_rights()
	return self.rights and self.rights.club ~= nil
end

function base_player:is_android()
	return self.guid < 0
end

-- 删除
function base_player:del()
	self.player_count = self.player_count - 1
end

-- 注册账号
function base_player:reset_account(account_, nickname_)
	self.account = account_
	self.nickname = nickname_
end

--发送pb消息
function base_player:send_pb(msgname,msg)
	send2client_pb(self,msgname,msg)
end

-- 检查房间限制
function base_player:check_room_limit(score,money_type)
	return self:get_money(money_type) < score
end

-- 进入房间并坐下
function base_player:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			ip_area = self.ip_area,
			first_game_type = def_first_game_type,
			second_game_type = def_second_game_type,
		}
		log.info("first_game_type = [%d] second_game_type = [%d]",def_first_game_type,def_second_game_type)
		tb:foreach_except(chair_id_, function (p)
			if p.chair_id then
				local v = {
					chair_id = p.chair_id,
					guid = p.guid,
					account = p.account,
					nickname = p.nickname,
					level = p:get_level(),
					money = p:get_money(),
					header_icon = p:get_header_icon(),
					ip_area = p.ip_area,
					icon = p.icon,
					sex = p.sex,
				}
				notify.pb_visual_info = notify.pb_visual_info or {}
				table.insert(notify.pb_visual_info, v)
			end
		end)
		
		send2client_pb(self, "SC_EnterRoomAndSitDown", notify)
	else
		send2client_pb(self, "SC_EnterRoomAndSitDown", {
			result = result_,
			})
	end
end

function base_player:change_table( room_id_, table_id_, chair_id_, result_, tb )
	print("===========base_player:change_table")
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_header_icon(),
				ip_area = p.ip_area,
			}
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		send2client_pb(self, "SC_ChangeTable", notify)
	else
		send2client_pb(self, "SC_ChangeTable", {
			result = result_,
			})
	end
end

-- 站起并离开房间
function base_player:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		log.info("send SC_StandUpAndExitRoom :"..result_)
		send2client_pb(self, "SC_StandUpAndExitRoom", {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})

		reddb:hdel("player:online:guid:"..tostring(self.guid),"first_game_type")
		reddb:hdel("player:online:guid:"..tostring(self.guid),"second_game_type")
		reddb:hdel("player:online:guid:"..tostring(self.guid),"server")
	else
		log.info("send SC_StandUpAndExitRoom nil "..result_)
		send2client_pb(self, "SC_StandUpAndExitRoom", {
			result = result_,
			})
	end
end

-- 切换座位
function base_player:on_change_chair(table_id_, chair_id_, result_, tb)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			ip_area = self.ip_area,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_header_icon(),
				ip_area = p.ip_area,
			}
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		send2client_pb(self, "SC_ChangeChair", notify)
	else
		send2client_pb(self, "SC_ChangeChair", {
			result = result_,
			})
	end
end

-- 进入房间
function base_player:on_enter_room(room_id_, result_)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(self, "SC_EnterRoom", {
			room_id = room_id_,
			result = result_,
			})
	else
		send2client_pb(self, "SC_EnterRoom", {
			result = result_,
			})
	end
end

-- 通知进入房间
function base_player:on_notify_enter_room(notify)
	send2client_pb(self, "SC_NotifyEnterRoom", notify)
end

-- 离开房间
function base_player:on_exit_room(result_)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(self, "SC_ExitRoom", {
			room_id = 0,
			result = result_,
		})
	else
		send2client_pb(self, "SC_ExitRoom", {
			result = result_,
		})
	end
end

-- 通知离开房间
function base_player:on_notify_exit_room(notify)
	log.info("on_notify_exit_room player [%d]  exit_player [%s] room_id[%s]",self.guid , tostring(notify.guid) , tostring(notify.room_id))
	send2client_pb(self, "SC_NotifyExitRoom", notify)
end

-- 坐下
function base_player:on_sit_down(table_id_, chair_id_, result_)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(self, "SC_SitDown", {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
	else
		send2client_pb(self, "SC_SitDown", {
			result = result_,
			})
	end

	return result_
end

-- 通知坐下
function base_player:notify_sit_down(player,reconnect)
	log.info("notify_sit_down  player guid[%d] ip_area =%s",player.guid , player.ip_area)
	send2client_pb(self, "SC_NotifySitDown", {
		table_id = player.table_id,
		pb_visual_info = player,
		is_online = reconnect,
	})
end

-- 站起
function base_player:on_stand_up(table_id_, chair_id_, result_)
	if result_ == enum.GAME_SERVER_RESULT_SUCCESS then
		print("=========base_player:on_stand_up true")
		send2client_pb(self, "SC_StandUp", {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
	else
		print("=========base_player:on_stand_up false")
		send2client_pb(self, "SC_StandUp", {
			result = result_,
			})
	end
end

-- 通知站起
function base_player:notify_stand_up(who,offline)
	send2client_pb(self, "SC_NotifyStandUp", {
		table_id = who.table_id,
		chair_id = who.chair_id,
		guid = who.guid,
		is_offline = offline and true or false,
	})
end

-- 通知空位置坐机器人
function base_player:on_notify_android_sit_down(room_id_, table_id_, chair_id_)
	local a = base_active_android:find_active_android(room_id_)
	if a then
		a:think_on_sit_down(room_id_, table_id_, chair_id_) 
	end
end



--------------------------------------------------------------
-- 以上继承于base_character
--------------------------------------------------------------



-- 得到玩家数量
function base_player:get_count()
	return self.player_count
end



-- 玩家存档发送到db
function base_player:save()
	--if self.flag_save_db or self.flag_base_info or self.flag_item_bag then
	-- if self.flag_base_info then
	-- 	log.info("base_player:save , guid [%d]  money [%d]",self.guid,self.money)
	-- 	self.flag_base_info = false
	-- 	send2db_pb("SD_SavePlayerData", {
	-- 		guid = self.guid,
	-- 		pb_base_info = self.pb_base_info,
	-- 	})
	-- end
end


function base_player:delete_notice(msg)
	-- body
	local notify = {
		msg_id = msg.msg_id,
		msg_type = msg.msg_type,
	}
	send2client_pb(self,"SC_DeletMsg",notify)
end

-- 玩家存档到redis
function base_player:save2redis()
	if self.flag_base_info then
		self.flag_base_info = false
		if self.pb_base_info then
			--redis_command(string.format("HSET player_base_info %d %s", self.guid, to_hex(pb.encode("PlayerBaseInfo", self.pb_base_info))))
		end
		self.flag_save_db = true
	end
end

-- 得到等级
function base_player:get_level()
	return self.level or 0
end

-- 得到钱
function base_player:get_money(money_type)
	if money_type == enum.ITEM_PRICE_TYPE_DIAMOND then
		return self.diamond or 0
	end

	if money_type == enum.ITEM_PRICE_TYPE_ROOM_CARD then
		return self.room_card or 0
	end

	return self.money or 0
end

--得到银行的钱
function base_player:get_bank_money( )
	return self.bank or 0
end

-- 得到头像
function base_player:get_header_icon()
	return self.header_icon
end


function base_player:log_money(money_type,why,old,now,old_bank,now_bank)
	send2db_pb("SD_LogMoney", {
		guid = self.guid,
		money_type = money_type,
		old_money = old,
		new_money = now,
		old_bank = old_bank,
		new_bank = now_bank,
		opt_type = why,
	})
end

function base_player:incrby(field,value)
	local v = reddb:hincrby("player:info:"..tostring(self.guid),field,string.format("%d",value))
	return tonumber(v)
end

function base_player:decrby(field,value)
	local v = reddb:hincrby("player:info:"..tostring(self.guid),field,string.format("%d",- value))
	return tonumber(v)
end

function base_player:decr_diamond(p,why)
	local money = self.diamond
	local oldmoney = money
	p.money = math.ceil(p.money)
	log.info("guid[%d] money_type[%d]  money[%d]" ,self.guid, p.money_type, p.money)
	log.info("money[%d] - p[%d]" , money,p.money)
	money = money - p.money
	self.diamond = money

	channel.publish("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = self.diamond,
		money_type = p.money_type,
	}})

	self:notify_money(why,money,money-oldmoney,enum.ITEM_PRICE_TYPE_DIAMOND)
	
	if self.guid > 0 then
		local newmoney = self:decrby("diamond",p.money)
		if newmoney ~= self.diamond then
			log.error("change diamond db ~= runtime")
		end

		self:log_money(enum.ITEM_PRICE_TYPE_DIAMOND,why,oldmoney,money,0,0)
	end
	
	log.info("decr_diamond  end oldmoney[%d] new_money[%d]" , oldmoney, self.diamond)
end

function base_player:decr_room_card(p,why)
	local money = self.room_card
	local oldmoney = money
	p.money = math.ceil(p.money)
	log.info("guid[%d] money_type[%d]  money[%d]" ,self.guid, p.money_type, p.money)
	log.info("money[%d] - p[%d]" , money,p.money)
	money = money - p.money
	self.room_card = money

	channel.publish("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = self.room_card,
		money_type = p.money_type,
	}})

	self:notify_money(why,money,money-oldmoney,enum.ITEM_PRICE_TYPE_ROOM_CARD)
	
	if not self:is_android() then
		local newmoney = self:decrby("room_card",p.money)
		if newmoney ~= self.room_card then
			log.error("change room_card db ~= runtime")
		end

		self:log_money(enum.ITEM_PRICE_TYPE_ROOM_CARD,why,oldmoney,self.room_card,0,0)
	end
	
	log.info("decr_room_card  end oldmoney[%d] new_money[%d]" , oldmoney, self.room_card)
end

function base_player:decr_gold(p,why)
	local money = self.money
	local oldmoney = money
	p.money = math.ceil(p.money)
	log.info("guid[%d] money_type[%d]  money[%d]" ,self.guid, p.money_type, p.money)
	log.info("money[%d] - p[%d]" , money,p.money)
	money = money - p.money
	self.money = money

	channel.publish("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = self.money,
		money_type = p.money_type,
	}})

	self:notify_money(why,money,money-oldmoney,enum.ITEM_PRICE_TYPE_GOLD)

	if not self:is_android() then
		local newmoney = self:decrby("money",p.money)
		if newmoney ~= self.money then
			log.error("change gold money db ~= runtime")
		end

		self:log_money(enum.ITEM_PRICE_TYPE_GOLD,why,oldmoney,self.money,self.bank,self.bank)
	end

	log.info("decr_gold  end oldmoney[%d] new_money[%d]" , oldmoney, self.money)
end

-- 花钱
function base_player:cost_money(price, why, whatever)
	for _, p in ipairs(price) do
		log.info("guid[%d] money_type[%d]  money[%d]" ,self.guid, p.money_type, p.money)
		if p.money_type == enum.ITEM_PRICE_TYPE_GOLD then
			self:decr_gold(p,why,whatever)
		elseif p.money_type == enum.ITEM_PRICE_TYPE_ROOM_CARD then
			self:decr_room_card(p,why,whatever)
		elseif p.money_type == enum.ITEM_PRICE_TYPE_DIAMOND  then
			self:decr_diamond(p,why,whatever)
		end
	end
end

--通知客户端金钱变化
function base_player:notify_money(why,money,changeMoney,money_type)
	money_type = money_type or enum.ITEM_PRICE_TYPE_GOLD
	send2client_pb(self, "SC_NotifyMoney", {
		opt_type = why,
		money_type = money_type,
		money = money,
		change_money = changeMoney,
		})
end

function base_player:notify_bank_money(why,money,change_money,money_type)
	money_type = money_type or enum.ITEM_PRICE_TYPE_GOLD
	send2client_pb(self, "SC_NotifyBank", {
		opt_type = why,
		money_type = money_type,
		money = money,
		change_money = change_money,
		})
end

function base_player:incr_gold(p,why)
	local money = self.money
	local oldmoney = money
	if p.money <= 0 then
		return
	end
	
	log.info("guid[%d] add money[%d]",self.guid , p.money)
	money = money + p.money
	self.money = money
	channel.publish("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = self.money,
		money_type = p.money_type,
	}})

	self:notify_money(why,money,money-oldmoney,enum.ITEM_PRICE_TYPE_GOLD)

	if not self:is_android() then
		local newmoney = self:incrby("money",p.money)
		if newmoney ~= self.money then
			log.error("change gold money db ~= runtime")
		end

		self:log_money(enum.ITEM_PRICE_TYPE_GOLD,why,oldmoney,self.money,self.bank,self.bank)
	end
end

function base_player:incr_room_card(p,why)
	local money = self.room_card
	local oldmoney = money
	if p.money <= 0 then
		return
	end
	
	log.info("guid[%d] add money[%d]",self.guid , p.money)
	money = money + p.money
	self.room_card = money

	channel.publish("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = self.room_card,
		money_type = p.money_type,
	}})
	
	self:notify_money(why,money,money-oldmoney,enum.ITEM_PRICE_TYPE_ROOM_CARD)
	
	if not self:is_android() then
		local room_card = self:incrby("room_card",p.money)
		if room_card ~= self.room_card then
			log.error("change room_card db ~= runtime")
		end
		self:log_money(enum.ITEM_PRICE_TYPE_ROOM_CARD,why,oldmoney,money,0,0)
	end
end

function base_player:incr_diamond(p,why)
	local money = self.diamond
	local oldmoney = self.diamond
	if p.money <= 0 then
		return
	end
	
	log.info("guid[%d] add money[%d]",self.guid , p.money)
	money = money + p.money
	self.diamond = money
	
	channel.publish("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = self.diamond,
		money_type = p.money_type,
	}})

	self:notify_money(why,money,money-oldmoney,enum.ITEM_PRICE_TYPE_DIAMOND)
	
	if not self:is_android() then
		local diamond = self:incrby("diamond",p.money)
		if diamond ~= self.diamond then
			log.error("change diamond db ~= runtime")
		end
		self:log_money(enum.ITEM_PRICE_TYPE_DIAMOND,why,oldmoney,money,0,0)
	end
end

-- 加钱
function base_player:add_money(price, opttype)
	for _, p in ipairs(price) do
		log.info("guid[%d] add money[%d],money_type:%d",self.guid , p.money,p.money_type)
		if p.money_type == enum.ITEM_PRICE_TYPE_GOLD then
			self:incr_gold(p,opttype)
		elseif p.money_type == enum.ITEM_PRICE_TYPE_ROOM_CARD then
			self:incr_room_card(p,opttype)
		elseif p.money_type == enum.ITEM_PRICE_TYPE_DIAMOND then
			self:incr_diamond(p,opttype)
		end
	end
end

-- 添加物品
function base_player:add_item(id, num)
	local item = item_details_table[id]
	if not item then
		log.error("guid[%d] item id[%d] not find in item details table", self.guid, id)
		return
	end
	
	if item.item_type == ITEM_TYPE_MONEY then
		local oldmoney = self.money
		self.money = self.money + num
		self.flag_base_info = true
		
		-- 收益
		send2db_pb("SD_UpdateEarnings", {
			guid = self.guid,
			money = num,
		})

		self:log_money(enum.ITEM_PRICE_TYPE_GOLD,LOG_MONEY_OPT_TYPE_BOX,oldmoney,self.money,self.bank,self.bank)
		return
	end
	
	self.pb_item_bag = self.pb_item_bag or {}
	self.pb_item_bag.items = self.pb_item_bag.items or {}
	for _, item in ipairs(self.pb_item_bag.items) do
		if item.item_id == id then
			item.item_num = item.item_num + num
			self.flag_item_bag = true
			return
		end
	end
	
	table.insert(self.pb_item_bag.items, {item_id = id, item_num = num})
	self.flag_item_bag = true
end

-- 删除物品
function base_player:del_item(id, num)
	if self.pb_item_bag and self.pb_item_bag.items then
		for i, item in ipairs(self.pb_item_bag.items) do
			if item.item_id == id and item.item_num >= num then
				if item.item_num == num then
					table.remove(self.pb_item_bag.items, i)
				else
					item.item_num = item.item_num - num
				end
				
				self.flag_item_bag = true
				return true
			end
		end
	end
	
	return false
end

-- 使用物品
function base_player:use_item(id, num)
	if self.pb_item_bag and self.pb_item_bag.items then
		for i, item in ipairs(self.pb_item_bag.items) do
			if item.item_id == id and item.item_num >= num then
				if item.item_num == num then
					table.remove(self.pb_item_bag.items, i)
				else
					item.item_num = item.item_num - num
				end
				
				self.flag_item_bag = true
				
				local itemdetail = item_details_table[id]
				if itemdetail.item_type == ITEM_TYPE_BOX then
					for _, v in ipairs(itemdetail.sub_item) do
						self:add_item(v.item_id, v.item_num * num)
					end
				end
				
				return true
			end
		end
	end
	
	return false
end

function base_player:setStatus(is_onLine)
	-- body
	if is_onLine then
	-- 掉线
		print("set online false")
		self.online = false
	else
	-- 强退
		print("set online true")
		self.online = true
	end
end

-- c修改银行钱
function  base_player:changeBankMoney( value,opttype, is_savedb)
	-- body
	log.info("changeBankMoney  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype)
	local oldbank = self.bank

	if oldbank + value then
		log.error("guid [%d] bank money[%d] value[%d]",self.guid ,oldbank ,value)
		return 2,oldbank,oldbank          -- 金钱不足
	end

	local bank_ = self:incrby("bank",value)
	self.bank = bank_
	self:notify_bank_money(opttype,bank_,bank_ - oldbank)
	log.info("opttype--------------%d",opttype)
	self:log_money(enum.ITEM_PRICE_TYPE_GOLD,opttype,self.money,self.money,oldbank,self.bank)
	log.info("changeBankMoney  end oldbank[%d] new_bank[%d]" , oldbank, self.bank)

	return enum.ChangMoney_Success,bank_,self.bank
end


--代理商转错后扣取玩家银行钱
--返回值:retcode,acturl_cost_money,reason
--acturl_cost_money 实际扣取金币数
--//原因reason (0--无，1--玩家银行金币0，2--玩家银行金币不够扣，3--玩家金币够扣,4--扣钱类型错误(扣钱传值为加钱))
function base_player:cost_player_banker_money( value, opttype ,is_savedb)
	log.info("cost_player_banker_money  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype)
	local oldbank = self.bank
	local flag_cost = 3 --默认玩家金币够扣
	local acturl_cost_money = 0

	if oldbank == 0 then
		log.warning("guid [%d] bank [%d] value[%d]",self.guid,oldbank,value)
		return -1,acturl_cost_money,1
	end

	if value > 0 then
		log.error("guid [%d] value[%d]",self.guid,value)
		return -1,acturl_cost_money,4
	else
		--cost money
		local tempMoney = oldbank + value
		if(tempMoney < 0) then --金币不够扣
			log.warning("guid [%d] bank money[%d] value[%d]",self.guid ,oldbank ,value)
			value = -oldbank
			flag_cost = 2  --金币不够扣
		end
	end

	log.info("guid [%d] bank money[%d] must cost money[%d]",self.guid ,oldbank ,value)
	
	local bank_ = self:incrby("bank",value)
	self.bank = bank_
	self:notify_bank_money(opttype,bank_,bank_ - oldbank)
	log.info("cost_player_banker_money:opttype--------------%d",opttype)
	self:log_money(enum.ITEM_PRICE_TYPE_GOLD,opttype,self.money,self.money,oldbank,self.bank)

	acturl_cost_money = value
	log.info("cost_player_banker_money  end oldbank[%d] new_bank[%d]" , oldbank, self.bank)
	return 1,acturl_cost_money,flag_cost
end

--修改银行钱
function base_player:change_bank(value, opttype, is_savedb, whatever)
	log.info("change_bank  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype)
	local oldbank = self.bank
	local ret = true

	if oldbank + value < 0 then
		log.error("guid [%d] bank money[%d] value[%d]",self.guid ,oldbank ,value)
		value = -oldbank
		ret = false
		if not whatever then
			return false
		end
	end

	local bank_ = self:incrby("bank",value)
	self.bank = bank_
	self:notify_bank_money(opttype,bank_,bank_  - oldbank)
	log.info("opttype--------------".. opttype)
	self:log_money(enum.ITEM_PRICE_TYPE_GOLD,opttype,self.money,self.money,oldbank,self.bank)

	log.info("change_bank  end oldbank[%d] new_bank[%d]" , oldbank, self.bank)
	return ret
end

-- 修改身上钱
function base_player:change_money(value, opttype, is_savedb, whatever)	
	log.info("change_money  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype)
	local oldmoney = self.money
	local ret = true

	if oldmoney + value < 0 then
		log.error("change_money money isn't enough,guid:%s,money:%s,change:%s",self.guid,money,value)
		value = -oldmoney
		ret = false
		if not whatever  then
			return false
		end
	end

	log.info("old money is :"..self.money)
	local money_ = self:incrby("money",value)
	self.money = money_
	log.info("money is :"..self.money)
	self:notify_money(opttype,money_,money_ - oldmoney)
	log.info("opttype--------------".. opttype)
	self:log_money(enum.ITEM_PRICE_TYPE_GOLD,opttype,oldmoney,self.money,self.bank,self.bank)
	log.info("change_money  end oldmoney[%d] new_money[%d]" , oldmoney, self.money)
	return ret
end


--记录游戏对手
function base_player:set_player_ip_contrl(player_list)
	-- body
	log.info("==================set_player_ip_contrl")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	for _,v in ipairs(player_list) do
		if v.guid ~= self.guid then
			set_game_times(gametype,self.guid,v.guid,true)
		end
	end
end

--增加游戏场数
function base_player:inc_play_times()
	-- body
	log.info("==================inc_play_times")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	inc_play_times(gametype,self.guid,true)
end

--判断游戏场次 judge_play_times
function base_player:judge_play_times(other,GameLimitCdTime)
	-- body
	log.info("==================judge_play_times")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	if judge_play_times(gametype,self.guid,other.guid,GameLimitCdTime,true) then
		print(string.format("%d : %d judge_play_times is true",self.guid,other.guid))
		return true
	else
		print(string.format("%d : %d judge_play_times is false",self.guid,other.guid))
		return false
	end
end

--判断游戏IP
function  base_player:judge_ip(player)
	-- body
	local firstip = self:get_ip_net()
	local secondip = player:get_ip_net()
	log.info("[%s] [%s]",firstip,secondip)
	return firstip == secondip
end

function base_player:get_ip_net(player)	
	-- body
	local str = self.ip
	log.info("======%s",str)
	local ipdata = string.split(str,"%d+")
	str = string.format("%s.%s",ipdata[1],ipdata[2])
	return str
end


return base_player