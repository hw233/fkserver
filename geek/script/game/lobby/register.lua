-- 注册消息
require "game.lobby.on_login_logout"
require "game.lobby.on_bank"
require "game.lobby.on_item"
require "game.lobby.on_room"
require "game.lobby.on_chat"
require "game.club.on_club"
require "game.lobby.on_template"

local msgopt = require "msgopt"

local h = {
	CG_GameServerCfg = on_cs_game_server_cfg,
	CS_GameServerCfg = on_cs_game_server_cfg,

	LS_LoginNotify = on_ls_login_notify,
	S_Logout = on_s_logout,
	SS_ChangeGame = on_ss_change_game,
	SS_ChangeTo = on_ss_change_to,

	CS_RequestPlayerInfo = on_cs_request_player_info,
	-- CS_LoginValidatebox = on_cs_login_validatebox,
	-- CS_ChangeGame = on_cs_change_game,
	CS_JoinRoom = on_cs_join_private_room,
	CS_ReconnectJoinRoom = on_cs_reconnect_join_room,
	CS_CreateRoom = on_cs_create_private_room,
	CS_SetNickname = on_cs_set_nickname,
	CS_ChangeHeaderIcon = on_cs_change_header_icon,
	-- CS_BankSetPassword = on_cs_bank_set_password,
	-- CS_BankChangePassword = on_cs_bank_change_password,
	-- CS_BankLogin = on_cs_bank_login,
	-- CS_BankDeposit = on_cs_bank_deposit,
	-- CS_BankDraw = on_cs_bank_draw,
	-- CS_BuyItem = on_cs_buy_item,
	-- CS_DelItem = on_cs_del_item,
	-- CS_UseItem = on_cs_use_item,
	-- CS_EnterRoom = on_cs_enter_room,
	-- CS_AutoEnterRoom = on_cs_auto_enter_room,
	-- CS_AutoSitDown = on_cs_auto_sit_down,
	-- CS_SitDown = on_cs_sit_down,
	-- CS_StandUp = on_cs_stand_up,
	-- CS_EnterRoomAndSitDown = on_cs_enter_room_and_sit_down,
	CS_StandUpAndExitRoom = on_cs_stand_up_and_exit_room,
	-- CS_ChangeChair = on_cs_change_chair,
	CS_Ready = on_cs_ready,
	-- CS_ChatWorld = on_cs_chat_world,
	-- CS_ChatPrivate = on_cs_chat_private,
	-- CS_ChatServer = on_cs_chat_server,
	-- CS_ChatRoom = on_cs_chat_room,
	-- CS_ChatTable = on_cs_chat_table,
	-- CS_ChangeTable = on_cs_change_table,
	-- CS_Exit = on_cs_exit,
	CS_Trustee = on_cs_trusteeship,
	-- CL_ResetBankPW = on_cl_ResetBankPW,

	CS_DismissTableReq = on_cs_dismiss_table_req,
	CS_DismissTableCommit = on_cs_dismiss_table_commit,

	GetTableStatusInfos = on_s_get_table_status_infos,
	C2S_EDIT_TABLE_TEMPLATE = on_cs_edit_table_template,
	CS_UpdateLocation = on_cs_update_location_gps,

	C2SPlayerInteraction = on_cs_player_interaction,

	CS_RequestBindPhone = on_cs_bind_account,
	CS_RequestSmsVerifyCode = on_cs_request_sms_verify_code,

	CS_RequestBindWx = on_cs_request_bind_wx,

	CS_PERSONAL_ID_BIND = on_cs_personal_id_bind,

	CS_SearchPlayer = on_cs_search_player,

	CS_PlayOnceAgain = on_cs_play_once_again,

	CS_Logout = on_cs_logout,

	CS_ForceKickoutPlayer = on_cs_force_kickout_player,

	C2S_VoiceInteractive = on_cs_voice_interactive,

	BS_Recharge = on_bs_recharge,

	BS_BindPhone = on_bs_bind_phone,

	CS_FastJoinRoom = on_cs_fast_join_room,
	SS_FastJoinRoom = on_ss_fast_join_room,
	SS_FastCreateRoom = on_ss_fast_create_room,
}

msgopt:reg(h)