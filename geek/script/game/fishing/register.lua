-- 注册捕鱼消息

require "game.net_func"
require "game.fishing.on_fishing"
require "game.fishing.fishing_android"

require "functions"


local function sz_T2S(_t)
    local szRet = "{"
    local function doT2S(_i, _v)
        if "number" == type(_i) then
            szRet = szRet .. "[" .. _i .. "] = "
            if "number" == type(_v) then
                szRet = szRet .. _v .. ","
            elseif "string" == type(_v) then
                szRet = szRet .. '"' .. _v .. '"' .. ","
            elseif "table" == type(_v) then
                szRet = szRet .. sz_T2S(_v) .. ","
            elseif "boolean" == type(_v) then
                szRet = szRet .. (_v and "true" or "false") .. ","
            else
                szRet = szRet .. "nil,"
            end
        elseif "string" == type(_i) then
            szRet = szRet .. '' .. _i .. ' = '
            if "number" == type(_v) then
                szRet = szRet .. _v .. ","
            elseif "string" == type(_v) then
                szRet = szRet .. '"' .. _v .. '"' .. ","
            elseif "table" == type(_v) then
                szRet = szRet .. sz_T2S(_v) .. ","
            elseif "boolean" == type(_v) then
                szRet = szRet .. (_v and "true" or "false") .. ","
            else
                szRet = szRet .. "nil,"
            end
        end
    end

    for k,v in pairs(_t) do doT2S(k,v) end
    szRet = szRet .. "}"
    return szRet
end


local room = g_room
local game_id = def_game_id

local show_log = not (b_register_dispatcher_hide_log or false)

function on_fishing_msg(player,msg_id,stringbuffer)
    if not player then return end

    local tb = room:find_table_by_player(player)
    if not tb then
        log.warning("table not find,guid[%d] not find in game=%d msg[%d]", player.guid, game_id, msg_id)
        return
    end
end

-- 处理客户端消?
function on_fishing_client_dispatcher(guid, func, msgname, stringbuffer)
	local player = base_players[guid]
	if not player then
		log.warning("guid[%d] not find in game=%d msg[%s]", guid, game_id, msgname)
		return
	end

	local f = _G[func]
	assert(f, string.format("on_client_dispatcher func:%s", func))
    local msg_id =  pb.enum(msgname .. ".MsgID", "ID")

	f(player,msg_id,stringbuffer)
end

function register_fishing_client_dispatcher(msgname)
    local id = pb.enum(msgname .. ".MsgID", "ID")
    assert(id, string.format("msg:%s, func:%s", msgname, func))
    reg_gate_dispatcher(msgname, id, "on_fishing_msg", "on_fishing_client_dispatcher", show_log)
end


--register_fishing_client_dispatcher("CS_TreasureEnd")
-- register_fishing_client_dispatcher("CS_ChangeCannonSet")
-- register_fishing_client_dispatcher("CS_Netcast")
-- register_fishing_client_dispatcher("CS_LockFish")
-- register_fishing_client_dispatcher("CS_LockSpecFish")
-- register_fishing_client_dispatcher("CS_Fire")
-- register_fishing_client_dispatcher("CS_ChangeCannon")
-- register_fishing_client_dispatcher("CS_TimeSync")

--register_dispatcher("CS_TreasureEnd",on_cs_fishing_treasureend)
--register_dispatcher("CS_ChangeCannonSet",on_cs_fishing_changecannonset)
--register_dispatcher("CS_Netcast",on_cs_fishing_netcast)
--register_dispatcher("CS_LockFish",on_cs_fishing_lockfish)
--register_dispatcher("CS_LockSpecFish",on_cs_fishing_lockspecfish)
--register_dispatcher("CS_Fire",on_cs_fishing_fire)
--register_dispatcher("CS_ChangeCannon",on_cs_fishing_changecannon)
--register_dispatcher("CS_TimeSync",on_cs_fishing_timesync)

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

require "game.fishing.logic.mathaide"
-- require "game.fishing.pathmanager"