-- 注册消息

local msgopt = require "msgopt"

require "db.msg.on_login_logout"
require "db.msg.on_bank"
require "db.msg.on_chat_mail"
require "db.msg.on_log"
require "db.msg.on_club"
require "db.msg.on_notice"

local register_dispatcher = msgopt.register

--------------------------------------------------------------------
-- 注册Login发过来的消息分派函数
register_dispatcher("LD_RegAccount",on_ld_reg_account)
register_dispatcher("LD_LogLogin",on_ld_log_login)
register_dispatcher("SD_LogLogout",on_sd_log_logout)
register_dispatcher("SD_SetNickname",on_sd_set_nickname)
--------------------------------------------------------------------
-- 注册Game发过来的消息分派函数
register_dispatcher("S_Logout",on_s_logout)
register_dispatcher("SD_LogMoney",on_sd_log_money)
register_dispatcher("SD_LogGameMoney",on_sd_log_game_money)
register_dispatcher("SL_Log_Game",on_sl_log_game)
register_dispatcher("SD_LogClubCommission",on_sd_log_club_commission)
register_dispatcher("SD_LogClubCommissionContributuion",on_sd_log_club_commission_contribution)

register_dispatcher("SD_LogRecharge",on_sd_log_recharge)

register_dispatcher("SD_CreateClub",on_sd_create_club)
register_dispatcher("SD_DismissClub",on_sd_dismiss_club)
register_dispatcher("SD_DelClub",on_sd_del_club)
register_dispatcher("SD_JoinClub",on_sd_join_club)
register_dispatcher("SD_ExitClub",on_sd_exit_club)
register_dispatcher("SD_ChangePlayerMoney",on_sd_change_player_money)
register_dispatcher("SD_ChangeClubMoney",on_sd_change_club_money)
register_dispatcher("SD_NewMoneyType",on_sd_new_money_type)
register_dispatcher("SD_AddClubMember",on_sd_add_club_member)
register_dispatcher("SD_CreateClubTemplate",on_sd_create_club_template)
register_dispatcher("SD_RemoveClubTemplate",on_sd_remove_club_template)
register_dispatcher("SD_EditClubTemplate",on_sd_edit_club_template)
register_dispatcher("SD_BatchJoinClub",on_sd_batch_join_club)
register_dispatcher("SD_TransferMoney",on_sd_transfer_money)
register_dispatcher("SD_BindPhone",on_sd_bind_phone)
register_dispatcher("SD_RequestShareParam",on_sd_request_share_param)
register_dispatcher("SD_LogPlayerCommission",on_sd_log_player_commission)
register_dispatcher("SD_CreatePartner",on_sd_create_partner)
register_dispatcher("SD_DismissPartner",on_sd_dismiss_partner)
register_dispatcher("SD_JoinPartner",on_sd_join_partner)
register_dispatcher("SD_ExitPartner",on_sd_exit_partner)
register_dispatcher("SD_LogPlayerCommissionContributes",on_sd_log_player_commission_contributes)
register_dispatcher("SD_UpdatePlayerInfo",on_sd_update_player_info)
register_dispatcher("SD_LogExtGameRound",on_sd_log_ext_game_round)
register_dispatcher("SD_EditClubInfo",on_sd_edit_club_info)
register_dispatcher("SD_QueryPlayerStatistics",on_sd_query_player_statistics)
register_dispatcher("SD_LogClubActionMsg",on_sd_log_club_action_msg)
register_dispatcher("SD_SetClubRole",on_sd_set_club_role)
register_dispatcher("SD_AddIntoClubGamingBlacklist",on_sd_add_into_club_gaming_blacklist)
register_dispatcher("SD_RemoveFromClubGamingBlacklist",on_sd_remove_from_club_gaming_blacklist)
register_dispatcher("SD_AddNotice",on_sd_add_notice)
register_dispatcher("SD_EditNotice",on_sd_edit_notice)
register_dispatcher("SD_RemoveNotice",on_sd_del_notice)
