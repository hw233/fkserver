-- 捕鱼消息处理

local pb = require "pb"
require "game.net_func"
require "game.lobby.base_player"
require "game.fishing.config"



local room = g_room

local global_storage = 0

send2client_pb_str = function(player_or_guid, msgid, msg_str)
    local player = player_or_guid
	if type(player) ~= "table" then
		player = base_players[player_or_guid]
		if not player then
			log.warning("game[send2client_pb] not find player:" .. player_or_guid)
			return
		end
	end

	if not player.is_player then
		log.info("----player is robot,send2client_pb return")
		return
	end

	if not player.online then
		log.info(string.format("game[send2client_pb] offline, guid:%d  msgid:%d",player.guid,msgid))
		return
	end

	if player.is_android then
        pb.decode(msgid,msg_str)
		player:on_msg_str(msgid,msg_str)
		return
	end

	send2client(player.guid, player.gate_id, msgid, msg_str)
end

send2client_pb = function(player_or_guid, msgname, msg)
	local player = player_or_guid
	if type(player) ~= "table" then
		player = base_players[player_or_guid]
		if not player then
			log.warning(string.format("game[send2client_pb] not find player:[%d],return",player_or_guid))
			return
		end
	end

	if not player.is_player then
		player:dispatch_msg(msgname,msg)
		return
	end

	if not player.online then
		log.info(string.format("game[send2client_pb] offline, guid:%d  msg:%s",player.guid,msgname))
		return
	end

    if player.is_android then
		player:on_msg(msgname,msg)
		return
	end

	local id = pb.enum(msgname .. ".MsgID", "ID")
    if id == 0 then
        log_warn("invalid message id") 
        return 
    end
	
	local stringbuffer = ""
	if msg then stringbuffer = pb.encode(msgname, msg) end

	send2client(player.guid, player.gate_id, id, stringbuffer)
end

-- 发送客户端消息
function broadcast2client_pb(room_id,table_id,msgname,msg)
	local room = room:find_room(room_id)
	if not room then
		return
	end

	local tb = room:find_table(table_id)
	if not tb then
		return
	end

	tb:broadcast2client(msgname,msg)
end

function on_catch_fish(catch_info)

end

local last_print_time = os.clock()

function update_player_fire_log(guid,multiple,cost)
    global_storage = global_storage + cost
    if os.clock() - last_print_time >= 3 then
        log.info(string.format("======current storage:%d   ",global_storage))
        last_print_time = os.clock()
    end

    for k,v in pairs(room.android_players) do
        if k == guid then return end
    end

	local player = base_players[guid]	
	if not player then
		log.error(string.format("update_player_fire_log guid[%d] not find in game" ,guid))
		return
	end

    local tb = room:find_table_by_player(player)
	if not tb then
		log.error(string.format("update_player_fire_log tableID[%d] not find in game" , player.table_id))
		return
	end

	tb:add_fire_log(player,multiple,cost)
end

function subtract_player_fire_log(guid,multiple,cost)
--    print(string.format("subtract_player_fire_log guid[%d] mul[%d] cost[%d]",guid,multiple,cost))
    global_storage = global_storage - cost
    if os.clock() - last_print_time >= 3 then
        log.info(string.format("======current storage:%d   ",global_storage))
        last_print_time = os.clock()
    end

        for k,v in pairs(room.android_players) do
        if k == guid then return end
    end

	local player = base_players[guid]	
	if not player then
		log.error(string.format("update_player_fire_log guid[%d] not find in game" ,guid))
		return
	end

    local tb = room:find_table_by_player(player)
	if not tb then
		log.error(string.format("update_player_fire_log tableID[%d] not find in game" , player.table_id))
		return
	end

	tb:subtract_fire_log(player,multiple,cost)
end


function update_player_hit_log(guid,fish_type,connon_score)
    for k,v in pairs(room.android_players) do
        if k == guid then return end
    end

	local player = base_players[guid]	
	if not player then
		log.error(string.format("[update_player_catch_log] guid[%d] not find in game" ,guid))
		return
	end

    local tb = room:find_table_by_player(player)
	if not tb then
		log.error(string.format("[update_player_catch_log] tableID[%d] not find in game" , player.table_id))
		return
	end

	tb:add_hit_log(player,fish_type,connon_score)
