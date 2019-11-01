
local room = g_room

function on_cs_selelct_card(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then return end
    tb:selected_cards(player,msg)
end

function on_cs_bi_pai_accomplish(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then 
        print("on_cs_bi_pai_accomplish",player.guid)
        return 
    end
    tb:bi_pai_accomplish(player,msg)
end

function on_cs_get_player_infos(player,msg)
    local tb = room:find_table_by_player(player)
    if not tb then return end
    tb:cs_get_player_infos(player,msg)
end