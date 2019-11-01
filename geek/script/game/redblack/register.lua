-- 注册红黑消息

require "game.redblack.on_redblack"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_RedblackBet",on_CS_RedblackBet)  
register_dispatcher("CS_RedblackInit",on_CS_RedblackInit)  
