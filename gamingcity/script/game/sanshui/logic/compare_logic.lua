--比牌流程
-- all_cards = {{chairId = xx,cards = {}}}
function logic:compare_process( all_cards)
    local bipaiResult = {}
    --将玩家牌型分类 普通/特殊
    local normal_cards = {}
    local special_cards = {}
    for _,playerCards in ipairs(all_cards) do
        if #playerCards.cards == 3 then
            table.insert(normal_cards,playerCards)
        elseif #playerCards.cards == 1 then
            table.insert(special_cards,playerCards)
        end
    end
    --排序
    local function normal_sort( players,index,sort_players )
        table.sort(players,function (player1,player2 )
            local compareResult = self:compare(player1.cards[index],player2.cards[index])
            return compareResult < 0
        end)
        sort_players[index] = {}
        for _,playerInfo in ipairs(players) do
            table.insert(sort_players[index],playerInfo)
        end
    end

        --计算比牌过程中的得分情况
        -- count_score = {
            -- player1 = { --选手
            --     1 = --轮次
            --     {
            --        player2 = {win = 0 ,extra = 0}    --对手
            --     },
            -- },
        -- }
    local function  count_score_func( players,index,count_score)
        
        for i=1,#players do
            for j=i+1,#players do
                --初始化返回数据
                local player1_chairId = players[i].chairId
                local player2_chairId = players[j].chairId
                local player1_cards =  players[i].cards
                local player2_cards =  players[j].cards
                count_score[player1_chairId] =  count_score[player1_chairId] or {}
                count_score[player2_chairId] =  count_score[player2_chairId] or {}
                count_score[player1_chairId][index] = count_score[player1_chairId][index] or {}
                count_score[player2_chairId][index] = count_score[player2_chairId][index] or {}
                local compareResult = self:compare(players[i].cards[index],players[j].cards[index])

                local function is_extra( cards,index ) --是否额外得分
                    local extra = 0
                    local cardType =  self:get_card_type(cards)
                    if index == 1 then
                        if cardType == CARD_TYPE.SAN_TIAO then --冲三
                            extra = 2
                        end
                    elseif index == 2 then

                        if cardType == CARD_TYPE.HU_LU then --中墩葫芦
                            extra = 1
                        elseif cardType == CARD_TYPE.TIE_ZHI then --铁支
                            extra = 6
                        elseif cardType == CARD_TYPE.TONG_HUA_SHUN then --同花顺
                            extra = 8
                        end
                    elseif index == 3 then
                        if cardType == CARD_TYPE.TIE_ZHI then --铁支
                            extra = 3
                        elseif cardType == CARD_TYPE.TONG_HUA_SHUN then --同花顺
                            extra = 4
                        end
                    end
                    return extra
                end

                if compareResult > 0 then
                    local winCards = player1_cards[index]
                    count_score[player1_chairId][index][player2_chairId] = {win = 1,extra = is_extra( winCards,index ),shoot = 0,qld = 0}
                    count_score[player2_chairId][index][player1_chairId] = {win = -1,extra = -1 *is_extra( winCards,index ),shoot = 0,qld = 0}

                elseif compareResult < 0 then
                    local winCards = player2_cards[index]
                    count_score[player2_chairId][index][player1_chairId] = {win = 1,extra = is_extra( winCards,index ),shoot = 0,qld = 0}
                    count_score[player1_chairId][index][player2_chairId] = {win = -1,extra = -1 *is_extra( winCards,index ),shoot = 0,qld = 0 }
                else --平局
                    count_score[player2_chairId][index][player1_chairId] = {win = 0,extra = 0,shoot = 0,qld = 0}
                    count_score[player1_chairId][index][player2_chairId] = {win = 0,extra = 0,shoot = 0,qld = 0}
                end
                
            end
        end
    end
 
   

    --普通牌型比较
    local function compareNormal(players)
        bipaiResult.normal = {}
        bipaiResult.normal.sort_players = {}
        bipaiResult.normal.count_score = {}
        for i=1,3 do
            normal_sort(players,i,bipaiResult.normal.sort_players)
            count_score_func( players,i, bipaiResult.normal.count_score)
        end
    end

    --daqiang luoji
    local function shootLogic()
        bipaiResult.shoot ={}

        --比较两副牌大小
        --默认player1 》 player2
        local function compareShoot( chairId1,chairId2,index )
            local player_card1 = nil
            local player_card2 = nil

            for i,player in ipairs(bipaiResult.normal.sort_players[index]) do
                if player.chairId == chairId1 then
                    player_card1 = player.cards[index]
                elseif player.chairId == chairId2 then
                    player_card2 = player.cards[index]
                end
                if player_card1 and player_card2 then break end
            end
            return self:compare(player_card1,player_card2)
        end
        for i = #bipaiResult.normal.sort_players[1],1,-1 do
            for j = i -1 ,1,-1 do
                local player1 = bipaiResult.normal.sort_players[1][i]
                local player2 = bipaiResult.normal.sort_players[1][j]
                if compareShoot(player1.chairId,player2.chairId,1) > 0 and  compareShoot(player1.chairId,player2.chairId,2) > 0 and  compareShoot(player1.chairId,player2.chairId,3) > 0 then
                   local shootId = player1.chairId
                   local get_shot_id = player2.chairId
                    bipaiResult.shoot[shootId] = bipaiResult.shoot[shootId] or {}
                    table.insert(bipaiResult.shoot[shootId],get_shot_id)
                    for round=1,3 do
                        bipaiResult.normal.count_score[shootId][round][get_shot_id].shoot = 1 --打枪
                        bipaiResult.normal.count_score[get_shot_id][round][shootId].shoot = -1 --被打枪
                    end
                end
            end
        end
    end


    local function quanleidaLogic(  )
        if #normal_cards ~= 4 then return end --不是4个普通牌型 不能全垒打
        for shootId,get_shot_ids in pairs(bipaiResult.shoot) do
            if #get_shot_ids == 3 then --打枪3人 肯定是全垒打了
                for _,get_shot_id in ipairs(get_shot_ids) do
                    for round=1,3 do
                        bipaiResult.normal.count_score[shootId][round][get_shot_id].qld = 1 --全垒打
                        bipaiResult.normal.count_score[get_shot_id][round][shootId].qld = -1 --被打
                    end
                end
                break
            end
        end
    end


    
    compareNormal(normal_cards)
    shootLogic()
    quanleidaLogic()
   
    function count_score_special_func(  )
        for i= 1,#bipaiResult.special.sort_players do
            local card_type = self:get_card_type(player.cards[1])
            --特殊牌型先扣 普通牌型的分
            for _,player2 in ipairs(bipaiResult.normal.sort_players) do
                local player1_chairId = player1.chairId
                local player2_chairId = player2.chairId
                bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
                bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}

                bipaiResult.special.count_score[player1_chairId][player2_chairId] = card_type.win_fen
                bipaiResult.special.count_score[player2_chairId][player1_chairId] = -1*card_type.win_fen
            end


            --特殊牌型互比
            for j= i + 1,#bipaiResult.special.sort_players do
                local player1_chairId = bipaiResult.special.sort_players[i].chairId
                local player2_chairId = bipaiResult.special.sort_players[j].chairId
                local player1_cards =  bipaiResult.special.sort_players[i].cards
                local player2_cards =  bipaiResult.special.sort_players[j].cards
                local compareResult = self:compare(player1_cards,player2_cards)
                if compareResult > 0 then
                    local card_type = self:get_card_type(player1_cards)
                    bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
                    bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}
                    bipaiResult.special.count_score[player1_chairId][player2_chairId] = card_type.win_fen
                    bipaiResult.special.count_score[player2_chairId][player1_chairId] = -1*card_type.win_fen
                elseif compareResult < 0 then
                    local card_type = self:get_card_type(player2_cards)
                    bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
                    bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}
                    bipaiResult.special.count_score[player2_chairId][player1_chairId] = card_type.win_fen
                    bipaiResult.special.count_score[player1_chairId][player2_chairId] = -1*card_type.win_fen
                else
                    bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
                    bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}
                    bipaiResult.special.count_score[player2_chairId][player1_chairId] = 0
                    bipaiResult.special.count_score[player1_chairId][player2_chairId] = 0
                end
            end
        end
    end


       --排序
    local function sort_special( players,sort_players )
        table.sort(players,function (player1,player2 )
            local compareResult = self:compare(player1.cards[1],player2.cards[1])
            return compareResult < 0
        end)
        for _,playerInfo in ipairs(players) do
            table.insert(sort_players,{chairId = playerInfo.chairId,type = self:get_card_type(playerInfo.cards[1])})
        end
    end

    local function compareSpecial(players)
        bipaiResult.special = {}
        bipaiResult.special.sort_players = {}
        bipaiResult.special.count_score = {}
        
        sort_special(players,bipaiResult.special.sort_players)
        count_score_special_func(players,i, bipaiResult.special.count_score)
        
    end

    compareSpecial(special_cards)
    return bipaiResult
end
