-- 炸金花陪玩机器人

local pb = require "pb_files"

local random = require("random")
local log = require "log"
require "data.land_data"
local robot_ip_area = robot_ip_area

local base_character = require "game.lobby.base_character"
local base_player = require "game.lobby.base_player"

--local base_room = require "game.lobby.base_room"
local room = g_room


local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

if not zhj_android then
	zhj_android = base_player:new()
end

-- 初始化
function zhj_android:init(guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)

	self.is_android = true
	self.money = 1000000
	self.bank  = 0
	self.platform_id = "0"
	self.channel_id = "test_99"
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
    self.ismax = false
	room = room or g_room
	room:enter_room(self)
end


-- 玩家坐下时
function zhj_android:think_on_sit_down(table_id_, chair_id_)
	room = room or g_room

	room:sit_down(self, table_id_, chair_id_)
end

-- 检查房间限制
function zhj_android:check_room_limit(score)
	return false
end

-- 通知站起
function zhj_android:on_notify_stand_up(notify)
end

function zhj_android:setStatus(is_onLine)
	self.online = true
end

-- 得到钱
function zhj_android:get_money()
	return self.money or 0
end

--得到银行的钱
function zhj_android:get_bank_money( )
	return self.bank or 0
end

-- 随机头像
function zhj_android:get_header_icon()
	return self.header_icon
end

--记录游戏对手
function zhj_android:set_player_ip_control(player_list)
end

--增加游戏场数
function zhj_android:inc_play_times()
	log.info("game_android ==================inc_play_times")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	inc_play_times(gametype,self.guid,true)
end

function zhj_android:get_ip(player)	
	return self.ip
end

--判断游戏IP
function  zhj_android:judge_ip(player)
	return false
end

function zhj_android:on_sit_down(table_id_, chair_id_, result_)
	return GAME_SERVER_RESULT_SUCCESS
end

function zhj_android:change_table( room_id_, table_id_, chair_id_, result_, tb )
end

--重置显示信息
function zhj_android:reset_show()
    self.header_icon = math.random(10)
	local ip_index = math.random(#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
end


function zhj_android:set_table(t)
    self.cur_table = t
end

function zhj_android:get_table()
    return self.cur_table
end

function zhj_android:set_maxcards(ismax)
    self.ismax = ismax
end

function zhj_android:is_max()
    return self.ismax
end

--主动处理消息
function zhj_android:dispatch_msg(msgname, msg)
    --log.info("zhj_android[dispatch_msg] msg:%s",msgname)
    if msgname == "SC_ZhaJinHuaStart" then
        if msg.banker_chair_id == self.chair_id then
            self:get_table():start_add_score_timer(random.boost_integer(2,5),self)
        end
    elseif msgname == "SC_ZhaJinHuaAddScore" then
        if msg.cur_chair_id == self.chair_id then
            self:get_table():start_add_score_timer(random.boost_integer(2,5),self)
        end
    elseif msgname == "SC_ZhaJinHuaGiveUp" then
        if msg.cur_chair_id == self.chair_id then
            self:get_table():start_add_score_timer(random.boost_integer(2,5),self)
        end
    elseif msgname == "SC_ZhaJinHuaCompareCard" then
        if msg.cur_chair_id == self.chair_id then
            self:get_table():start_add_score_timer(random.boost_integer(8,11),self)
        end
	elseif msgname == "SC_ZhaJinHuaAllComCards" then
        if msg.cur_chair_id == self.chair_id then
            self:get_table():start_add_score_timer(random.boost_integer(8,11),self)
        end
    end
end
