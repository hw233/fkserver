-- 注册消息
local skynet = require "skynet"
local pb = require "pb"
local msgopt = require "msgopt"
local netmsgopt = require "netmsgopt"
require "functions"



local def_game_id = def_game_id
local def_game_name = def_game_name

function query_many_ox_config_data()
	send2db_pb("SD_QueryOxConfigData", {
		cur_time = get_second_time(),
	})
end

function on_gm_update_cfg()
	local tb = get_game_cfg(def_game_id)
	g_room:gm_update_cfg(tb)
end

skynet.start(function()
	require "table_func"

	require "game.lobby.base_player"
	require "game.lobby.on_login_logout"
	require "game.lobby.on_bank"
	require "game.lobby.on_item"
	require "game.lobby.on_award"
	require "game.lobby.on_room"
	require "game.lobby.on_chat"
	require "game.lobby.on_mail"
	require "game.lobby.on_bonus"
	require "game.lobby.on_recharge_cash"


	local show_log = not (b_register_dispatcher_hide_log or false)

	register_db_dispatcher = msgopt.register
	register_login_dispatcher = msgopt.register
	register_cfg_dispatcher = msgopt.register
	register_gate_dispatcher = msgopt.register
	register_client_dispatcher = netmsgopt.register

	-- local register_client_dispatcher = register_client_dispatcher
	b_register_dispatcher_hide_log = true


	--------------------------------------------------------------------

	-- 注册cfg发过来的消息分派函数
	register_cfg_dispatcher("FS_ChangeGameCfg",on_fs_chang_config)
	register_cfg_dispatcher("CS_QueryMaintain",on_cs_change_maintain)
	register_cfg_dispatcher("S_ReplyPrivateRoomConfig",on_S_ReplyPrivateRoomConfig)
	register_cfg_dispatcher("SS_JoinPrivateRoom",on_SS_JoinPrivateRoom)
	-- 注册DB发过来的消息分派函数
	register_db_dispatcher("DS_LoadPlayerData",on_ds_load_player_data)
	register_db_dispatcher("DS_Charge_Rate",on_ds_charge_rate)
	register_db_dispatcher("DS_Player_Append_Info",on_ds_player_append_info)
	register_db_dispatcher("DS_ResetAccount",on_ds_reset_account)
	register_db_dispatcher("DS_SetPassword",on_ds_set_password)
	register_db_dispatcher("DS_SetNickname",on_ds_set_nickname)
	register_db_dispatcher("DS_BankChangePassword",on_ds_bank_change_password)
	register_db_dispatcher("DS_ResetPW",on_ds_ResetPw)
	register_db_dispatcher("DS_BankLogin",on_ds_bank_login)
	register_db_dispatcher("DS_BankTransfer",on_ds_bank_transfer)
	register_db_dispatcher("DS_BankTransferByGuid",on_ds_bank_transfer_by_guid)
	register_db_dispatcher("DS_SaveBankStatement",on_ds_save_bank_statement)
	register_db_dispatcher("DS_BankStatement",on_ds_bank_statement)
	register_db_dispatcher("DES_SendMail",on_des_send_mail)
	register_db_dispatcher("DS_LoadAndroidData",on_ds_load_android_data)
	register_db_dispatcher("DS_QueryPlayerMsgData",on_ds_QueryPlayerMsgData)
	register_db_dispatcher("DS_QueryPlayerMarquee",on_ds_QueryPlayerMarquee)
	register_db_dispatcher("DS_CashMoneyType",on_ds_cash_money_type)
	register_db_dispatcher("DS_CashMoney",on_ds_cash_money)
	-- 代理提现
	register_db_dispatcher("DS_ProxyCashToBank",on_ds_proxy_cash_money_to_bank)

	register_db_dispatcher("DS_WithDrawCash",on_DS_WithDrawCash)
	register_db_dispatcher("DS_BandAlipay",on_ds_bandalipay)
	register_db_dispatcher("DS_BandAlipayNum",on_ds_bandalipaynum)
	--register_db_dispatcher("DS_OxConfigData",on_ds_LoadOxConfigData)
	register_db_dispatcher("DS_ServerConfig",on_ds_server_config)
	register_db_dispatcher("DS_QueryPlayerInviteReward",on_ds_load_player_invite_reward)
	register_db_dispatcher("DS_QueryChannelInviteCfg",on_ds_load_channel_invite_cfg)
	register_db_dispatcher("DS_CheckCashTime",on_SD_CheckCashTime)
	register_db_dispatcher("DS_NotifyClientBankerChange",on_ds_notifyclientbankchange)
	register_db_dispatcher("DS_ChangeBank",on_ds_changebank)
	register_db_dispatcher("DS_CheckBankTransferEnable",on_DS_CheckBankTransferEnable)
	register_db_dispatcher("DS_PlayerBankTransfer",on_DS_PlayerBankTransfer)
	register_db_dispatcher("DS_BandBankcard",on_ds_bandbankcard)
	register_db_dispatcher("DS_BandBankcardNum",on_ds_bandbankcardnum)
	register_db_dispatcher("DS_Get_Instructor_Weixin",on_ds_instructor_weixin)
	--红包
	register_db_dispatcher("DS_RepPlayerBonusGameStatistics",on_ds_query_game_statistics)
	register_db_dispatcher("DS_RepBonusActivity",on_ds_query_bonus_activities)
	register_db_dispatcher("DS_RepPlayerBonusInfo",on_ds_query_player_bonuses)
	register_db_dispatcher("DS_RepPickPlayerBonusResult",on_ds_pick_bonus)
	register_db_dispatcher("DS_PlayerCurrentBonusLimitInfo",on_ds_load_current_bonus_activity_limit_info)


	--------------------------------------------------------------------
	-- 注册Login发过来的消息分派函数
	register_login_dispatcher("LS_LoginNotify",on_ls_login_notify)
	register_login_dispatcher("S_Logout",on_s_logout)
	register_login_dispatcher("LS_Player_Identiy",on_ls_player_identiy)
	register_login_dispatcher("LS_Update_Risk",on_update_risk)
	register_login_dispatcher("LS_Player_SeniorPromoter",on_ls_player_seniorpromoter)
	register_login_dispatcher("SS_ChangeGame",on_ss_change_game)
	register_login_dispatcher("LS_ChangeGameResult",on_LS_ChangeGameResult)
	register_login_dispatcher("LS_BankTransferSelf",on_ls_bank_transfer_self)
	register_login_dispatcher("LS_BankTransferTarget",on_ls_bank_transfer_target)
	register_login_dispatcher("LS_BankTransferByGuid",on_ls_bank_transfer_by_guid)
	register_login_dispatcher("LS_LoginNotifyAgain",on_ls_login_notify_again)
	register_login_dispatcher("LS_NewNotice",on_new_nitice)
	register_login_dispatcher("LS_GameNotice",on_game_notice)
	register_login_dispatcher("LS_DelMessage",on_ls_DelMessage)
	register_login_dispatcher("LS_CashDeal",on_cash_false_deal)
	register_login_dispatcher("LS_ChangeTax",on_ls_set_tax)
	register_login_dispatcher("LS_AlipayEdit",on_ls_AlipayEdit)
	register_login_dispatcher("LS_CC_ChangeMoney",on_ls_cc_changemoney)
	register_login_dispatcher("LS_FreezeAccount",on_ls_FreezeAccount)
	register_login_dispatcher("LS_AddMoney",on_ls_addmoney)
	register_login_dispatcher("LS_UpdatePlatformSwitch",on_cs_change_recharge_switch)
	--register_login_dispatcher("LS_UpdatePlatformCashSwitch",on_cs_change_cash_switch)
	--register_login_dispatcher("LS_UpdatePlatformPlayerToAgentCashSwitch",on_cs_change_playertoagent_cash_switch)
	--register_login_dispatcher("LS_UpdatePlatformBankerTransferSwitch",on_cs_change_banker_transfer_switch)
	register_login_dispatcher("LS_BankcardEdit",on_ls_BankcardEdit)
	--register_login_dispatcher("LS_UpdatePlatformAllSwitchInfo",on_ls_update_platform_switch_info)
	register_login_dispatcher("LS_UpdatePlatformAllCashSwitch",on_cs_change_all_cash_switch)
	register_login_dispatcher("LS_UpdateBonusHongbao",on_ls_load_bonus_config)

	--------------------------------------------------------------------
	-- 注册客户端发过来的消息分派函?
	register_client_dispatcher("CS_RequestPlayerInfo",on_cs_request_player_info)
	register_client_dispatcher("CS_LoginValidatebox",on_cs_login_validatebox)
	register_client_dispatcher("CS_ChangeGame",on_cs_change_game)
	register_client_dispatcher("CS_JoinPrivateRoom",on_CS_JoinPrivateRoom)
	register_client_dispatcher("CS_PrivateRoomInfo",on_CS_PrivateRoomInfo)
	register_client_dispatcher("CS_ResetAccount",on_cs_reset_account)
	register_client_dispatcher("CS_SetPassword",on_cs_set_password)
	register_client_dispatcher("CS_SetPasswordBySms",on_cs_set_password_by_sms)
	register_client_dispatcher("CS_SetNickname",on_cs_set_nickname)
	register_client_dispatcher("CS_ChangeHeaderIcon",on_cs_change_header_icon)
	register_client_dispatcher("CS_BankSetPassword",on_cs_bank_set_password)
	register_client_dispatcher("CS_BankChangePassword",on_cs_bank_change_password)
	register_client_dispatcher("CS_BankLogin",on_cs_bank_login)
	register_client_dispatcher("CS_BankDeposit",on_cs_bank_deposit)
	register_client_dispatcher("CS_BankDraw",on_cs_bank_draw)
	register_client_dispatcher("CS_BankTransfer",on_cs_bank_transfer)
	register_client_dispatcher("CS_CheckBankTransferEnable",on_CS_CheckBankTransferEnable)
	register_client_dispatcher("CS_BankTransferByGuid",on_cs_bank_transfer_by_guid)
	register_client_dispatcher("CS_BankStatement",on_cs_bank_statement)
	register_client_dispatcher("CS_BuyItem",on_cs_buy_item)
	register_client_dispatcher("CS_DelItem",on_cs_del_item)
	register_client_dispatcher("CS_UseItem",on_cs_use_item)
	register_client_dispatcher("CS_SendMail",on_cs_send_mail)
	register_client_dispatcher("CS_DelMail",on_cs_del_mail)
	register_client_dispatcher("CS_ReceiveMailAttachment",on_cs_receive_mail_attachment)
	register_client_dispatcher("CS_ReceiveRewardLogin",on_cs_receive_reward_login)
	register_client_dispatcher("CS_ReceiveRewardOnline",on_cs_receive_reward_online)
	register_client_dispatcher("CS_ReceiveReliefPayment",on_cs_receive_relief_payment)
	register_client_dispatcher("CS_EnterRoom",on_cs_enter_room)
	register_client_dispatcher("CS_AutoEnterRoom",on_cs_auto_enter_room)
	register_client_dispatcher("CS_AutoSitDown",on_cs_auto_sit_down)
	register_client_dispatcher("CS_SitDown",on_cs_sit_down)
	register_client_dispatcher("CS_StandUp",on_cs_stand_up)
	register_client_dispatcher("CS_EnterRoomAndSitDown",on_cs_enter_room_and_sit_down)
	register_client_dispatcher("CS_StandUpAndExitRoom",on_cs_stand_up_and_exit_room)
	register_client_dispatcher("CS_ChangeChair",on_cs_change_chair)
	register_client_dispatcher("CS_Ready",on_cs_ready)
	register_client_dispatcher("CS_ChatWorld",on_cs_chat_world)
	register_client_dispatcher("CS_ChatPrivate",on_cs_chat_private)
	register_client_dispatcher("SC_ChatPrivate",on_sc_chat_private)
	register_client_dispatcher("CS_ChatServer",on_cs_chat_server)
	register_client_dispatcher("CS_ChatRoom",on_cs_chat_room)
	register_client_dispatcher("CS_ChatTable",on_cs_chat_table)
	register_client_dispatcher("CS_ChangeTable",on_cs_change_table)
	register_client_dispatcher("CS_Exit",on_cs_exit)
	register_client_dispatcher("CS_ReconnectionPlay",on_cs_reconnection_play_msg)
	register_client_dispatcher("CS_QueryPlayerMsgData",on_cs_QueryPlayerMsgData)
	register_client_dispatcher("CS_QueryPlayerMarquee",on_cs_QueryPlayerMarquee)
	register_client_dispatcher("CS_SetMsgReadFlag",on_cs_SetMsgReadFlag)
	register_client_dispatcher("CS_CashMoney",on_cs_cash_money)
	register_client_dispatcher("CS_ProxyCashMoneyToBank",on_cs_proxy_cash_money_to_bank)
	register_client_dispatcher("CS_CashMoneyType",on_cs_cash_money_type)
	register_client_dispatcher("CS_BandAlipay",on_cs_bandalipay)
	register_client_dispatcher("cs_trusteeship",on_cs_Trusteeship)
	register_client_dispatcher("CL_ResetBankPW",on_cl_ResetBankPW)
	register_client_dispatcher("CS_RequestProxyConfig",on_CS_RequestProxyConfig)
	register_client_dispatcher("CS_BandBankcard",on_cs_bandbankcard)
	register_client_dispatcher("CS_Get_Instructor_Weixin",on_cs_instructor_weixin)
	--红包
	register_client_dispatcher("CS_QueryBonusActivity",on_cs_query_bonus_activities)
	register_client_dispatcher("CS_QueryBonus",on_cs_query_bonus)
	register_client_dispatcher("CS_PickBonus",on_cs_pick_bonus)


	register_client_dispatcher("")


	register_gate_dispatcher("FS_ChangMoneyDeal",on_changmoney_deal)
	register_gate_dispatcher("GS_UpdatePlayerBank",on_GS_UpdatePlayerBank)
	register_gate_dispatcher("GS_ReCharge",on_gs_recharge)
	-- register_gate_dispatcher("SS_JoinPrivateRoom",on_SS_JoinPrivateRoom)
	-- register_gate_dispatcher("LS_CC_ChangeMoney",on_ls_cc_changemoney)
	register_gate_dispatcher("LG_UpdateBankMoney",on_lg_updatebankmoney)



	local tb_reg_msg_dispatcher = {
		demo = function ()
			require "game.demo.register"
		end,
		shuihu_zhuan = function()
			require "game.shuihu_zhuan.register"
		end,
		land = function ()
			require "game.land.register"
		end,
		zhajinhua = function ()
			require "game.zhajinhua.register"
		end,
		showhand = function ()
			require "game.showhand.register"
		end,
		ox = function ()
			require "game.ox.register"
		end,

		texas = function ()
			require "game.texas.register"
		end,

		banker_ox = function ()
			require "game.banker_ox.register"
		end,

		sangong = function ()
			require "game.sangong.register"
		end,

		slotma = function ()
			require "game.slotma.register"
		end,

		maajan = function ()
			require "game.maajan.register"
		end,

		classics_ox = function ()
			require "game.classics_ox.register"
		end,

		thirteen_warter = function ()
			require "game.thirteen_water.register"
		end,

		fishing = function()
			require "game.fishing.register"
		end,

		jc_fishing = function()
			require "game.jc_fishing.register"
		end,

		twenty_one = function()
			require "game.twenty_one.register"
		end,

		sanshui = function()
			require "game.sanshui.register"
		end,

		multi_showhand = function()
			require "game.multi_showhand.register"
		end,

		redblack = function()
			require "game.redblack.register"
		end,

		bigtwo = function()
			require "game.bigtwo.register"
		end,

		shaibao = function()
			require "game.shaibao.register"
		end,

		fivestar = function()
			require "game.five_star.register"
		end,

		toradora = function()
			require "game.toradora.register"
		end,

		shelongmen = function()
			require "game.shelongmen.register"
		end,
	}

	local f = tb_reg_msg_dispatcher[def_game_name]
	if f then
		f()
	end
end)