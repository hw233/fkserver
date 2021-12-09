require "game.club.on_club"
require "game.club.on_template"

local h = {
	C2S_CLUBLIST_REQ = on_cs_club_list,
	C2S_CREATE_CLUB_REQ = on_cs_club_create,
	C2S_CLUB_DISMISS_REQ = on_cs_club_dismiss,
	C2S_JOIN_CLUB_REQ = on_cs_club_join_req,
	C2S_CLUB_KICK_PLAYER_REQ = on_cs_club_kickout,
	C2S_CLUB_INFO_REQ = on_cs_club_detail_info_req,
	C2S_CLUB_PLAYER_LIST_REQ = on_cs_club_query_memeber,
	C2S_CLUB_OP_REQ = on_cs_club_operation,
	C2S_CLUB_REQUEST_LIST_REQ = on_cs_club_request_list_req,
	C2S_EDIT_CLUB_GAME_TYPE_REQ = on_cs_club_edit_game_type,
	C2S_CREATE_CLUB_WITH_INVITE_MAIL = on_cs_club_create_club_with_mail,
	C2S_INVITE_JOIN_CLUB = on_cs_club_invite_join_club,

	C2S_CLUB_TEAM_LIST_REQ = on_cs_club_team_list,
	C2S_CLUB_TRANSFER_MONEY_REQ = on_cs_transfer_money,

	C2S_CONFIG_CLUB_TEMPLATE_COMMISSION = on_cs_config_club_template_commission,
	C2S_GET_CLUB_TEMPLATE_COMMISSION = on_cs_get_club_template_commission,
	C2S_CONFIG_CLUB_TEAM_TEMPLATE = on_cs_config_club_team_template,
	C2S_GET_CLUB_TEAM_TEMPLATE_CONFIG = on_cs_get_club_team_template_conf,
	C2S_RESET_CLUB_TEMPLATE_COMMISSION = on_cs_reset_club_teamplate_commission,

	C2S_EXCHANGE_CLUB_COMMISSON_REQ = on_cs_exchagne_club_commission,

	C2S_CLUB_MONEY_REQ = on_cs_club_money,

	B2S_CLUB_CREATE = on_bs_club_create,

	C2S_CONFIG_FAST_GAME_LIST = on_cs_config_fast_game_list,

	B2S_CLUB_CREATE_WITH_GROUP = on_bs_club_create_with_group,

	C2S_IMPORT_PLAYER_FROM_GROUP = on_cs_club_import_player_from_group,

	C2S_CLUB_FORCE_DISMISS_TABLE = on_cs_force_dismiss_table,

	C2S_CLUB_BLOCK_PULL_GROUPS = on_cs_pull_block_groups,
	C2S_CLUB_BLOCK_NEW_GROUP = on_cs_new_block_group,
	C2S_CLUB_BLOCK_DEL_GROUP = on_cs_del_block_group,
	C2S_CLUB_BLOCK_ADD_PLAYER_TO_GROUP = on_cs_add_player_to_block_group,
	C2S_CLUB_BLOCK_REMOVE_PLAYER_FROM_GROUP = on_cs_remove_player_from_block_group,

	C2S_CLUB_EDIT_INFO = on_cs_club_edit_info,

	C2S_CLUB_GET_CONFIG = on_cs_club_get_config,
	C2S_CLUB_EDIT_CONFIG = on_cs_club_edit_config,

	C2S_CLUB_INVITE_JOIN_ROOM = on_cs_club_invite_join_room,

	CS_SEARCH_CLUB_PLAYER = on_cs_search_club_player,

	C2S_CLUB_EDIT_TEAM_CONFIG = on_cs_club_edit_team_config,

	B2S_CLUB_DEL = on_bs_club_del,

	B2S_CLUB_DISMISS = on_bs_club_dismiss,

	CS_CLUB_MEMBER_INFO = on_cs_club_member_info,

	CS_CLUB_IMPORT_PLAYER_FROM_TEAM = on_cs_club_import_player_from_team,

	CS_TEAM_STATUS_INFO = on_cs_team_status_info,
	CS_CLUB_TEAM_TEMPLATE_INFO = on_cs_team_template_info,
	CS_CLUB_CHANGE_TEAM_TEMPLATE = on_cs_change_team_template,

	C2S_CLUB_GET_TEAM_PARTNER_CONFIG = on_cs_club_get_team_partner_config,

	C2S_CLUB_EDIT_TEAM_PARTNER_CONFIG = on_cs_club_edit_team_partner_config,

	C2S_CLUB_BLOCK_TEAM_PULL_GROUPS = on_cs_pull_block_team_groups,
	C2S_CLUB_BLOCK_TEAM_NEW_GROUP = on_cs_new_block_team_group,
	C2S_CLUB_BLOCK_TEAM_DEL_GROUP = on_cs_del_block_team_group,
	C2S_CLUB_BLOCK_TEAM_ADD_TEAM_TO_GROUP = on_cs_add_team_to_block_team_group,
	C2S_CLUB_BLOCK_TEAM_REMOVE_TEAM_FROM_GROUP = on_cs_remove_team_from_block_team_group,
}

local msgopt = require "msgopt"
msgopt:reg(h)