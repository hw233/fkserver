-- game player

local pb = require "pb_files"
require "functions"
local base_character = require "game.lobby.base_character"
require "game.lobby.base_android"
local player_money = require "game.lobby.player_money"
local log  = require "log"
local enum = require "pb_enums"
local json = require "cjson"
local onlineguid = require "netguidopt"
local util = require "util"
require "data.item_details_table"
local club_money_type = require "game.club.club_money_type"
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
function base_player:check_money_limit(score,money_id)
	return self:get_money(money_id) < score
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
			room_id = def_game_id,
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
function base_player:notify_sit_down(player,reconnect,private_table)
	log.info("notify_sit_down  player guid[%d] ip_area =%s",player.guid , player.ip_area)
	
	local seat = {
		chair_id = player.chair_id,
		player_info = {
			guid = player.guid,
			icon = player.icon,
			nickname = player.nickname,
			sex = player.sex,
		},
		longitude = player.gps_longitude,
		latitude = player.gps_latitude,
	}
	if private_table then
		local club_id = private_table.club_id
		local money_id = club_id and club_money_type[club_id] or -1
		seat.money = {{
			money_id = money_id,
			count = player:get_money(money_id),
		}}
	end
	
	send2client_pb(self, "SC_NotifySitDown", {
		table_id = player.table_id,
		seat = seat,
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
	-- 	channel.publish("db.?","msg","SD_SavePlayerData", {
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
function base_player:get_money(money_id)
	return player_money[self.guid][money_id or 0] or 0
end

--得到银行的钱
function base_player:get_bank_money( )
	return self.bank or 0
end

-- 得到头像
function base_player:get_header_icon()
	return self.header_icon
end


function base_player:log_money(money_id,old,now,why,why_ext,where)
	channel.publish("db.?","msg","SD_LogMoney", {
		guid = self.guid,
		money_id = money_id,
		old_money = old,
		new_money = now,
		where = where,
		reason = why,
		reason_ext = why_ext,
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

function base_player:incr_redis_money(money_id,money)
	local newmoney = reddb:hincrby(string.format("player:money:%d",self.guid),money_id,math.floor(money))
	self:notify_money(money_id)
	return newmoney
end

function base_player:incr_money(item,why,why_ext)
	if not why then
		log.error("base_player:incr_money [%d] why can not be nil.",self.guid)
		return
	end

	log.dump(item)
	local where = item.where or 0
	local oldmoney = player_money[self.guid][item.money_id]
	log.info("base_player:incr_money guid[%d] money_id[%d]  money[%d]" ,self.guid, item.money_id, item.money)
	log.info("base_player:incr_money money[%d] + p[%d]" , oldmoney,item.money)

	local changes = channel.call("db.?","msg","SD_ChangePlayerMoney",{{
		guid = self.guid,
		money = math.floor(item.money),
		money_id = item.money_id,
		where = where,
	}},why)

	if table.nums(changes) == 0 or table.nums(changes[1]) == 0 then
		log.error("db incrmoney error,guid[%d] money_id[%d] oldmoney[%d]",self.guid,item.money_id,oldmoney)
		-- return
	end
	
	local dboldmoney = changes[1].oldmoney
	local dbnewmoney = changes[1].newmoney
	
	if dboldmoney ~= oldmoney then
		log.error("db incrmoney error,guid[%s] money_id[%s] oldmoney[%s] dboldmoney[%s]",self.guid,item.money_id,oldmoney,dboldmoney)
		-- return
	end

	local newmoney
	if not self:is_android() then
		newmoney = reddb:hincrby(string.format("player:money:%d",self.guid),item.money_id,math.floor(item.money))
		if dbnewmoney ~= newmoney then
			log.error("db incrmoney error,guid[%s] money_id[%s] newmoney[%s] dbnewmoney[%s]",self.guid,item.money_id,newmoney,dbnewmoney)
			-- return
		end
	end
	
	log.info("base_player:incr_money  end oldmoney[%d] new_money[%d]" , oldmoney, newmoney)
	self:notify_money(item.money_id)
	self:log_money(item.money_id,oldmoney,newmoney,why,why_ext)
	return oldmoney,newmoney
end

-- 花钱
function base_player:cost_money(price, why,why_ext)
	for _, item in ipairs(price) do
		log.info("guid[%d] money_id[%d]  money[%d] why[%d] why_ext[%s]" ,self.guid, item.money_id, item.money,why,why_ext)
		if item.money < 0 then 
			log.error("cost_money but got minus money values.")
			return
		end

		item.money_id = item.money_id or 0
		item.where = item.where or 0
		item.money = - item.money
		local oldmoney,_ = self:incr_money(item,why,why_ext)
		if not oldmoney then
			return
		end
	end

	return true
end

--通知客户端金钱变化
function base_player:notify_money(money_id)
	money_id = money_id or 0
	onlineguid.send(self.guid,"SYNC_OBJECT",util.format_sync_info(
		"PLAYER",{
			guid = self.guid,
			money_id = money_id,
		},{
			money = player_money[self.guid][money_id] or 0
		}
	))
end

-- 加钱
function base_player:add_money(price,why,why_ext)
	for _, item in ipairs(price) do
		log.info("guid[%d] add money[%d],money_type:%d",self.guid , p.money,p.money_type)
		if item.money < 0 then 
			log.error("add_money but got minus money value.")
			return
		end

		item.money_id = item.money_id or 0
		item.where = item.where or 0
		local oldmoney,_ = self:incr_money(item,why,why_ext)
		if not oldmoney then return end
	end

	return true
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
		channel.publish("db.?","msg","SD_UpdateEarnings", {
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
	self:notify_money()
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