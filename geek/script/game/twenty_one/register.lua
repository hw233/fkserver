require "game.twenty_one.on_twenty_one"


register_dispatcher("CS_Operation",on_cs_operation)
register_dispatcher("CS_Bet",on_cs_bet)
register_dispatcher("SC_PlayerInfos",on_cs_get_player_infos)