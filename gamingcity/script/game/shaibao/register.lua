-- 注册骰宝消息

require "game.shaibao.on_shaibao"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_ShaiBaoBet",on_CS_ShaiBaoBet)  
register_client_dispatcher("CS_ShaiBaoInit",on_CS_ShaiBaoInit)  
