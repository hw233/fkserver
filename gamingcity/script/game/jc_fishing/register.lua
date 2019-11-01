-- 注册捕鱼消息

require "game.net_func"
require "game.jc_fishing.on_fishing"
require "game.jc_fishing.fishing_android"
local pb = require "pb"

require "functions"

local room = g_room
local game_id = def_game_id

local show_log = not (b_register_dispatcher_hide_log or false)


-- 处理客户端消?
function on_fishing_client_dispatcher(guid, msg)
	local player = base_players[guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d msg[%s]", guid, game_id, msgname))
		return
	end

	local f = _G[func]
	assert(f, string.format("on_client_dispatcher func:%s", func))
    local msg_id =  pb.enum(msgname .. ".MsgID", "ID")

	f(player,msg)
end


-- register_client_dispatcher("CS_TreasureEnd",on_cs_fishing_treasureend)
register_client_dispatcher("CS_ChangeCannonSet",on_cs_fishing_changecannonset)
register_client_dispatcher("CS_Netcast",on_cs_fishing_netcast)
register_client_dispatcher("CS_LockFish",on_cs_fishing_lockfish)
register_client_dispatcher("CS_LockSpecFish",on_cs_fishing_lockspecfish)
register_client_dispatcher("CS_Fire",on_cs_fishing_fire)
register_client_dispatcher("CS_ChangeCannon",on_cs_fishing_changecannon)
register_client_dispatcher("CS_TimeSync",on_cs_fishing_timesync)

--[[
function create_androids(count)
    for i = 1,count do
        local player = fishing_android:new()
        player:init(i + 100000, "android", "android")
        player.is_android = true
        player.vip = 0
        player.ip_area = "局域网"
        player.pb_base_info = {money = 99999990000, }
        player.last_fire = os.clock()

        room.android_players[player.guid] = player

        local result_, room_id_, table_id_, chair_id_, tb = room:enter_room_and_sit_down(player)
        player:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
        room:get_table_players_status(player)
        tb:ready(player)
        tb.cpp_table:OnChangeCannon(player.guid,player.chair_id,false)
    end
end

require "timer"
local add_timer = add_timer

add_timer(5*1, function()
	create_androids(10)
end)
--]]
