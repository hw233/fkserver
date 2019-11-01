-- 房间基类

local pb = require "pb"
local log = require "log"
require "game.net_func"
local send2client_pb = send2client_pb

local base_prize_pool = require "game.lobby.base_prize_pool"
local base_table = require "game.lobby.base_table"

require "table_func"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")

-- enum GAME_READY_MODE
-- local GAME_READY_MODE_NONE = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_NONE")
-- local GAME_READY_MODE_ALL = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_ALL")
-- local GAME_READY_MODE_PART = pb.enum("GAME_READY_MODE", "GAME_READY_MODE_PART")
local redisopt = require "redisopt"

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query
local redis_cmd_do = redis_cmd_do
local get_second_time = get_second_time

base_room = {}


-- 创建
function base_room  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 奖池
global_prize_pool = global_prize_pool or base_prize_pool:new()

-- 初始化
function base_room:init(room, table_count, chair_count, ready_mode, room_limit, cell_money, roomconfig, room_lua_cfg)
	self.tax_show_ = roomconfig.tax_show -- 是否显示税收信息
	self.tax_open_ = roomconfig.tax_open -- 是否开启税收
	self.tax_ = roomconfig.tax * 0.01
	self.roomConfig = roomconfig
	self.room_manager_ = room
	self.ready_mode_ = ready_mode -- 准备模式
	self.room_limit_ = room_limit or 0 -- 房间分限制
	self.cell_score_ = cell_money or 0 -- 底注
	self.player_count_limit_ = table_count * chair_count -- 房间人数总限制
	self.table_list_ = {}
	self.configid_ = 0
	self.room_cfg = room_lua_cfg
	self.game_switch_is_open = roomconfig.game_switch_is_open
	log.info(string.format("base_room:init:self.game_switch_is_open = [%d]~~~~~~~~~~~~~~~~~:",self.game_switch_is_open))

	if global_prize_pool then
		print("================1  "..type(global_prize_pool))
		dump(global_prize_pool)
		if global_prize_pool.load_lua_cfg then
			print("================2")
		end
	end
	global_prize_pool:load_lua_cfg(self.id, room_lua_cfg)

	for i = 1, table_count do
		local t = room:create_table()
		--room, table_id, chair_count
		t:init(self, i, chair_count)
		if self.room_cfg ~= nil then
			t:load_lua_cfg()
		end
		self.table_list_[i] = t
	end
	self.room_player_list_ = {}
	self.cur_player_count_ = 0 -- 当前玩家人数


	local str = string.format("del %s_%d_%d",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)

	str = string.format("del %s_%d_%d_player_num",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)

	str = string.format("del %s_%d_%d_player_count",def_game_name,def_first_game_type,def_second_game_type)
	log.info(str)
	redis_command(str)
end



-- gm重新更新配置
function base_room:gm_update_cfg(room,table_count, chair_count, room_limit, cell_money, roomconfig, room_lua_cfg)
	self.room_limit_ = room_limit or 0 -- 房间分限制
	self.cell_score_ = cell_money or 0 -- 底注
	self.tax_show_ = roomconfig.tax_show -- 是否显示税收信息
	self.tax_open_ = roomconfig.tax_open -- 是否开启税收
	self.tax_ = roomconfig.tax * 0.01
	self.roomConfig = roomconfig	
	self.player_count_limit_ = table_count * chair_count -- 房间人数总限制
	self.configid_ = self.configid_ + 1
	self.room_cfg = room_lua_cfg
	self.game_switch_is_open = roomconfig.game_switch_is_open
	log.info(string.format("gm_update_cfg:self.game_switch_is_open = [%d]~~~~~~~~~~~~~~~~~:",self.game_switch_is_open))

	global_prize_pool:load_lua_cfg(self.id, room_lua_cfg)
	
	--游戏维护中通知玩家
	if self.game_switch_is_open == 1 then

		for i,tb in ipairs(self.table_list_) do

			if not tb:is_play() then
				tb:foreach(function (p)
					if p.vip ~= 100 then
						send2client_pb(p, "SC_GameMaintain", {
						result = GAME_SERVER_RESULT_MAINTAIN,
						})
					end
					
				end)
			end
		end

	end
end

-- 找到桌子
function base_room:find_table(table_id)
	if not table_id then
		return nil
	end
	return self.table_list_[table_id]
end

-- 通过玩家找桌子
function base_room:find_table_by_player(player)
	if not player.table_id then
		log.warning(string.format("guid[%d] not find in table", player.guid))
		return nil
	end

	local tb = self:find_table(player.table_id)
	if not tb then
		log.warning(string.format("table_id[%d] not find in table", player.table_id))
		return nil
	end

	return tb
end

function base_room:get_room_cell_money()
	return self.cell_score_
end

function base_room:get_room_tax()
	-- body
	return self.tax_
end
-- 得到准备模式
function base_room:get_ready_mode()
	return self.ready_mode_
end

-- 得到房间分限制
function base_room:get_room_limit()
	return self.room_limit_
end

-- 找到房间中玩家
function base_room:find_player_list()
	return self.room_player_list_
end

-- 得到玩家
function base_room:get_player(chair_id)
	return self.room_player_list_[chair_id]
end

-- 得到桌子列表
function base_room:get_table_list()
	return self.table_list_
end

