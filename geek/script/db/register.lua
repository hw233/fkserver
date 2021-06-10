-- 注册消息

local msgopt = require "msgopt"

require "db.msg.on_login_logout"
require "db.msg.on_bank"
require "db.msg.on_chat_mail"
require "db.msg.on_log"
require "db.msg.on_club"
require "db.msg.on_notice"

local h = {
	--------------------------------------------------------------------
	-- 注册Login发过来的消息分派函数
	LD_RegAccount = on_ld_reg_account,
	LD_LogLogin = on_ld_log_login,
	SD_LogLogout = on_sd_log_logout,
	SD_SetNickname = on_sd_set_nickname,
	--------------------------------------------------------------------
	-- 注册Game发过来的消息分派函数
	S_Logout = on_s_logout,
	SD_LogMoney = on_sd_log_money,
	SD_LogGameMoney = on_sd_log_game_money,
	SL_Log_Game = on_sl_log_game,
	SD_LogClubCommission = on_sd_log_club_commission,
	SD_LogClubCommissionContributuion = on_sd_log_club_commission_contribution,

	SD_LogRecharge = on_sd_log_recharge,

	SD_CreateClub = on_sd_create_club,
	SD_DismissClub = on_sd_dismiss_club,
	SD_DelClub = on_sd_del_club,
	SD_JoinClub = on_sd_join_club,
	SD_ExitClub = on_sd_exit_club,
	SD_ChangePlayerMoney = on_sd_change_player_money,
	SD_ChangeClubMoney = on_sd_change_club_money,
	SD_NewMoneyType = on_sd_new_money_type,
	SD_AddClubMember = on_sd_add_club_member,
	SD_CreateClubTemplate = on_sd_create_club_template,
	SD_RemoveClubTemplate = on_sd_remove_club_template,
	SD_EditClubTemplate = on_sd_edit_club_template,
	SD_BatchJoinClub = on_sd_batch_join_club,
	SD_TransferMoney = on_sd_transfer_money,
	SD_BindPhone = on_sd_bind_phone,
	SD_RequestShareParam = on_sd_request_share_param,
	SD_LogPlayerCommission = on_sd_log_player_commission,
	SD_CreatePartner = on_sd_create_partner,
	SD_DismissPartner = on_sd_dismiss_partner,
	SD_JoinPartner = on_sd_join_partner,
	SD_ExitPartner = on_sd_exit_partner,
	SD_LogPlayerCommissionContributes = on_sd_log_player_commission_contributes,
	SD_UpdatePlayerInfo = on_sd_update_player_info,
	SD_LogExtGameRound = on_sd_log_ext_game_round,
	SD_EditClubInfo = on_sd_edit_club_info,
	SD_QueryPlayerStatistics = on_sd_query_player_statistics,
	SD_LogClubActionMsg = on_sd_log_club_action_msg,
	SD_SetClubRole = on_sd_set_club_role,
	SD_AddIntoClubGamingBlacklist = on_sd_add_into_club_gaming_blacklist,
	SD_RemoveFromClubGamingBlacklist = on_sd_remove_from_club_gaming_blacklist,
	SD_AddNotice = on_sd_add_notice,
	SD_EditNotice = on_sd_edit_notice,
	SD_RemoveNotice = on_sd_del_notice,
}

msgopt:reg(h)