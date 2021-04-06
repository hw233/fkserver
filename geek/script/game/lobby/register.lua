-- 注册消息
require "game.lobby.on_login_logout"
require "game.lobby.on_bank"
require "game.lobby.on_item"
require "game.lobby.on_room"
require "game.lobby.on_chat"
require "game.club.on_club"
require "game.lobby.on_template"

--------------------------------------------------------------------
register_dispatcher("CG_GameServerCfg",on_cs_game_server_cfg)
register_dispatcher("CS_GameServerCfg",on_cs_game_server_cfg)

-- 注册Login发过来的消息分派函数
register_dispatcher("LS_LoginNotify",on_ls_login_notify)
register_dispatcher("S_Logout",on_s_logout)
register_dispatcher("SS_ChangeGame",on_ss_change_game)
register_dispatcher("SS_ChangeTo",on_ss_change_to)

--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函?
register_dispatcher("CS_RequestPlayerInfo",on_cs_request_player_info)
register_dispatcher("CS_LoginValidatebox",on_cs_login_validatebox)
register_dispatcher("CS_ChangeGame",on_cs_change_game)
register_dispatcher("CS_JoinRoom",on_cs_join_private_room)
register_dispatcher("CS_CreateRoom",on_cs_create_private_room)
register_dispatcher("CS_SetNickname",on_cs_set_nickname)
register_dispatcher("CS_ChangeHeaderIcon",on_cs_change_header_icon)
register_dispatcher("CS_BankSetPassword",on_cs_bank_set_password)
register_dispatcher("CS_BankChangePassword",on_cs_bank_change_password)
register_dispatcher("CS_BankLogin",on_cs_bank_login)
register_dispatcher("CS_BankDeposit",on_cs_bank_deposit)
register_dispatcher("CS_BankDraw",on_cs_bank_draw)
register_dispatcher("CS_BuyItem",on_cs_buy_item)
register_dispatcher("CS_DelItem",on_cs_del_item)
register_dispatcher("CS_UseItem",on_cs_use_item)
register_dispatcher("CS_EnterRoom",on_cs_enter_room)
register_dispatcher("CS_AutoEnterRoom",on_cs_auto_enter_room)
register_dispatcher("CS_AutoSitDown",on_cs_auto_sit_down)
register_dispatcher("CS_SitDown",on_cs_sit_down)
register_dispatcher("CS_StandUp",on_cs_stand_up)
register_dispatcher("CS_EnterRoomAndSitDown",on_cs_enter_room_and_sit_down)
register_dispatcher("CS_StandUpAndExitRoom",on_cs_stand_up_and_exit_room)
register_dispatcher("CS_ChangeChair",on_cs_change_chair)
register_dispatcher("CS_Ready",on_cs_ready)
register_dispatcher("CS_ChatWorld",on_cs_chat_world)
register_dispatcher("CS_ChatPrivate",on_cs_chat_private)
register_dispatcher("SC_ChatPrivate",on_sc_chat_private)
register_dispatcher("CS_ChatServer",on_cs_chat_server)
register_dispatcher("CS_ChatRoom",on_cs_chat_room)
register_dispatcher("CS_ChatTable",on_cs_chat_table)
register_dispatcher("CS_ChangeTable",on_cs_change_table)
register_dispatcher("CS_Exit",on_cs_exit)
register_dispatcher("CS_Trustee",on_cs_trusteeship)
register_dispatcher("CL_ResetBankPW",on_cl_ResetBankPW)

-- register_dispatcher("SS_JoinPrivateRoom",on_SS_JoinPrivateRoom)

register_dispatcher("CS_DismissTableReq",on_cs_dismiss_table_req)
register_dispatcher("CS_DismissTableCommit",on_cs_dismiss_table_commit)

register_dispatcher("GetTableStatusInfo",on_s_get_table_status_info)
register_dispatcher("C2S_EDIT_TABLE_TEMPLATE",on_cs_edit_table_template)
register_dispatcher("CS_UpdateLocation",on_cs_update_location_gps)

register_dispatcher("C2SPlayerInteraction",on_cs_player_interaction)

register_dispatcher("CS_RequestBindPhone",on_cs_bind_account)
register_dispatcher("CS_RequestSmsVerifyCode",on_cs_request_sms_verify_code)

register_dispatcher("CS_RequestBindWx",on_cs_request_bind_wx)

register_dispatcher("CS_PERSONAL_ID_BIND",on_cs_personal_id_bind)

register_dispatcher("CS_SearchPlayer",on_cs_search_player)

register_dispatcher("CS_PlayOnceAgain",on_cs_play_once_again)

register_dispatcher("CS_Logout",on_cs_logout)

register_dispatcher("CS_ForceKickoutPlayer",on_cs_force_kickout_player)

register_dispatcher("C2S_VoiceInteractive",on_cs_voice_interactive)

register_dispatcher("BS_Recharge",on_bs_recharge)

register_dispatcher("BS_BindPhone",on_bs_bind_phone)