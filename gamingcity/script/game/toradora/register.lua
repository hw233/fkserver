-- 注册斗地主消息

require "game.toradora.on_toradora"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_ToradoraBetting",on_CS_ToradoraBetting)
register_client_dispatcher("CS_ToradoraGetHistory",on_CS_ToradoraGetHistory)
register_client_dispatcher("CS_GetPlayInfo",on_CS_GetPlayInfo)

