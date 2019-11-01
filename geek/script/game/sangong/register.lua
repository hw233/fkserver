-- 注册牛牛消息

require "game.sangong.on_sangong"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_sangongEnter",on_cs_sangong_enter)
register_dispatcher("CS_sangongNextGame",on_cs_sangong_reEnter)
register_dispatcher("CS_sangongLeave",on_cs_sangong_leave)
register_dispatcher("CS_sangongContend",on_cs_sangong_contend)
register_dispatcher("CS_sangongPlayerBet",on_cs_sangong_bet)
register_dispatcher("CS_sangongPlayerGuessCards",on_cs_sangong_guess)
register_dispatcher("CS_sangongLastRecord",on_cs_quest_last_record)


