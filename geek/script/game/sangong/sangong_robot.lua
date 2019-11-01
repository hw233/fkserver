-- 炸金花陪玩机器人

local pb = require "pb_files"

local random = require "random"

require "data.land_data"
local robot_ip_area = robot_ip_area

require "game.lobby.base_character"
require "game.lobby.base_player"

--local base_room = require "game.lobby.base_room"
local room = g_room


local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")


if not banker_android then
	banker_android = base_player:new()
end


-- 初始化
function banker_android:init(roomid_, guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)

	self.is_android = true
	self.is_player = false
	self.money = 1000000
	self.bank  = 0
	self.platform_id = "0"
	self.channel_id = "test_99"
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
    self.ismax = false
    self.ismix = false
	room = room or g_room
	room:enter_room(self, roomid_)
end


-- 玩家坐下时
function banker_android:think_on_sit_down(room_id_, table_id_, chair_id_)
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
function banker_android:check_room_limit(score)
	return false
end

-- 通知站起
function banker_android:on_notify_stand_up(notify)
end

function banker_android:setStatus(is_onLine)
	self.online = true
end

-- 得到钱
function banker_android:get_money()
	return self.money or 0
end

--得到银行的钱
function banker_android:get_bank_money( )
	return self.bank or 0
end

-- 随机头像
function banker_android:get_header_icon()
	return self.header_icon
end

--记录游戏对手
function banker_android:set_player_ip_control(player_list)
end

--增加游戏场数
function banker_android:inc_play_times()
	-- body
	log.info("game_android ==================inc_play_times")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	inc_play_times(gametype,self.guid,true)
end

function banker_android:get_ip(player)	
	return self.ip
end

--判断游戏IP
function  banker_android:judge_ip(player)
	return false
end

function banker_android:on_sit_down(table_id_, chair_id_, result_)
	return GAME_SERVER_RESULT_SUCCESS
end

function banker_android:change_table( room_id_, table_id_, chair_id_, result_, tb )
end

--重置显示信息
function banker_android:reset_show()
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
end


function banker_android:set_table(t)
    self.cur_table = t
end

function banker_android:get_table()
    return self.cur_table
end

function banker_android:set_maxcards(ismax)
    self.ismax = ismax
end

function banker_android:is_max()
    return self.ismax
end

function banker_android:set_mixcards(ismix)
    self.ismix = ismix
end

function banker_android:is_mix()
    return self.ismix
end

--主动处理消息
function banker_android:dispatch_msg(msgname, msg)
    --log.info("banker_android[dispatch_msg] msg:%s",msgname)
    if msgname == "SC_BankerBeginToContend" then
    	--选择抢桩
        self:get_table():start_contend_timer(random.boost_integer(1,5),self)
    elseif msgname == "SC_BankerPlayerBeginToBet" then
    	--选择下注
        self:get_table():start_begin_to_bet_timer(random.boost_integer(1,5),self)
    elseif msgname == "SC_BankerShowOwnCards" then
    	--猜牌
        self:get_table():start_guess_cards_timer(random.boost_integer(1,5),self)        
    end
end
