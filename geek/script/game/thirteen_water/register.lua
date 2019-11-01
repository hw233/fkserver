-- 注册13水消息

require "game.thirteen_water.on_thirteen"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_Player_SetCards",on_cs_player_set_cards)
