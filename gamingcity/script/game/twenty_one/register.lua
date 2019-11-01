require "game.twenty_one.on_twenty_one"


register_client_dispatcher("CS_Operation",on_cs_operation)
register_client_dispatcher("CS_Bet",on_cs_bet)
register_client_dispatcher("SC_PlayerInfos",on_cs_get_player_infos)