-- 捕鱼房间
local pb = require "pb"
local base_room = require "game.lobby.base_room"
require "game.jc_fishing.fishing_table"
require "game.jc_fishing.config"

local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

fishing_room = class("fishing_room",base_room)

function fishing_room:ctor( ... )
	self.android_players = {}
    self.last_tick_time = os.clock()
end

function fishing_room:update_lua_cfg( room_lua_cfg )
    log.info("fishing_room:update_lua_cfg")

    if not room_lua_cfg then return end

    local cfg = json.decode(room_lua_cfg)

    if not cfg then return end

    if cfg.room_cfg then room_cfg = cfg.room_cfg end

    log.info(string.format("room_cfg weight[%d]",room_cfg.weight))

    if cfg.broadcast then  broadcast_cfg = cfg.broadcast end
    
    log.info(string.format("broadcast_cfg money[%d] multiple[%d]",broadcast_cfg.money,broadcast_cfg.multiple))

    if cfg.blacklist_cfg then blacklist_cfg = cfg.blacklist_cfg end

    log.info(string.format("blacklist_cfg base_weight[%d]",blacklist_cfg.base_weight))

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

-- 初始化房间
function fishing_room:init(tb, chair_count, ready_mode,room_lua_cfg)
	log.info(string.format("fishing_room:init,tablecount:%d,chair_count:%d",tb.table_count,chair_count))
	fishing_room.super.init(self,tb, chair_count, ready_mode,room_lua_cfg)
    self:update_lua_cfg(room_lua_cfg)
end


function fishing_room:create_table()
	return fishing_table:new()
end


-- 快速坐下
function fishing_room:auto_sit_down(player)
	log.info("test fishing auto sit down .....................")
	local result_, table_id_, chair_id_ = fishing_room.super.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		--第一个人进来，开始游戏
		log.info("sitdown success")
		local tb = self.super.find_table_by_player(self,player)
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
			--log.warning(string.format("table pcount %d, table_id is %d",tb:get_player_count(),j))
		end
	end	
	
	--log.warning(string.format("final, room pcount %d,suitable_table table_id is %d, chair_id is %d,player_count is %d",
	--room.cur_player_count_,table_id,chair_id,suitable_table:get_player_count()))
	log.info(string.format("suitable_table:[%d]",table_id))
	return suitable_table,chair_id,table_id
end

function fishing_room:player_offline(player)
	log.info("fishing_room:player_offline")
	return fishing_room.super.player_offline(self,player)
end


--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function fishing_room:check_player_is_in_blacklist( player_guid )
    return self.blacklist_player[player_guid] and self.blacklist_player[player_guid] == true
end

-- 心跳
function fishing_room:tick()
	if os.clock() - self.last_tick_time > 0.03 then
		self.last_tick_time = os.clock()
		self.super.tick(self)
		for _,v in pairs(self.android_players) do v:tick() end
	end
end

