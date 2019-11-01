
local room = g_room

function on_cs_bet(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then 
        log.error(string.format("on_cs_bet error:not find table [%d] ",player.guid))
        return 
    end
    tb:on_bet(player,msg)
end

function on_cs_ready_start(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then 
        log.error(string.format("on_cs_ready_start error:not find table [%d] ",player.guid))
        return 
    end
    tb:on_ready_start(player,msg)
end