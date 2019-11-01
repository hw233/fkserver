local pb = require "pb"
local base_room = require "game.lobby.base_room"
local room = g_room
require "game.lobby.base_player"

local LOG_MONEY_OPT_TYPE_GM = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM")
local LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY")
local def_game_id = def_game_id

require "game.net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb
local send2loginid_pb = send2loginid_pb

function gm_change_money(guid,money,log_type)
    local player = base_players[guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
			return
	end
    player:change_money(money, log_type or LOG_MONEY_OPT_TYPE_GM)

	send2db_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,		
	})
end

function gm_change_bank_money(guid,money,log_type)
    local player = base_players[guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		return
	end
    player:change_bank(money,log_type or LOG_MONEY_OPT_TYPE_GM)

	send2db_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,
	})
end


function gm_change_player_bank(web_id_,login_id_, guid_,banktype_,order_id_,money_)
	-- body
	log.info(string.format("gm_change_player_bank: web_id[%d] login_id[%d] guid[%d] banktype[%d] order_id[%s] money[%d]",web_id_,login_id_, guid_,banktype_,tostring(order_id_),money_))
	local player = base_players[guid_]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d", guid_, def_game_id))
		send2loginid_pb(login_id_, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 122,
	    	guid = guid_,
	    	order_id = order_id_,
	    	cost_money = money_,
	    	acturl_cost_money = 0,
	    	reason = 0
	    	})
		return
	end
	--返回值:retcode,old_bank,new_bank,acturl_cost_money,reason
	local ret = 0
	local acturl_cost_money_ = 0
	local reason_ = 0
	ret,acturl_cost_money_,reason_ = player:cost_player_banker_money(money_,banktype_,true)
	log.info(string.format("ret[%d] acturl_cost_money_[%d] reason_[%d]",ret,acturl_cost_money_,reason_))
	if tonumber(ret) == 1 then --success
		log.info(string.format("gm_change_player_bank: guid[%d] cost money[%d] success",guid_,money_))
	else --failed
		log.error(string.format("gm_change_player_bank: guid[%d] cost money[%d] failed",guid_,money_))	
	end
	send2loginid_pb(login_id_, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = ret,
	    	guid = guid_,
	    	order_id = order_id_,
	    	cost_money = money_,
	    	acturl_cost_money = acturl_cost_money_,
	    	reason = reason_
	    })
	return
end


function gm_change_bank(web_id_, login_id, guid, money, log_type)
	local player = base_players[guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		send2loginid_pb(login_id, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 0,
	    	})
		return
	end

	print ("web_id_, login_id, guid, money, log_type", web_id_, login_id, guid, money, log_type)
    player:change_bank(money, log_type or LOG_MONEY_OPT_TYPE_GM, true)

    send2loginid_pb(login_id, "SL_LuaCmdPlayerResult", {
    	web_id = web_id_,
    	result = 1,
    	})
end

function gm_broadcast_client(json_str)
	print("gm_broadcast_client comming......")
	local msg = {
		update_info = json_str
	}
	base_players:broadcast2client_pb("SC_BrocastClientUpdateInfo", msg)
	print "gm_broadcast_client ok..................."
end

function gm_set_slotma_rate(guid,count)
    local player = base_players[guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		return
	end
    
	print ("old random_count-> is :",player.pb_base_info.slotma_addition)
	player.pb_base_info.slotma_addition = count
	print ("random_count-> is :",player.pb_base_info.slotma_addition)
	player.flag_base_info = true


	send2db_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,
	})
end

function gm_cost_player_money(transfer_id,proxy_guid,player_guid,transfer_type,transfer_money,platform_id,channel_id,promoter_id)
	if transfer_id == nil or proxy_guid == nil or player_guid == nil or transfer_type == nil or transfer_money == nil or platform_id == nil or channel_id == nil or promoter_id == nil then
		return
	end
	local money = tonumber(transfer_money)
	local guid = tonumber(player_guid)
	if money < 0 then
		return
	end
	local player = base_players[guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		return
	end
	if player.room_id then
		local room = room:find_room(player.room_id)
		if room then
			if player.table_id then
				local tb = room:find_table(player.table_id)
				if tb and tb:is_play(player) then
					table.insert(tb.game_end_event,guid)
					player:add_game_end_event(function ()
						if money > player:get_money() then
							money = 0 - player:get_money()
							player:change_money(money,LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY)
							send2db_pb("SD_LogProxyCostPlayerMoney", {
								transfer_id = transfer_id,
								proxy_guid = proxy_guid,
								player_guid = player_guid,
								transfer_type = transfer_type,
								transfer_money = money,
								platform_id = platform_id,
								channel_id = channel_id,
								promoter_id = promoter_id,
							})
						else
							money = 0 - money
							player:change_money(money,LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY)
							send2db_pb("SD_LogProxyCostPlayerMoney", {
								transfer_id = transfer_id,
								proxy_guid = proxy_guid,
								player_guid = player_guid,
								transfer_type = transfer_type,
								transfer_money = money,
								platform_id = platform_id,
								channel_id = channel_id,
								promoter_id = promoter_id,
							})
						end
					end)
					return
				end
			end
		end
	end
	if money > player:get_money() then
		money = 0 - player:get_money()
		player:change_money(money,LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY)
		send2db_pb("SD_LogProxyCostPlayerMoney", {
			transfer_id = transfer_id,
			proxy_guid = proxy_guid,
			player_guid = player_guid,
			transfer_type = transfer_type,
			transfer_money = money,
			platform_id = platform_id,
			channel_id = channel_id,
			promoter_id = promoter_id,
		})
	else
		money = 0 - money
		player:change_money(money,LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY)
		send2db_pb("SD_LogProxyCostPlayerMoney", {
			transfer_id = transfer_id,
			proxy_guid = proxy_guid,
			player_guid = player_guid,
			transfer_type = transfer_type,
			transfer_money = money,
			platform_id = platform_id,
			channel_id = channel_id,
			promoter_id = promoter_id,
		})
	end
end


