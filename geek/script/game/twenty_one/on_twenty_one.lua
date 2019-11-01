
local log = require "log"

local room = g_room

function on_cs_operation(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then
        log.error("on_cs_operation error:not find table [%d] ",player.guid)
        return
    end
    tb:on_operation(player,msg)
end


function on_cs_bet(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then
        log.error("on_cs_bet error:not find table [%d] ",player.guid)
        return
    end
    tb:on_bet(player,msg)
end

function on_cs_get_player_infos(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then
        log.error("on_cs_get_player_infos error:not find table [%d] ",player.guid)
        return
    end
    tb:get_player_infos(player,msg)
end