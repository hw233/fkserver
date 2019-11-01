local onlineguid = require "netguidopt"
local channel = require "channel"
require "gate.msg.runtime"

local MSG = {}

function MSG.S_ReplyServerConfig(msg)
	log.info("load config complete ltype=%d id=%d\n", msg.type, msg.server_id)
end

function MSG.S_NotifyGameServerStart(msg)
    send_pb("S_RequestUpdateGameServerConfig",{
		game_id = msg.game_id,
	})
end

function MSG.S_ReplyUpdateGameServerConfig(msg)

end

function MSG.S_NotifyLoginServerStart(msg)

end

function MSG.FG_GameServerCfg(msg)
    --发送
	local notify_map = {}
    for _,item in  pairs(game_cfg.pb_cfg) do
        if item.game_id == msg.pb_cfg.game_id then
			local dbcfg = msg.pb_cfg
		end
		
        if online_game[item.game_id] and online_game[item.game_id].is_open then
			if item.platform_id then
				local platforms = string.split(item.platform_id,"\\d+")
				for _,platform_id in pairs(platforms) do
					local platform_id_number = tonumber(platform_id)
					notify_map[platform_id_number] = notify_map[platform_id_number] or {pb_cfg = {}}
					table.insert(notify_map[platform_id_number].pb_cfg,item)
				end
			end
        end
	end
	
	for platform_id,notify in pairs(notify_map) do
		local platform_guid = online_platform_guid[platform_id]
		if platform_guid then
			for guid,guid_c in pairs(platform_guid) do
				channel.publish("client."..tostring(guid),"msg","",notify)
			end
		end
	end
end



function MSG.S_ReviceWarnningAddr(msg)
	warning_addr = msg

	local pt_addr = warning_addr.notice_potato_addr
	local tg_addr = warning_addr.notice_telegram_addr

	if pt_addr and tg_addr then
		log.info("***************notice_warnning warnning ip = [%s] ,warnning port = [%u], pt_url = [%s], tg_url = [%s]*********", 
			ip_, port_, pt_addr, tg_addr)
		local warning_data = string.format("通知: 网关---.配置服 连接成功 ip[%s:%d]",ip_,port_)
	end
end

return MSG