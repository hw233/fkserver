-- 游戏机器人
require "data.land_data"
require "functions"
local enum = require "pb_enums"
local robot_ip_area = robot_ip_area

local base_character = require "game.lobby.base_character"

local room = g_room

local game_android = base_character:new()

-- 初始化
function game_android:init(roomid_, guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)
	self.money = 10000
	self.bank  = 0
	self.header_icon = math.random(10)

	self.platform_id = "0"
	self.channel_id = "game_@_android_&_player_#_channel"
	self.ip = ""
	self.ip_area =  table.choice(robot_ip_area)

	room = room or g_room
	room:enter_room(self, roomid_)
end


-- 玩家坐下时
function game_android:think_on_sit_down(room_id_, table_id_, chair_id_)
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
function game_android:check_money_limit(score)
	return false
end

-- 通知站起
function game_android:on_notify_stand_up(notify)
end

function game_android:setStatus(is_onLine)
	self.online = true
end

-- 得到钱
function game_android:get_money()
	return self.money or 0
end

--得到银行的钱
function game_android:get_bank_money()
	return self.bank
end

-- 随机头像
function game_android:get_header_icon()
	return self.header_icon
end

--记录游戏对手
function game_android:set_player_ip_control(player_list)
end

--增加游戏场数
function game_android:inc_play_times()
	--log.info("game_android ==================inc_play_times")
	--local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	--inc_play_times(gametype,self.guid,true)
end

function game_android:get_ip(player)
	return self.ip
end

--判断游戏IP
function  game_android:judge_ip(player)
	return false
end

function game_android:on_sit_down(table_id_, chair_id_, result_)
	return enum.GAME_SERVER_RESULT_SUCCESS
end

function game_android:change_table( room_id_, table_id_, chair_id_, result_, tb )
end

function game_android:cost_money(price, opttype, bRet)
	local money = self.money

	for _, p in ipairs(price) do
		p.money = math.ceil(p.money)
		if p.money_type == enum.ITEM_PRICE_TYPE_GOLD then
			if p.money <= 0 then
				return false
			end
			money = money - p.money
		end
	end

	if money < 0 then
		return false
	end

	self.money = money
	
	return true
end

function game_android:add_money(price, opttype)
	local money = self.money

	for _, p in ipairs(price) do
		if p.money_type == enum.ITEM_PRICE_TYPE_GOLD then
			if p.money <= 0 then
				return false
			end
			money = money + p.money
		end
	end

	self.money = money
	
	return true
end

return game_android