end

function update_player_catch_log(guid,fish_type,multi,money)
    global_storage = global_storage - money
    if os.clock() - last_print_time >= 3 then
        log.info(string.format("======current storage:%d   ",global_storage))
        last_print_time = os.clock()
    end

    for k,v in pairs(room.android_players) do
        if k == guid then return end
    end

	local player = base_players[guid]	
	if not player then
		log.error(string.format("[update_player_catch_log] guid[%d] not find in game" ,guid))
		return
	end

    local tb = room:find_table_by_player(player)
	if not tb then
		log.error(string.format("[update_player_catch_log] tableID[%d] not find in game" , player.table_id))
		return
	end

	tb:add_catch_log(player,fish_type,multi,money)
end


-- 回存
function write_player_money(guid,change_money)
    if change_money == 0 then return end

	local player = base_players[guid]	
	if not player then
		log.error(string.format("[write_player_money] guid[%d] not find in game",guid))
		return
	end

    local tb = room:find_table_by_player(player)
	if not tb then
		log.error(string.format("[write_player_money] tableID[%d] not find in game" , player.table_id))
		return
	end

	tb:change_player_money(player,change_money)
end

function get_fish_weight(fish_level_type,fish_type)
--    print(string.format("get_fish_weight fish_type[%d],fish_type_id[%d]",fish_level_type,fish_type))
    if fish_level_type < 0 or fish_level_type >= special_fish_type.ESFT_MAX then return 0 end

    if fish_level_type == special_fish_type.ESFT_NORMAL then return fish_set[fish_type].probability end
    if fish_level_type == special_fish_type.ESFT_KINGANDQUAN or 
        fish_level_type == special_fish_type.ESFT_KING then return  fish_king[fish_type].probability end
    if fish_level_type == special_fish_type.ESFT_SANYUAN then return fish_sanyuan[fish_type].probability end
    if fish_level_type == special_fish_type.ESFT_SIXI then return fish_sixi[fish_type].probability end
    return 0
end

function get_room_weight()
--    print(string.format("get_room_weight weight[%d]",room_cfg.weight))
    return room_cfg.weight
end

function get_player_weight(guid)
--    print(string.format("get_player_weight guid[%d],global weight[%d],max_win_weight[%d]",guid,blacklist_cfg.global_weight,blacklist_cfg.max_win_weight))
    local blacklist_player_weight = 0
    if room:check_player_is_in_blacklist(guid)  then 
        blacklist_player_weight = blacklist_cfg.base_weight
    end

    return blacklist_player_weight
end

--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
-- 打开宝箱
function on_cs_fishing_treasureend(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:CSTreasureEnd()
	else
		log.error(string.format("guid[%d] treasureend", player.guid))
	end
end

-- 改变大炮集
function on_cs_fishing_changecannonset(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnChangeCannonSet(player,msg.add)
	else
		log.error(string.format("guid[%d] changecannonset", player.guid))
	end
end

-- 网鱼
function on_cs_fishing_netcast(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnNetCast(player,msg.bullet_id,msg.data,msg.fish_id)
	else
		log.error(string.format("guid[%d] netcast", player.guid))
	end
end

-- 锁定鱼
function on_cs_fishing_lockfish(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnLockFish(player,msg.lock)
	else
		log.error(string.format("guid[%d] lockfish", player.guid))
	end
end

--锁定指定鱼
function on_cs_fishing_lockspecfish(player,msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnLockSpecFish(player,msg.fish_id)
	else
		log.error(string.format("guid[%d] lockspecfish", player.guid))
	end
end

-- 开火
function on_cs_fishing_fire(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnFire(player,msg)
	else
		log.error(string.format("guid[%d] fire", player.guid))
	end
end

-- 变换大炮
function on_cs_fishing_changecannon(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnChangeCannon(player,msg.add)
	else
		log.error(string.format("guid[%d] changecannon", player.guid))
	end
end

-- 获取系统时间
function on_cs_fishing_timesync(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb.cpp_table:OnTimeSync(player,msg.client_tick)
	else
		log.error(string.format("guid[%d] timesync", player.guid))
	end
end