-- 遍历房间所有玩家
function base_room:foreach_by_player(func)
	for _, p in pairs(self.room_player_list_) do
		func(p)
	end
end

-- 广播房间中所有人消息
function base_room:broadcast2client_by_player(msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for _, p in pairs(self.room_player_list_) do
		send2client_pb_str(p, id, msg)
	end
end

-- 遍历所有桌子
function base_room:foreach_by_table(func)
	for _, t in pairs(self.table_list_) do
		func(t)
	end
end

function base_room:get_player_num( ... )
	-- body
	local num = 0
	for _,v in pairs(self.room_player_list_) do
		if v then
			num = num + 1
		end
	end
	return num
end


function base_room:update_game_player_count()
	--redis_command(string.format("HSET game_server_online_count %d %d", def_game_id, self.player_count))
	log.info(string.format("=======================================game_id[%d] def_first_game_type[%d]  def_second_game_type[%d]  update_game_player_count[%d]  " ,def_game_id,def_first_game_type,def_second_game_type,self.cur_player_count_))
	broadcast_player_count(self.cur_player_count_ )
end

-- 玩家进入房间
function base_room:player_enter_room(player, room_id_)
	player.in_game = true
	log.info(string.format("set player[%d] in_game true this room have player count is [%d] [%d]" ,player.guid , self.cur_player_count_ , self:get_player_num()))
	player.room_id = room_id_
	self.room_player_list_[player.guid] = player
	self.cur_player_count_ = self.cur_player_count_ + 1
	local str = string.format("incr %s_%d_%d",def_game_name,def_first_game_type,def_second_game_type)	
	log.info(string.format("%s guid[%d]",str,player.guid))
	redis_command(str)

	str = string.format("set %s_%d_%d_%d_player_num %d",def_game_name,def_game_id,def_first_game_type,def_second_game_type,self:get_player_num())
	log.info(string.format("%s guid[%d]",str,player.guid))
	redis_command(str)

	str = string.format("set %s_%d_%d_%d_player_count %d",def_game_name,def_game_id,def_first_game_type,def_second_game_type,self.cur_player_count_)
	log.info(string.format("%s guid[%d]",str,player.guid))
	redis_command(str)

	log.info(string.format("GameInOutLog,base_room:player_enter_room, guid %s, room_id %s",
	tostring(player.guid),tostring(player.room_id)))


	redis_cmd_query(string.format("HGET player:online %d", player.guid), function (reply)
		if type(reply) == "string" then
			local data = reply
			local dataTab = string.split(data,":")
			local str = string.format("HSET player_guid_online %d %s:%s:%d:%d:%s:%s",player.guid, dataTab[1], dataTab[2], def_first_game_type, def_second_game_type, dataTab[5], dataTab[6])
			log.info(str)
			redis_command(str)
		end
	end)
	self:update_game_player_count()
end

-- 玩家退出房间
function base_room:player_exit_room(player,is_logout)
	log.info(string.format("GameInOutLog,base_room:player_exit_room, guid %s, room_id %s",
	tostring(player.guid),tostring(player.room_id)))
	
	print("base_room:player_exit_room")
	local room_id_ = player.room_id
	player.room_id = nil
	self.room_player_list_[player.guid] = false
	self.cur_player_count_ = self.cur_player_count_ - 1

	local str = string.format("decr %s_%d_%d",def_game_name,def_first_game_type,def_second_game_type)
	log.info(string.format("%s guid[%d]",str,player.guid))
	redis_command(str)

	str = string.format("set %s_%d_%d_%d_player_num %d",def_game_name,def_game_id,def_first_game_type,def_second_game_type,self:get_player_num())
	log.info(string.format("%s guid[%d]",str,player.guid))
	redis_command(str)

	str = string.format("set %s_%d_%d_%d_player_count %d",def_game_name,def_game_id,def_first_game_type,def_second_game_type,self.cur_player_count_)
	log.info(string.format("%s guid[%d]",str,player.guid))
	redis_command(str)

	if not is_logout then
		log.info(string.format("player_exit_room set guid[%d] onlineinfo",player.guid))

		redis_cmd_query(string.format("HGET player_guid_online %d", player.guid), function (reply)
			if type(reply) == "string" then
				local data = reply
				local dataTab = self:lua_string_split(data,":")
				if dataTab[1] then
					local str = string.format("HSET player_guid_online %d %s:%s:%d:%d:%s:%s",player.guid, dataTab[1], dataTab[2], 0, 0, dataTab[5],dataTab[6])
					log.info(str)
					redis_command(str)
				else
					log.error(string.format("base_room:player_exit_room guid[%d] data[%s]",player.guid,data))
				end
			end
		end)
	else
		log.info(string.format("player_exit_room not set guid[%d] onlineinfo",player.guid))
	end
	
	player:on_exit_room(room_id_, 0)
	self:update_game_player_count()
end



function base_room:lua_string_split(str, split_char)      
    local sub_str_tab = {}
   
    while (true) do
        local pos = string.find(str, split_char)  
        if (not pos) then
        	-- print('*******:'..str)
            table.insert(sub_str_tab,str)  
            break
        end  
    
        local sub_str = string.sub(str, 1, pos - 1)
        -- print('*******:'..sub_str)
        table.insert(sub_str_tab,sub_str)
        local t = string.len(str)
        str = string.sub(str, pos + 1, t)
        -- print('--------:'..str)
    end
    return sub_str_tab
end