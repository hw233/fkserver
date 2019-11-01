require "game.sanshui.on_sanshui"
require "game.sanshui.logic.logic"

register_client_dispatcher("CS_SelectCards",on_cs_selelct_card)
register_client_dispatcher("CS_BiPaiAccomplish",on_cs_bi_pai_accomplish)
register_client_dispatcher("CS_PlayerInfos",on_cs_get_player_infos)