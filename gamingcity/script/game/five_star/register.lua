-- 注册斗地主消息

require "game.five_star.on_fivestar"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_FiveStarBetting",on_CS_FiveStarBetting)
register_client_dispatcher("CS_FiveStarGetHistory",on_CS_FiveStarGetHistory)
register_client_dispatcher("CS_GetPlayInfo",on_CS_GetPlayInfo)
register_client_dispatcher("CS_GetBigWinListHistory",on_CS_GetBigWinListHistory)

