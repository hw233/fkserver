-- 捕鱼房间
local pb = require "pb_files"
local base_room = require "game.lobby.base_room"
local fishing_table = require "game.fishing.fishing_table"
require "game.fishing.config"
local log = require "log"
local json = require "cjson"
require "functions"

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local fishing_room = base_room:new()

-- 初始化房间
function fishing_room:init(conf, chair_count, ready_mode)
	log.info("fishing_room:init,tablecount:%d,chair_count:%d",conf.table_count,chair_count)
	base_room.init(self,conf, chair_count, ready_mode)
	self:update_lua_cfg(conf.game_cfg)
	self.android_players = {}
	self.last_tick_time = os.clock()
end

function fishing_room:update_lua_cfg( room_lua_cfg )
    log.info("fishing_room:update_lua_cfg")

    if not room_lua_cfg then return end

    local cfg = json.decode(room_lua_cfg)

    if not cfg then return end

    if cfg.room_cfg then room_cfg = cfg.room_cfg end

    log.info("room_cfg weight[%d]",room_cfg.weight)

    if cfg.broadcast then  broadcast_cfg = cfg.broadcast end
    
    log.info("broadcast_cfg money[%d] multiple[%d]",broadcast_cfg.money,broadcast_cfg.multiple)

    if cfg.blacklist_cfg then blacklist_cfg = cfg.blacklist_cfg end

    log.info("blacklist_cfg base_weight[%d]",blacklist_cfg.base_weight)

    if cfg.fish_king then
        for k,v in pairs(cfg.fish_king) do 
            if not fish_king[tonumber(k)] then fish_king[tonumber(k)] = v 
            else fish_king[tonumber(k)].probability = v.probability end
        end
    end

    if cfg.fish_sanyuan then  
        for k,v in pairs(cfg.fish_sanyuan) do 
            if not fish_sanyuan[tonumber(k)] then fish_sanyuan[tonumber(k)] = v 
            else fish_sanyuan[tonumber(k)].probability = v.probability end
        end 
    end

    if cfg.fish_sixi then 
        for k,v in pairs(cfg.fish_sixi) do 
            if not fish_sixi[tonumber(k)] then fish_sixi[tonumber(k)] = v 
            else fish_sixi[tonumber(k)].probability = v.probability end
        end 
    end

    if cfg.fish_set then 
        for k,v in pairs(cfg.fish_set) do 
            if not fish_set[tonumber(k)] then fish_set[tonumber(k)] = v 
            else fish_set[tonumber(k)].probability = v.probability end
        end 
    end

	return true
end

-- gm重新更新配置, room_lua_cfg
function fishing_room:gm_update_cfg(rooms, room_lua_cfg)
    self:update_lua_cfg(room_lua_cfg)

	local old_count = #self.room_list_
	for i,v in ipairs(rooms) do
		if i <= old_count then
			print("change----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money,v.game_switch_is_open)
			self.room_list_[i]:gm_update_cfg(self,v.table_count, self.chair_count_, v.money_limit, v.cell_money, v, room_lua_cfg)
			 for j,v in ipairs(self.room_list_[i].table_list_) do
			 	if v and self.room_list_[i].room_cfg ~= nil then
			 		v:load_lua_cfg()
			 	end
			 end
		else
			local r = self:create_room()
			print("Init----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money)
			r:init(self, v.table_count, self.chair_count_, self.ready_mode_, v.money_limit, v.cell_money, v, room_lua_cfg)
			self.room_list_[i] = r
			for j,v in ipairs(self.room_list_[i].table_list_) do
			 	if v and self.room_list_[i].room_cfg ~= nil then
			 		v:load_lua_cfg()
			 	end
			 end
		end
	end
end

function fishing_room:create_table()
	return fishing_table:new()
end

-- 快速坐下
function fishing_room:auto_sit_down(player)
	log.info("test fishing auto sit down .....................")
	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		--第一个人进来，开始游戏
		log.info("sitdown success")
		local tb = base_room.find_table_by_player(self,player)
		if #tb.player_list_ == 1 then
			log.info("start game")
	    	tb.cpp_table:OnEventGameStart()
	    end

		return result_, table_id_, chair_id_
	end
	
	return result_
end

function fishing_room:get_suitable_table(room,player,bool_change_table)
	log.info("fishing_room:get_suitable_table")

	local suitable_player_count = -1
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if suitable_table == nil or (suitable_table ~= nil and suitable_table:get_player_count() < tb:get_player_count()) then
			for k,chair in ipairs(tb:get_player_list()) do
				if (bool_change_table and player.table_id ~= tb.table_id_) or (not bool_change_table) then
					if chair == false and tb:can_enter(player) then
						local tmp_player_count = tb:get_player_count()
						if suitable_player_count < tmp_player_count then
							suitable_player_count = tmp_player_count
							suitable_table = tb
							chair_id = k
							table_id = j
							break
						end
					end
				end
			end
		end
		
		if tb:get_player_count() > 0 then
			--log.warning("table pcount %d, table_id is %d",tb:get_player_count(),j)
		end
	end	
	
	log.info("suitable_table:[%d]",table_id)
	return suitable_table,chair_id,table_id
end

function fishing_room:player_offline(player)
	log.info("fishing_room:player_offline")
	return base_room.player_offline(self,player)
end


--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function fishing_room:check_player_is_in_blacklist( player_guid )
    return self.blacklist_player[player_guid] and self.blacklist_player[player_guid] == true
end

-- 心跳
function fishing_room:tick()
	base_room.tick(self)
	local now_tick = os.clock()
	if now_tick - self.last_tick_time > 0.03 then
		self.last_tick_time = now_tick
		for _,v in pairs(self.android_players) do 
			v:tick() 
		end
	end
end

return fishing_room