-- 骰宝测试机器人

local pb = require "pb"

local random = require "random"

require "data.land_data"
local robot_ip_area = robot_ip_area

require "timer"
local add_timer = add_timer

require "game.lobby.base_character"
require "game.lobby.base_player"

--local base_room = require "game.lobby.base_room"
local room = g_room


local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local def_game_id = def_game_id
local inc_play_times = inc_play_times
local judge_play_times = judge_play_times
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type


if not shaibao_android then
	shaibao_android = base_player:new()
end


-- 初始化
function shaibao_android:init(roomid_, guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)

	self.is_android = true
	self.pb_base_info = {}
	self.pb_base_info.money = 1000000
	self.pb_base_info.bank  = 0
	self.platform_id = "0"
	self.channel_id = "test_99"
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
	room = room or g_room
	room:enter_room(self, roomid_)
end


-- 玩家坐下时
function shaibao_android:think_on_sit_down(room_id_, table_id_, chair_id_)
	room = room or g_room

	if self.room_id ~= room_id_ then
		if self.room_id ~= 0 then
			room:exit_room(self)
		end

		room:enter_room(self, room_id_)
	end

	room:sit_down(self, table_id_, chair_id_)
end

-- 检查房间限制
function shaibao_android:check_room_limit(score)
	return false
end

-- 通知站起
function shaibao_android:on_notify_stand_up(notify)
end

function shaibao_android:setStatus(is_onLine)
	self.online = true
end

-- 得到钱
function shaibao_android:get_money()
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.money
end

--得到银行的钱
function shaibao_android:get_bank_money( )
	-- body
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.bank
end

-- 随机头像
function shaibao_android:get_header_icon()
	return self.header_icon
end

--记录游戏对手
function shaibao_android:set_player_ip_control(player_list)
end

--增加游戏场数
function shaibao_android:inc_play_times()
	-- body
	log.info("game_android ==================inc_play_times")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	inc_play_times(gametype,self.guid,true)
end

function shaibao_android:get_ip(player)	
	return self.ip
end

--判断游戏IP
function  shaibao_android:judge_ip(player)
	return false
end

function shaibao_android:on_sit_down(table_id_, chair_id_, result_)
	return GAME_SERVER_RESULT_SUCCESS
end

function shaibao_android:change_table( room_id_, table_id_, chair_id_, result_, tb )
end

--重置显示信息
function shaibao_android:reset_show()
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
end


function shaibao_android:set_table(t)
    self.cur_table = t
end

function shaibao_android:get_table()
    return self.cur_table
end

local BET_XIAO    = pb.enum("SHAIBAO_BET_AREA", "BET_XIAO")
local BET_DA      = pb.enum("SHAIBAO_BET_AREA", "BET_DA")
local BET_ZD_WS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_1")
local BET_ZD_WS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_2")
local BET_ZD_WS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_3")
local BET_ZD_WS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_4")
local BET_ZD_WS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_5")
local BET_ZD_WS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_WS_6")
local BET_RY_WS   = pb.enum("SHAIBAO_BET_AREA", "BET_RY_WS")
local BET_ZD_DS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_1")
local BET_ZD_DS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_2")
local BET_ZD_DS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_3")
local BET_ZD_DS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_4")
local BET_ZD_DS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_5")
local BET_ZD_DS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_DS_6")
local BET_ZD_SS_1 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_1")
local BET_ZD_SS_2 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_2")
local BET_ZD_SS_3 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_3")
local BET_ZD_SS_4 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_4")
local BET_ZD_SS_5 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_5")
local BET_ZD_SS_6 = pb.enum("SHAIBAO_BET_AREA", "BET_ZD_SS_6")
local BET_DH_4    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_4")
local BET_DH_5    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_5")
local BET_DH_6    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_6")
local BET_DH_7    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_7")
local BET_DH_8    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_8")
local BET_DH_9    = pb.enum("SHAIBAO_BET_AREA", "BET_DH_9")
local BET_DH_10   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_10")
local BET_DH_11   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_11")
local BET_DH_12   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_12")
local BET_DH_13   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_13")
local BET_DH_14   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_14")
local BET_DH_15   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_15")
local BET_DH_16   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_16")
local BET_DH_17   = pb.enum("SHAIBAO_BET_AREA", "BET_DH_17")

--主动处理消息
function shaibao_android:dispatch_msg(msgname, msg)
    print("shaibao_android[dispatch_msg] msg",msgname)
    if msgname == "SC_ShaiBaoStart" then
        add_timer(5,function ()
			if self.action_type == 1 then
				for i=BET_ZD_WS_1,BET_ZD_WS_6 do
					local msg = {area = i,money = 10000}
					self:get_table():add_score(self,msg)
				end
				local msg = {area = BET_RY_WS,money = 60000}
				self:get_table():add_score(self,msg) 
			elseif self.action_type == 2 then
				local msg = {area = BET_XIAO,money = self.next_bet}
				self:get_table():add_score(self,msg)
			elseif self.action_type == 3 then
				local msg = {area = BET_DA,money = self.next_bet}
				self:get_table():add_score(self,msg) 
			end
		end)
	elseif msgname == "SC_ShaiBaoEnd" then
		if self.action_type == 2 then
			if msg.money > 0 then
				self:set_next_bet(1000)
			else
				self:set_next_bet(self.next_bet*2)
			end
		elseif self.action_type == 3 then
			if msg.money > 0 then
				self:set_next_bet(2000)
			else
				self:set_next_bet(self.next_bet*2)
			end
		end
    end
end

--设置机器人押注类型
function shaibao_android:set_action(action_type)
	self.pb_base_info.money = 100000000
	self.action_type = action_type
	if self.action_type == 2 then
		self:set_next_bet(1000)
	elseif self.action_type == 3 then
		self:set_next_bet(2000)
	else
		self:set_next_bet(0)
	end
end

--设置下一局下注金额
function shaibao_android:set_next_bet(bet)
	self.next_bet = bet
end