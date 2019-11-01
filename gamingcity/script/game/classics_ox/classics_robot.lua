-- 炸金花陪玩机器人

local pb = require "pb"

local random = require "random"

require "data.land_data"
local robot_ip_area = robot_ip_area

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


if not classics_android then
	classics_android = base_player:new()
end


-- 初始化
function classics_android:init(roomid_, guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)

	self.is_android = true
	self.is_player = false
	self.pb_base_info = {}
	self.pb_base_info.money = 1000000
	self.pb_base_info.bank  = 0
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

function classics_android:reset_info()
    -- body
    self.header_icon = math.random(10)
    local ip_index = math.random(#robot_ip_area)
    self.ip_area =  robot_ip_area[ip_index]
end

-- 玩家坐下时
function classics_android:think_on_sit_down(room_id_, table_id_, chair_id_)
	room = room or g_room
    log.info(string.format("think_on_sit_down room_id_ %d , table_id_ %d ,chair_id_  %d ",room_id_, table_id_, chair_id_))
	if self.room_id ~= room_id_ then
		if self.room_id ~= 0 then
			room:exit_room(self)
		end

		room:enter_room(self, room_id_)
	end

	room:sit_down(self, table_id_, chair_id_)
end

-- 检查房间限制
function classics_android:check_room_limit(score)
	return false
end

-- 通知站起
function classics_android:on_notify_stand_up(notify)
end

function classics_android:setStatus(is_onLine)
	self.online = true
end

-- 得到钱
function classics_android:get_money()
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.money
end

--得到银行的钱
function classics_android:get_bank_money( )
	-- body
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.bank
end

-- 随机头像
function classics_android:get_header_icon()
	return self.header_icon
end

--记录游戏对手
function classics_android:set_player_ip_control(player_list)
end

--增加游戏场数
function classics_android:inc_play_times()
	-- body
	log.info("game_android ==================inc_play_times")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	inc_play_times(gametype,self.guid,true)
end

function classics_android:get_ip(player)
	return self.ip
end

--判断游戏IP
function  classics_android:judge_ip(player)
	return false
end

function classics_android:on_sit_down(table_id_, chair_id_, result_)
	return GAME_SERVER_RESULT_SUCCESS
end

function classics_android:change_table( room_id_, table_id_, chair_id_, result_, tb )
end

--重置显示信息
function classics_android:reset_show()
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
end


function classics_android:set_table(t)
    self.cur_table = t
end

function classics_android:get_table()
    return self.cur_table
end

function classics_android:set_maxcards(ismax)
    self.ismax = ismax
end

function classics_android:is_max()
    return self.ismax
end

function classics_android:set_mixcards(ismix)
    self.ismix = ismix
end

function classics_android:is_mix()
    return self.ismix
end

--主动处理消息
function classics_android:dispatch_msg(msgname, msg)
    --log.info(string.format("classics_android[dispatch_msg] msg:%s",msgname))
    if msgname == "SC_ClassicsBeginToContend" then
    	--选择抢桩
        self:get_table():start_contend_timer(random.boost_integer(1,5),self)
    elseif msgname == "SC_ClassicsPlayerBeginToBet" then
    	--选择下注
        self:get_table():start_begin_to_bet_timer(random.boost_integer(1,5),self)
    elseif msgname == "SC_ClassicsShowOwnCards" then
    	--猜牌
        self:get_table():start_guess_cards_timer(random.boost_integer(1,5),self)
    end
end
