define = require("game/sanshui/logic/define")

local CARD_TYPE = define.CADE_TYPE

local logic = class("logic")

local function foreach(array,iter_func)
    for k,v in pairs(array) do iter_func(k,v) end
end

local function inc_field(tb,field,value)
    tb[field] = tb[field] + value
end

function push_back(tb,elem)
    tb[#tb + 1] = elem
end

function pop_back(tb)
    table.remove(tb,#tb)
end

local function array_count_value(array,kv_func,max_key)
    local counts = {}
    for i = 1,max_key do counts[i]  = {} end
    
    local k1 = nil
    local v1 = nil
    foreach(array,function(k,v)
        k1,v1 = kv_func(k,v)
        if k1 and k1 > 0  and v1 then  push_back(counts[k1],v1) end
    end)

    return counts
end

local function array_counts(array,kv_func,max_key)
    local counts = {}
    for i = 1,max_key do counts[i] = 0 end
    
    local k1 = nil
    local v1 = nil
    foreach(array,function(k,v) 
        k1,v1 = kv_func(k,v)
        if k1 and k1 > 0 and v1 then inc_field(counts,k1,v1) end
    end)

    return counts
end

local function sum_counts(counts,iterator_func)
    local sum = 0
    local k1,v1
    for k,v in pairs(counts) do
        k1,v1 = iterator_func(k,v)
        sum = sum + v1
    end

    return sum
end

function logic:ctor() return end

function logic:is_tonghuashun(card_color_value,count)
    for k,v in pairs(card_color_value) do
        if #v >= 3 and #v == count then
            local c_counts = array_counts(v,function(k,v) return v,1 end,60)
            if #self:is_shunzi(c_counts,#v) > 0 then return true end
        end
    end

    return false
end

function logic:is_tiezhi(card_num_value)
    if sum_counts(card_num_value,function(k,v) return k,#v end) == 3 then return false end
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[4] > 0 and counts[1] > 0
end

function logic:is_hulu(card_num_value)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[3] > 0 and counts[2] > 0
end

function logic:is_tonghua(card_color_value)
    local colors = 0
    local card_count = 0
    for k,v in ipairs(card_color_value) do
        if #v > 0 then 
            colors = colors + 1 
            card_count = card_count + #v
        end
    end

    return card_count > 3 and colors == 1
end

function logic:is_santiao(card_num_value)
    local all_card_count = sum_counts(card_num_value,function(k,v) return k,#v end)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return (all_card_count == 3 and counts[3] > 0) or (counts[3] > 0 and counts[1] >= 2)
end

function logic:is_liangdui(card_num_value)
    if sum_counts(card_num_value,function(k,v) return k,#v end) == 3 then return false end
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[2] >= 2
end

function logic:is_duizi(card_num_value)
    local all_card_count = sum_counts(card_num_value,function(k,v) return k,#v end)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return (all_card_count == 3 and counts[2] > 0) or (counts[2] > 0 and counts[1] >= 3)
end

function logic:is_shunzi(card_counts,scale)
    local card_num_value = array_count_value(card_counts,function(k,v) if v > 0 then return  k % 15,k else return k % 15,nil  end end,14)
    local all_shunzi = {}

    local function peek_one_shunzi(ret_cards,card_num_value,cur_num,scale)
        if #card_num_value[cur_num] == 0 then  return end

        for _,v in pairs(card_num_value[cur_num]) do
            push_back(ret_cards,v)
            if #ret_cards == scale then 
                push_back(all_shunzi,clone(ret_cards)) 
            else
                peek_one_shunzi(ret_cards,card_num_value,cur_num + 1,scale)
            end
            pop_back(ret_cards)
        end
    end

    if #card_num_value[1] > 0 then card_num_value[14] = card_num_value[1] end
    if #card_num_value[14] > 0 then card_num_value[1] = card_num_value[14] end

    for i = 1,15 - scale do 
        local cards = {}
        peek_one_shunzi(cards,card_num_value,i,scale)
    end

    return all_shunzi
end


function logic:is_shierhuangzu(card_num_value)
    return #card_num_value[11] + #card_num_value[12] + #card_num_value[13]  + #card_num_value[14] + #card_num_value[1]== 13
end

function logic:is_same_color(cards)
    local color_count_map = {}
    foreach(cards,function(k,v) 
        local color = math.floor(v / 15) + 1
        if not color_count_map[color] then color_count_map[color] = 0 end
        inc_field(color_count_map,color,1)
    end)

    return table.nums(color_count_map) == 1
end

function logic:is_santonghuashun(card_counts)
    local all_santonghuashun = {}
    local all_sanshunzi = self:is_sanshunzi(card_counts)
    for _,sanshunzi in pairs(all_sanshunzi) do
        if #sanshunzi == 3 and self:is_same_color(sanshunzi[1]) and self:is_same_color(sanshunzi[2]) and self:is_same_color(sanshunzi[3]) then
            push_back(all_santonghuashun,sanshunzi)
        end
    end

    return all_santonghuashun
end

function logic:is_sanfentianxia(card_num_value)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[4] == 3
end

function logic:is_quanda(card_num_value)
    return #card_num_value[8] + #card_num_value[9] + #card_num_value[10] + #card_num_value[11] 
        + #card_num_value[12] + #card_num_value[13] + #card_num_value[14] +  #card_num_value[1] == 13
end

function logic:is_quanxiao(card_num_value)
    return #card_num_value[2] + #card_num_value[3] + #card_num_value[4] + #card_num_value[5] 
        + #card_num_value[6] + #card_num_value[7] + #card_num_value[8] == 13
end

function logic:is_couyise(card_color_value)
    return #card_color_value[1] + #card_color_value[3] == 13 or 
            #card_color_value[2] + #card_color_value[4] == 13
end

function logic:is_sitaosantiao(card_num_value)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[3] == 4
end

function logic:is_wuduisantiao(card_num_value)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[3] == 1 and counts[2] + counts[4] * 2 == 5
end

function logic:is_liuduiban(card_num_value)
    local counts = array_counts(card_num_value,function(k,v) return #v,1 end,13)
    return counts[2] + counts[4] * 2 == 6
end


function logic:is_sanshunzi(card_counts)
    local all_sanshunzi = {}
    local all_shunzi5 = self:is_shunzi(card_counts,5)
    if  #all_shunzi5 == 0 then return all_sanshunzi end

    local sanshunzi_buf_stack = {}

    for _,shunzi5 in ipairs(all_shunzi5) do 
        push_back(sanshunzi_buf_stack,shunzi5)
        for _,i in ipairs(shunzi5)  do inc_field(card_counts,i,-1) end

        local all_shunzi5_1 = self:is_shunzi(card_counts,5)

        for _,shunzi5_1 in ipairs(all_shunzi5_1) do
            push_back(sanshunzi_buf_stack,shunzi5_1)
            for _,i in ipairs(shunzi5_1) do inc_field(card_counts,i,-1) end

            local all_shunzi3 = self:is_shunzi(card_counts,3)
            for _,shunzi3 in ipairs(all_shunzi3) do
                push_back(sanshunzi_buf_stack,shunzi3)

                local sanshunzi = clone(sanshunzi_buf_stack)
                table.sort(sanshunzi,function(a,b) return #a < #b end)
                
                push_back(all_sanshunzi,sanshunzi)

                pop_back(sanshunzi_buf_stack)
            end

            for _,i in ipairs(shunzi5_1) do inc_field(card_counts,i,1) end
            pop_back(sanshunzi_buf_stack)
        end

        for _,i in ipairs(shunzi5)  do inc_field(card_counts,i,1) end
        pop_back(sanshunzi_buf_stack)
    end

    return all_sanshunzi
end

function logic:is_santonghua(card_color_value)
    local cards = {}
    local card_color_counts = array_count_value(card_color_value,function(k,v) return #v,v end,13)
    if #card_color_counts[13] == 1 then
        return true,card_color_counts[13][1]
    end

    if #card_color_counts[10] == 1 and #card_color_counts[3] == 1 then
        for _,v in pairs(card_color_counts[3][1]) do push_back(cards, v) end
        for _,v in pairs(card_color_counts[10][1]) do push_back(cards, v) end
        return true,cards
    end

    if #card_color_counts[5] == 2 and #card_color_counts[3] == 1 then
        for _,v in pairs(card_color_counts[3][1]) do push_back(cards, v) end
        for _,v in pairs(card_color_counts[5][1]) do push_back(cards, v) end
        for _,v in pairs(card_color_counts[5][2]) do push_back(cards, v) end
        return true,cards
    end

    if #card_color_counts[5] == 1 and #card_color_counts[8] == 1 then
        for _,v in pairs(card_color_counts[8][1]) do push_back(cards, v) end
        for _,v in pairs(card_color_counts[5][1]) do push_back(cards, v) end
        return true,cards
    end
    
    return false
end

function logic:split_cards(state)
    local card_counts = state.card_counts
	
	--�Ƶľ�����ֵ�ֲ�ͳ�� 0-14
    local card_num_value   = array_count_value(card_counts,function(k,v) 
        if v > 0 then return k % 15,k 
        else return nil,nil end
    end,14)

	--ͬ��С��������ͳ��
    local card_num_counts_value = array_count_value(card_num_value,function(k,v) 
        if #v == 0 then return nil,nil end
        return #v,v
    end,13)

--    dump(card_num_counts_value)
	
	--��ͬ��ɫͳ��
    local card_color_value  = array_count_value(card_counts,function(k,v)
        if v > 0 then return math.floor(k / 15) + 1,k
        else return nil,nil end
    end,4)

    local cards = {}
    local all_cards = {}

    for k,v in pairs(card_counts) do 
        if v > 0 then push_back(all_cards, k) end
    end

    table.sort(all_cards)

    if #all_cards == 13 then
        for i = 1,1 do
            if #self:is_shunzi(card_counts,13) > 0 then 
			    local card_color_counts = array_counts(card_color_value,function(k,v) return #v,1 end,13)

                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a % 15 < b % 15 end)

                if card_color_counts[13] == 1 then
                    push_back(state.types, {{cards = cards,type = CARD_TYPE.QING_LONG}})
                else
                    push_back(state.types, {{cards = cards,type = CARD_TYPE.YI_TIAO_LONG}})
                end
                break
            end

            if self:is_shierhuangzu(card_num_value) then
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a % 15 < b % 15 end)
                push_back(state.types,{{cards = cards,type = CARD_TYPE.SHI_ER_HUANG_ZHU}})
                break
            end

            local all_santonghuashun = self:is_santonghuashun(card_counts)
            if #all_santonghuashun > 0 then       
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return math.floor(a / 15) < math.floor(b / 15) end)    
                push_back(state.types, {{cards = all_cards,type = CARD_TYPE.SAN_TONG_HUA_SHUN}})
                break
            end

            if self:is_sanfentianxia(card_num_value) then
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a % 15 < b % 15 end)
                push_back(state.types, {{cards = cards,type = CARD_TYPE.SAN_FEN_TIAN_XIA}})
                break
            end

            if self:is_quanda(card_num_value) then
                push_back(state.types, {{cards = all_cards,type = CARD_TYPE.QUAN_DA}})
                break
            end

            if self:is_quanxiao(card_num_value) then
                push_back(state.types, {{cards = all_cards,type = CARD_TYPE.QUAN_XIAO}})
                break
            end

            if self:is_couyise(card_color_value) then
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a / 15 < b / 15 end)
                push_back(state.types, {{cards = all_cards,type = CARD_TYPE.COU_YI_SE}})
                break
            end

            if self:is_sitaosantiao(card_num_value) then
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a % 15 < b % 15 end)
                push_back(state.types, {{cards = cards,type = CARD_TYPE.SI_TAO_SAN_TIAO}})
                break
            end

            if self:is_wuduisantiao(card_num_value) then
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a % 15 < b % 15 end)
                push_back(state.types, {{cards = cards,type = CARD_TYPE.WU_DUI_SAN_TIAO}})
                break
            end
        
            if self:is_liuduiban(card_num_value) then
                local cards = clone(all_cards)
                table.sort(cards, function(a, b) return a % 15 < b % 15 end)
                push_back(state.types, {{cards = cards,type = CARD_TYPE.LIU_DUI_BAN}})
                --return
            end


            local a_cards = self:is_sanshunzi(card_counts)
            if #a_cards > 0 then
                local cards = {}
                for _,v in ipairs(a_cards[1]) do
                    for __,vv in ipairs(v) do
                        table.insert(cards,1,v[#v - __ + 1])
                    end
                end
                push_back(state.types,{{cards = cards,type = CARD_TYPE.SAN_SHUN_ZI}})
                break
            end

            local ret,cards = self:is_santonghua(card_color_value)
            if ret then
                push_back(state.types,{{cards = cards,type = CARD_TYPE.SAN_TONG_HUA}})
                break
            end
        end
    end

    --print("card_sum 1",card_sum)
    for key,value in pairs(card_color_value) do
        if #value >= 5 then
            print("1")
         
            local all_shunzi = self:is_shunzi(array_counts(value,function(k,v) return v,1 end,60),5)
            if #all_shunzi > 0 then --ͬ��˳
                for _,cs in pairs(all_shunzi) do
                    for _,v in pairs(cs) do inc_field(card_counts,v,-1) end

                    push_back(state.cur_type,{cards = clone(cs),type = CARD_TYPE.TONG_HUA_SHUN})
            
                    self:split_cards(state)
                
                    pop_back(state.cur_type)

                    for _,i in pairs(cs) do inc_field(card_counts,i,1) end
                end
            else
                for i = 1,#value - 4 do --ͬ��
                    for j = 0,4 do inc_field(card_counts,value[i + j],-1) end
 
                    push_back(state.cur_type,{cards = {value[i],value[i + 1],value[i + 2],value[i + 3],value[i + 4]},type = CARD_TYPE.TONG_HUA})
                    self:split_cards(state)
                    pop_back(state.cur_type)

                    for j = 0,4 do inc_field(card_counts,value[i + j],1) end
                end
            end
        end
    end

	--print("card_sum 2",card_sum)
    if #card_num_counts_value[4] > 0 then --��֧
        print("2")

        for _,v in pairs(card_num_counts_value[4]) do
            for i = 1,4 do inc_field(card_counts,v[i],-1) end

            if #card_num_counts_value[1] > 0 then
                local v1 = card_num_counts_value[1]
                local i = #v1
                cards = {v[1],v[2],v[3],v[4],v1[i][1]}

                card_counts[v1[i][1]] = card_counts[v1[i][1]] - 1

                push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.TIE_ZHI})
            
                self:split_cards(state)
                
                pop_back(state.cur_type)

                card_counts[v1[i][1]] = card_counts[v1[i][1]] + 1
            elseif #card_num_counts_value[2] > 0 then
                for _,v1 in pairs(card_num_counts_value[2]) do
                    cards = {v[1],v[2],v[3],v[4],v1[1]}

                    inc_field(card_counts,v1[1],-1)

                    push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.TIE_ZHI})
            
                    self:split_cards(state)

                    pop_back(state.cur_type)

                    inc_field(card_counts,v1[1],1)
                end
            elseif #card_num_counts_value[3] > 0 then
                for _,v1 in pairs(card_num_counts_value[3]) do
                    cards = {v[1],v[2],v[3],v[4],v1[1]}

                    inc_field(card_counts,v1[1],-1)
                    push_back(state.cur_type, {cards = {v[1],v[2],v[3],v[4],v1[1]},type = CARD_TYPE.TIE_ZHI})
            
                    self:split_cards(state)
                    
                    pop_back(state.cur_type)

                    inc_field(card_counts,v1[1],1)
                end
            end

            for i = 1,4 do inc_field(card_counts,v[i],1) end
        end
    end

	--print("card_sum 3",card_sum)
    if #card_num_counts_value[3] > 0 and #card_num_counts_value[2] > 0 then --��«
        print("3")
        for k = #card_num_counts_value[3],1,-1 do 
            local v = card_num_counts_value[3][k]
            for i = 1,3 do inc_field(card_counts,v[i],-1) end

            for _,v1 in ipairs(card_num_counts_value[2]) do
                cards = {v[1],v[2],v[3],v1[1],v1[2]}

                for i = 1,2 do inc_field(card_counts,v1[i],-1) end

                push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.HU_LU})

                self:split_cards(state)
                
                pop_back(state.cur_type)

                for i = 1,2 do inc_field(card_counts,v1[i],1) end
            end

            for i = 1,3 do inc_field(card_counts,v[i],1) end
        end
    end

	--print("card_sum 4",card_sum)
    local all_shunzi = self:is_shunzi(card_counts,5) --˳��
    if #all_shunzi > 0 then
        for _,cs in pairs(all_shunzi) do
            local card_color_counts  = array_counts(cs,function(k,v) return math.floor(v / 15) + 1,1 end,4)
            if card_color_counts[1] ~= #cs and card_color_counts[2] ~= #cs and card_color_counts[3] ~= #cs and card_color_counts[4] ~= #cs then 
                print("4")
                for _,v in pairs(cs) do inc_field(card_counts,v,-1) end

                push_back(state.cur_type, {cards = clone(cs),type = CARD_TYPE.SHUN_ZI})
        
                self:split_cards(state)

                pop_back(state.cur_type)

                for _,v in pairs(cs) do inc_field(card_counts,v,1) end
            end
        end
    end

    --print("card_sum 5",card_sum)
    if #card_num_counts_value[3] > 0 and #card_num_counts_value[1] >= 2 then --����
        print("5")
		
        for k = #card_num_counts_value[3],1,-1 do
            local v = card_num_counts_value[3][k]

            for i = 1,3 do inc_field(card_counts,v[i],-1) end

            local i = 1  --�����ĸ����ƣ�����С��ѡ��      --#card_num_counts_value[1] - 1
            

            for j = 1,2 do inc_field(card_counts,card_num_counts_value[1][j][1],-1) end

            cards = {v[1],v[2],v[3],card_num_counts_value[1][1][1],card_num_counts_value[1][2][1]}

            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.SAN_TIAO})

            self:split_cards(state)
            
            pop_back(state.cur_type)

            for j = 1,2 do inc_field(card_counts,card_num_counts_value[1][j][1],1) end
            for i = 1,3 do inc_field(card_counts,v[i],1) end
        end
    end

    --print("card_sum 6",card_sum)
    if #card_num_counts_value[2] >= 2 and #card_num_counts_value[1] > 0 then --����
        print("6")
        local k = 1 --���Եĸ����ƣ�����С��ѡ��   #card_num_counts_value[1]
        inc_field(card_counts,card_num_counts_value[1][k][1],-1)
        for i = #card_num_counts_value[2] - 1,1,-1 do
            cards = {}
            for j = 1,2 do inc_field(card_counts,card_num_counts_value[2][i][j],-1) end
            for j = 1,2 do inc_field(card_counts,card_num_counts_value[2][i + 1][j],-1) end

            for j = 1,2 do push_back(cards,card_num_counts_value[2][i][j]) end
            for j = 1,2 do push_back(cards,card_num_counts_value[2][i + 1][j]) end
            push_back(cards,card_num_counts_value[1][k][1])

            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.LIANG_DUI})

            self:split_cards(state)

            pop_back(state.cur_type)

            for j = 1,2 do inc_field(card_counts,card_num_counts_value[2][i][j],1) end
            for j = 1,2 do inc_field(card_counts,card_num_counts_value[2][i + 1][j],1) end
        end

        inc_field(card_counts,card_num_counts_value[1][k][1],1)
    end

    --print("card_sum 7",card_sum)
    if #card_num_counts_value[2] >= 1 and #card_num_counts_value[1] >= 3 then --����
        print("7")
        for k = #card_num_counts_value[2],1,-1 do
            local v = card_num_counts_value[2][k]

            local j = 1 --һ�Եĸ����ƣ�����С��ѡ�� --#card_num_counts_value[1] - 2
            for i = 0,2 do inc_field(card_counts,card_num_counts_value[1][j + i][1],-1) end
            for i = 1,2 do inc_field(card_counts,v[i],-1) end
            cards = {}
            for i = 0,2 do push_back(cards,card_num_counts_value[1][j + i][1]) end
            for i = 1,2 do push_back(cards,v[i]) end
            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.DUI_ZI} )

            self:split_cards(state)

            pop_back(state.cur_type)

            for i = 0,2 do inc_field(card_counts,card_num_counts_value[1][j + i][1],1) end
            for i = 1,2 do inc_field(card_counts,v[i],1) end
        end

        return
    end

    --print("card_sum 11",card_sum) --û�ж������ϵ��ƣ�ֻ���������?
    if #all_cards >= 5 then --����
        print("11")
        if #card_num_counts_value[1] >= 5 then
            --5����ѡ�ƹ���ѡһ�����ģ�Ȼ��4����С��
            cards = {}
            local k = #card_num_counts_value[1]
    		cards[1] = card_num_counts_value[1][k][1]
            --5�����ĸ����ƣ�����С��ѡ��
            for i = 1,4 do push_back(cards,card_num_counts_value[1][i][1]) end
            for i = 1,4 do inc_field(card_counts,card_num_counts_value[1][i][1],-1) end
            inc_field(card_counts,card_num_counts_value[1][k][1],-1)

            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.WU_LONG})
            self:split_cards(state)
            cards = {}
            pop_back(state.cur_type)

            for i = 1,4 do inc_field(card_counts,card_num_counts_value[1][i][1],1) end
            inc_field(card_counts,card_num_counts_value[1][k][1],1)
        else
            cards = {}
            for i = 1,60 do
                if card_counts[i] > 0 then push_back(cards,i) end
                if #cards == 5 then 
                    for _,v in ipairs(cards) do card_counts[v] = card_counts[v] - 1 end
                    push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.WU_LONG} )

                    self:split_cards(state)     

                    for _,v in ipairs(cards) do card_counts[v] = card_counts[v] + 1 end
                    cards = {}
                    pop_back(state.cur_type)
                end   
            end
        end
    end

    --print("card_sum 12",card_sum) --ʣ��3�����ͷ��?
    if #all_cards == 3 then
        if #card_num_counts_value[3] >= 1 then
            print("8")
            cards = {card_num_counts_value[3][1][1],card_num_counts_value[3][1][2],card_num_counts_value[3][1][3]}
            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.SAN_TIAO})
        elseif #card_num_counts_value[2] >= 1 then
            print("9")
            cards = {card_num_counts_value[2][1][1],card_num_counts_value[2][1][2],card_num_counts_value[1][1][1]}
            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.DUI_ZI})
        else
            print("10")
            cards = {card_num_counts_value[1][1][1],card_num_counts_value[1][2][1],card_num_counts_value[1][3][1]}
            push_back(state.cur_type, {cards = clone(cards),type = CARD_TYPE.WU_LONG})
        end
		
		local result1 = self:compare_type(state.cur_type[2], state.cur_type[1])
		local result2 = self:compare_type(state.cur_type[3], state.cur_type[2])
		--β�������е�������
		if result1 < 1 and result2 < 1 then
			push_back(state.types, clone(state.cur_type)) --record the cur_types calculate above 
		end
    end
    pop_back(state.cur_type) -- clean the state.cur_type container
end

function logic:split_state_card(cards)
    local state = {
        card_counts = array_counts(cards,function(k,v) return v,1 end,60),
        types = {},
        cur_type = {}
    }

    self:split_cards(state)

    dump(state.types)

    if #state.types == 0 then log.error("logic:split_state_card faild") end
    local types = self:type_sort(state.types)
    if #types == 0 then log.error("logic:split_state_card faild") end
    dump(types)
    return types
end

function logic:get_card_type(cards)
    local card_counts      =  array_counts(cards,function(k,v) return v,1 end,60)
    local card_num_value   =  array_count_value(cards,function(k,v) return v % 15,v end,14)
    local card_color_value = array_count_value(cards,function(k,v) return math.floor(v / 15) + 1,v end,4)

    if #cards == 13 then
        if #self:is_shunzi(card_counts,13) > 0 then 
            return (#card_color_value[1] == 13 or #card_color_value[2] == 13 or #card_color_value[3] == 13 or #card_color_value[4] == 13) and
                CARD_TYPE.QING_LONG or CARD_TYPE.YI_TIAO_LONG
        end

        if self:is_shierhuangzu(card_num_value) then return CARD_TYPE.SHI_ER_HUANG_ZHU end
        if #self:is_santonghuashun(card_counts) > 0 then return CARD_TYPE.SAN_TONG_HUA_SHUN end
        if self:is_sanfentianxia(card_num_value) then return CARD_TYPE.SAN_FEN_TIAN_XIA end
        if self:is_quanda(card_num_value) then  return CARD_TYPE.QUAN_DA end
        if self:is_quanxiao(card_num_value) then return CARD_TYPE.QUAN_XIAO end
        if self:is_couyise(card_color_value) then return CARD_TYPE.COU_YI_SE end
        if self:is_sitaosantiao(card_num_value) then return CARD_TYPE.SI_TAO_SAN_TIAO end
        if self:is_wuduisantiao(card_num_value) then return CARD_TYPE.WU_DUI_SAN_TIAO end
        if self:is_liuduiban(card_num_value) then return CARD_TYPE.LIU_DUI_BAN  end
        if #self:is_sanshunzi(card_counts) > 0 then return CARD_TYPE.SAN_SHUN_ZI  end
        if self:is_santonghua(card_color_value) then return CARD_TYPE.SAN_TONG_HUA end
        return nil
    end

    if self:is_tonghuashun(card_color_value,#cards) and #cards > 3 then return CARD_TYPE.TONG_HUA_SHUN end
    if self:is_tiezhi(card_num_value) then return CARD_TYPE.TIE_ZHI end
    if self:is_hulu(card_num_value) then return CARD_TYPE.HU_LU end
    if self:is_tonghua(card_color_value) then return CARD_TYPE.TONG_HUA end
    if #cards > 3 and #self:is_shunzi(card_counts,#cards) > 0 then return CARD_TYPE.SHUN_ZI end
    if self:is_santiao(card_num_value) then return CARD_TYPE.SAN_TIAO end
    if self:is_liangdui(card_num_value) then return CARD_TYPE.LIANG_DUI end
    if self:is_duizi(card_num_value) then return CARD_TYPE.DUI_ZI end
    return CARD_TYPE.WU_LONG
end

function logic:compare_type(cards1,cards2)
    local type1 = cards1.type
    local type2 = cards2.type

    if not type1 and not type2 then return 0 end
    if type1 and not type2 then return 1 end
    if not type1 and type2 then return -1 end

    if type1.index < type2.index then return -1 end
    if type1.index > type2.index then return 1  end

    local card_num_counts1 = array_counts(cards1.cards,function(k,v) return v % 15,1 end,14)
    local card_num_counts2 = array_counts(cards2.cards,function(k,v) return v % 15,1 end,14)
    local card_count_num1 = array_count_value(card_num_counts1,function(k,v) return v,k end,13)
    local card_count_num2 = array_count_value(card_num_counts2,function(k,v) return v,k end,13)

    if type1 == CARD_TYPE.TIE_ZHI then return card_count_num1[4][1] > card_count_num2[4][1] and 1 or -1 end
    if type1 == CARD_TYPE.HU_LU or type1 == CARD_TYPE.SAN_TIAO then  return card_count_num1[3][1] > card_count_num2[3][1] and 1 or -1 end
    if type1 == CARD_TYPE.DUI_ZI then 
        if card_count_num1[2][1] > card_count_num2[2][1] then return 1 end
        if card_count_num1[2][1] < card_count_num2[2][1] then return -1 end
        table.sort(card_count_num1[1],function(a,b) return a > b end)
        table.sort(card_count_num2[1],function(a,b) return a > b end)
        local min_count = #card_count_num1[1] < #card_count_num2[1] and #card_count_num1[1] or #card_count_num2[1]
        for i = 1,min_count do
            if card_count_num1[1][i] > card_count_num2[1][i] then return 1 end
            if card_count_num1[1][i] < card_count_num2[1][i] then return -1 end
        end

        return 0
    end 

    if type1 == CARD_TYPE.LIANG_DUI then
        table.sort(card_count_num1[2],function(a,b) return a > b end)
        table.sort(card_count_num2[2],function(a,b) return a > b end)
        if card_count_num1[2][1] > card_count_num2[2][1] then return 1 end
        if card_count_num1[2][1] < card_count_num2[2][1] then return -1 end
        if card_count_num1[2][2] > card_count_num2[2][2] then return 1 end
        if card_count_num1[2][2] < card_count_num2[2][2] then return -1 end
        if card_count_num1[1][1] > card_count_num2[1][1] then return  1 end
        if card_count_num1[1][1] < card_count_num2[1][1] then return  -1 end
        return 0
    end

    if type1 == CARD_TYPE.SHUN_ZI or type1 == CARD_TYPE.TONG_HUA_SHUN then
        if card_num_counts1[14] > 0 and card_num_counts1[2] > 0 then 
            card_num_counts1[14] = 0
            card_num_counts1[1] = 1 
        end

        if card_num_counts2[14] > 0 and card_num_counts2[2] > 0 then 
            card_num_counts2[14] = 0
            card_num_counts2[1] = 1 
        end
    end

    for j = 14,1,-1 do
        if card_num_counts1[j] > 0 and card_num_counts2[j] == 0 then return 1 end
        if card_num_counts1[j] == 0 and card_num_counts2[j] > 0 then return -1 end
    end 

    return 0
end


function logic:compare(cards1,cards2)
    local type1 = self:get_card_type(cards1)
    local type2 = self:get_card_type(cards2)

--    dump(type1)
--    dump(type2)

    if not type1 and not type2 then return 0 end
    if type1 and not type2 then return 1 end
    if not type1 and type2 then return -1 end

    if type1.index < type2.index then return -1 end
    if type1.index > type2.index then return 1  end

    local card_num_counts1 = array_counts(cards1,function(k,v) return v % 15,1 end,14)
    local card_num_counts2 = array_counts(cards2,function(k,v) return v % 15,1 end,14)
    local card_count_num1 = array_count_value(card_num_counts1,function(k,v) return v,k end,13)
    local card_count_num2 = array_count_value(card_num_counts2,function(k,v) return v,k end,13)

    if type1 == CARD_TYPE.TIE_ZHI then
         if card_count_num1[4][1] > card_count_num2[4][1] then return 1 end
         if card_count_num1[4][1] > card_count_num2[4][1] then return -1 end 
         return 0
    end

    if type1 == CARD_TYPE.HU_LU or type1 == CARD_TYPE.SAN_TIAO then  
         if card_count_num1[3][1] > card_count_num2[3][1] then return 1 end
         if card_count_num1[3][1] < card_count_num2[3][1] then return -1 end 
         return 0
    end

    if type1 == CARD_TYPE.LIANG_DUI then
        table.sort(card_count_num1[2],function(a,b) return a > b end)
        table.sort(card_count_num2[2],function(a,b) return a > b end)
        if card_count_num1[2][1] > card_count_num2[2][1] then return 1 end
        if card_count_num1[2][1] < card_count_num2[2][1] then return -1 end
        if card_count_num1[2][2] > card_count_num2[2][2] then return 1 end
        if card_count_num1[2][2] < card_count_num2[2][2] then return -1 end
        if card_count_num1[1][1] > card_count_num2[1][1] then return  1 end
        if card_count_num1[1][1] < card_count_num2[1][1] then return  -1 end
        return 0
    end

    if type1 == CARD_TYPE.DUI_ZI then 
        if card_count_num1[2][1] > card_count_num2[2][1] then return 1 end
        if card_count_num1[2][1] < card_count_num2[2][1] then return -1 end
        table.sort(card_count_num1[1],function(a,b) return a > b end)
        table.sort(card_count_num2[1],function(a,b) return a > b end)
        local min_count = #card_count_num1[1] < #card_count_num2[1] and #card_count_num1[1] or #card_count_num2[1]
        for i = 1,min_count do
            if card_count_num1[1][i] > card_count_num2[1][i] then return 1 end
            if card_count_num1[1][i] < card_count_num2[1][i] then return -1 end
        end

        return 0
    end 

    if type1 == CARD_TYPE.SHUN_ZI or type1 == CARD_TYPE.TONG_HUA_SHUN then
        if card_num_counts1[14] > 0 and card_num_counts1[2] > 0 then 
            card_num_counts1[14] = 0
            card_num_counts1[1] = 1 
        end

        if card_num_counts2[14] > 0 and card_num_counts2[2] > 0 then 
            card_num_counts2[14] = 0
            card_num_counts2[1] = 1 
        end
    end

    for j = 14,1,-1 do
        if card_num_counts1[j] > 0 and card_num_counts2[j] == 0 then return 1 end
        if card_num_counts1[j] == 0 and card_num_counts2[j] > 0 then return -1 end
    end 

    return 0
end

function logic:types_code(types)
    if #types == 1 then return types[1].type.index * 1000 end
    return types[1].type.index * 1000 + types[2].type.index * 100 + types[3].type.index
end

function logic:sort_types_compare(types1,types2)
    if #types1 < #types2 then return 1 end
    if #types1 > #types2 then return -1 end
    
    local code1 = self:types_code(types1)
    local code2 = self:types_code(types2)
    if code1 > code2 then return 1 end
    if code1 < code2 then return -1 end
    
    if #types1 == 1 then 
        return self:compare_type(types1[1],types2[1]) 
    end

    if #types1 == 3 then
        local ret = self:compare_type(types1[3],types2[3])
        if ret ~= 0 then return ret end
        ret = self:compare_type(types1[2],types2[2])
        if ret ~= 0 then return ret end
        ret = self:compare_type(types1[1],types2[1])
        if ret ~= 0 then return ret end
    end

    return 0
end


function logic:type_sort(types)
    if not types or #types <= 1 then return types end
    
    table.sort(types,function(types1,types2)  return self:sort_types_compare(types1,types2) > 0 end)

    local ret_types = {types[1]}
    local need_push = true
    for _,v in pairs(types) do
        need_push = true
        for i = #ret_types,1,-1 do
            local ret_type = ret_types[#ret_types]
            local ret_code = self:types_code(ret_type)
            local code = self:types_code(v)

            if  math.floor(ret_code / 1000) >= math.floor(code / 1000) and 
                math.floor((ret_code % 1000) / 100) >= math.floor((code % 1000) / 100) and 
                (ret_code % 100) >= (code % 100) then  
                need_push = false 
            end
        end

        if need_push then 
            push_back(ret_types,v)
        end
    end

    return ret_types
end

function logic:pre_compare_process(cards1, cards2)
    local bipaiResult = {}
    --��������ͷ���?��ͨ/����
    local normal_cards = {}
    local special_cards = {}

    if #cards1 > 1 then 
        table.insert(normal_cards, cards1)
    else
        table.insert(special_cards, cards1)
    end

    if #cards2 > 1 then 
        table.insert(normal_cards, cards2)
    else
        table.insert(special_cards, cards2)
    end

    --����
    local function normal_sort( players,index)
        dump(players,"players")
        table.sort(players,function (player1,player2 )
            local compareResult = self:compare(player1.cards[index], player2.cards[index])
            return compareResult < 0
        end)

        return clone(players)

--        sort_players[index] = player
--        for _,playerInfo in ipairs(players) do
--            table.insert(sort_players[index],playerInfo)
--        end
    end

        --������ƹ����еĵ÷����
        -- count_score = {
            -- player1 = { --ѡ��
            --     1 = --�ִ�
            --     {
            --        player2 = {win = 0 ,extra = 0}    --����
            --     },
            -- },
        -- }
    local function  count_score_func( players,index,count_score)
        for i=1,#players do
            for j=i+1,#players do
                --��ʼ����������
                count_score[1] =  count_score[1] or {}
                count_score[1][index] = count_score[1][index] or {}
                local compareResult = self:compare_type(players[i][index],players[j][index])

                local function is_extra( cards,index ) --�Ƿ����÷�
                    local extra = 0
                    local cardType =  cards.type
                    if index == 1 then
                        if cardType == CARD_TYPE.SAN_TIAO then --����
                            extra = 2
                        end
                    elseif index == 2 then

                        if cardType == CARD_TYPE.HU_LU then --�жպ�«
                            extra = 1
                        elseif cardType == CARD_TYPE.TIE_ZHI then --��֧
                            extra = 6
                        elseif cardType == CARD_TYPE.TONG_HUA_SHUN then --ͬ��˳
                            extra = 8
                        end
                    elseif index == 3 then
                        if cardType == CARD_TYPE.TIE_ZHI then --��֧
                            extra = 3
                        elseif cardType == CARD_TYPE.TONG_HUA_SHUN then --ͬ��˳
                            extra = 4
                        end
                    end
                    return extra
                end

                if compareResult > 0 then
                    local winCards = players[1][index]
                    count_score[1][index] = {win = 1 + is_extra( winCards,index )}
                elseif compareResult < 0 then
                    local winCards = players[2][index]
                    count_score[1][index] = {win = -1 + (-1) *is_extra( winCards,index )}
                else --ƽ��
                    count_score[1][index] = {win = 0}
                end
                
            end
        end
    end
 
    --��ͨ���ͱȽ�
    local function compareNormal(players)
        bipaiResult.normal = {}
        bipaiResult.normal.sort_players = {}
        bipaiResult.normal.count_score = {}
        bipaiResult.normal.normal_players = {}


        for _,player in pairs(players) do
            table.insert(bipaiResult.normal.normal_players,player.chairId)
        end
        for i=1,3 do
            normal_sort(players,i,bipaiResult.normal.sort_players)
            count_score_func( players,i, bipaiResult.normal.count_score)
        end
    end

    compareNormal(normal_cards)
   
    local function count_score_special_func(players)
        for i= 1,#players do 
			local player1 = players[1]
			local card_type1 = player1.type
			
            for _,player2 in ipairs(normal_cards) do
                bipaiResult.special.count_score[1] = bipaiResult.special.count_score[1] or {}

                bipaiResult.special.count_score[1] = card_type1.win_fen
            end

            for j= i + 1,#players do
				local player2 = players[2]
				local card_type2 = player2.type
                local player2 = bipaiResult.special.sort_players[j]

                if card_type1.index > card_type2.index then
                    bipaiResult.special.count_score[1] = bipaiResult.special.count_score[1] or {}
                    bipaiResult.special.count_score[1] = card_type1.win_fen
                elseif card_type1.index < card_type2.index then
                    bipaiResult.special.count_score[1] = bipaiResult.special.count_score[1] or {}
                    bipaiResult.special.count_score[1] = -1*card_type2.win_fen
                else
                    bipaiResult.special.count_score[1] = bipaiResult.special.count_score[1] or {}
                    bipaiResult.special.count_score[1] = 0
                end
            end
        end
    end

       --����
    local function sort_special( players,sort_players )
        table.sort(players,function (player1,player2 )
            local compareResult = self:compare_type(player1,player2)
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
        
        --sort_special(players,bipaiResult.special.sort_players)
        count_score_special_func(players, bipaiResult.special.count_score)
    end

    compareSpecial(special_cards)
	   
    local result = 0
    for i=1,3 do
        if #special_cards > 0 then
            result = result + bipaiResult.special.count_score[1]
        else
            result = result + bipaiResult.normal.count_score[1][i].win
        end
    end
    	
    return result
end

--��������
-- all_cards = {{chairId = xx,cards = {}}}
function logic:compare_process( all_cards)
    local bipaiResult = {}
    --��������ͷ���?��ͨ/����
    local normal_cards = {}
    local special_cards = {}
    for _,playerCards in ipairs(all_cards) do
        if #playerCards.cards == 3 then
            table.insert(normal_cards,playerCards)
        elseif #playerCards.cards == 1 then
			table.insert(special_cards,playerCards)
        end
    end
    --����
    local function normal_sort( players,index,sort_players )
        table.sort(players,function (player1,player2 )
            local compareResult = self:compare(player1.cards[index], player2.cards[index])
            return compareResult < 0
        end)
        sort_players[index] = {}
        for _,playerInfo in ipairs(players) do
            table.insert(sort_players[index],playerInfo)
        end
    end

        --������ƹ����еĵ÷����
        -- count_score = {
            -- player1 = { --ѡ��
            --     1 = --�ִ�
            --     {
            --        player2 = {win = 0 ,extra = 0}    --����
            --     },
            -- },
        -- }
    local function  count_score_func( players,index,count_score)
        
        for i=1,#players do
            for j=i+1,#players do
                --��ʼ����������
                local player1_chairId = players[i].chairId
                local player2_chairId = players[j].chairId
                local player1_cards =  players[i].cards
                local player2_cards =  players[j].cards
                count_score[player1_chairId] =  count_score[player1_chairId] or {}
                count_score[player2_chairId] =  count_score[player2_chairId] or {}
                count_score[player1_chairId][index] = count_score[player1_chairId][index] or {}
                count_score[player2_chairId][index] = count_score[player2_chairId][index] or {}
                local compareResult = self:compare(players[i].cards[index],players[j].cards[index])

                local function is_extra( cards,index ) --�Ƿ����÷�
                    local extra = 0
                    local cardType =  self:get_card_type(cards)
                    if index == 1 then
                        if cardType == CARD_TYPE.SAN_TIAO then --����
                            extra = 2
                        end
                    elseif index == 2 then

                        if cardType == CARD_TYPE.HU_LU then --�жպ�«
                            extra = 1
                        elseif cardType == CARD_TYPE.TIE_ZHI then --��֧
                            extra = 6
                        elseif cardType == CARD_TYPE.TONG_HUA_SHUN then --ͬ��˳
                            extra = 8
                        end
                    elseif index == 3 then
                        if cardType == CARD_TYPE.TIE_ZHI then --��֧
                            extra = 3
                        elseif cardType == CARD_TYPE.TONG_HUA_SHUN then --ͬ��˳
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
                else --ƽ��
                    count_score[player2_chairId][index][player1_chairId] = {win = 0,extra = 0,shoot = 0,qld = 0}
                    count_score[player1_chairId][index][player2_chairId] = {win = 0,extra = 0,shoot = 0,qld = 0}
                end
                
            end
        end
    end
 
   

    --��ͨ���ͱȽ�
    local function compareNormal(players)
        bipaiResult.normal = {}
        bipaiResult.normal.sort_players = {}
        bipaiResult.normal.count_score = {}
        bipaiResult.normal.normal_players = {}


        for _,player in pairs(players) do
            table.insert(bipaiResult.normal.normal_players,player.chairId)
        end
        for i=1,3 do
            normal_sort(players,i,bipaiResult.normal.sort_players)
            count_score_func( players,i, bipaiResult.normal.count_score)
        end
    end

    --daqiang luoji
    local function shootLogic()
        bipaiResult.shoot ={}

        --�Ƚ������ƴ�С
        --Ĭ��player1 �� player2
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
                        bipaiResult.normal.count_score[shootId][round][get_shot_id].shoot = 1 --��ǹ
                        bipaiResult.normal.count_score[get_shot_id][round][shootId].shoot = -1 --����ǹ
                    end
                end
            end
        end
    end


    local function quanleidaLogic(  )
        if #normal_cards ~= 4 then return end --����4����ͨ���� ����ȫ�ݴ�
        for shootId,get_shot_ids in pairs(bipaiResult.shoot) do
            if #get_shot_ids == 3 then --��ǹ3�� �϶���ȫ�ݴ���
                for _,get_shot_id in ipairs(get_shot_ids) do
                    for round=1,3 do
                        bipaiResult.normal.count_score[shootId][round][get_shot_id].qld = 1 --ȫ�ݴ�
                        bipaiResult.normal.count_score[get_shot_id][round][shootId].qld = -1 --����
                    end
                end
                break
            end
        end
    end


    
    compareNormal(normal_cards)
    shootLogic()
    quanleidaLogic()
   
    local function count_score_special_func(  )
        for i= 1,#bipaiResult.special.sort_players do
            local player1 = bipaiResult.special.sort_players[i]
            local player1_chairId = player1.chairId
            local card_type1 = player1.type
            
            for _,player2 in ipairs(normal_cards) do
				local player2_chairId = player2.chairId
				bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
				bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}

				bipaiResult.special.count_score[player1_chairId][player2_chairId] = card_type1.win_fen
				bipaiResult.special.count_score[player2_chairId][player1_chairId] = -1*card_type1.win_fen
			end


			for j= i + 1,#bipaiResult.special.sort_players do
				local player2 = bipaiResult.special.sort_players[j]
				local player1_chairId = player1.chairId
				local player2_chairId = player2.chairId
				local card_type2 = player2.type

				if card_type1.index > card_type2.index then

					bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
					bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}
					bipaiResult.special.count_score[player1_chairId][player2_chairId] = card_type1.win_fen
					bipaiResult.special.count_score[player2_chairId][player1_chairId] = -1*card_type1.win_fen
				elseif card_type1.index < card_type2.index then
					bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
					bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}
					bipaiResult.special.count_score[player2_chairId][player1_chairId] = card_type2.win_fen
					bipaiResult.special.count_score[player1_chairId][player2_chairId] = -1*card_type2.win_fen
				else
					bipaiResult.special.count_score[player1_chairId] = bipaiResult.special.count_score[player1_chairId] or {}
					bipaiResult.special.count_score[player2_chairId] = bipaiResult.special.count_score[player2_chairId] or {}
					bipaiResult.special.count_score[player2_chairId][player1_chairId] = 0
					bipaiResult.special.count_score[player1_chairId][player2_chairId] = 0
				end
			end
		end
	end


       --����
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
        count_score_special_func()
        
    end

    compareSpecial(special_cards)
    return bipaiResult
end


function logic:balance_scores(player_cards)
	local function extra(type_cards,index )
		local c_type =  type_cards.type
		return (c_type.extra and c_type.extra[index]) and c_type.extra[index] or 0
    end

	local function type_cards_cmp_score(type_cards_l,type_cards_r)
		if #type_cards_l < #type_cards_r then return {{win = type_cards_l[1].type.win_fen,extra = 0}},{{win = -type_cards_l[1].type.win_fen,extra = 0}} end
		if #type_cards_l > #type_cards_r then return {{win = -type_cards_r[1].type.win_fen,extra = 0}},{{win = type_cards_r[1].type.win_fen,extra = 0}} end
		
		if #type_cards_l == 1 then 
			local cmp_res = self:compare_type(type_cards_l[1],type_cards_r[1])
			if cmp_res > 0 then
				return {{win = type_cards_l[1].type.win_fen,extra = 0}},{{win = -type_cards_l[1].type.win_fen,extra = 0}}
			elseif cmp_res < 0 then
				return {{win = -type_cards_r[1].type.win_fen,extra = 0}},{{win = type_cards_r[1].type.win_fen,extra = 0}}
			else
				return {{win = 0,extra = 0}},{{win = 0,extra = 0}}
			end
		end 

		local s_l = {}
		local s_r = {}
		for i = 1,3 do
			local cmp_res = self:compare_type(type_cards_l[i],type_cards_r[i])
			if cmp_res > 0 then
				local extra_l = extra(type_cards_l[i],i)
				s_l[i] = {win = type_cards_l[i].type.win_fen,extra = extra_l}
				s_r[i] = {win = -type_cards_l[i].type.win_fen,extra = -extra_l}
			elseif cmp_res < 0 then
				local extra_r = extra(type_cards_r[i],i)
				s_l[i] = {win = -type_cards_r[i].type.win_fen,extra = -extra_r}
				s_r[i] = {win = type_cards_r[i].type.win_fen,extra = extra_r}
			else
				s_l[i] = {win = 0,extra = 0}
				s_r[i] = {win = 0,extra = 0}
			end
		end

		return s_l,s_r
	end

	
    local function  caculate_scores(type_cards_ps)
		local cmp_ret_scores = table.agg(type_cards_ps,{},function(last_res,p,k) 
			last_res[p.chair_id] = {}
			table.walk(type_cards_ps,function(p1,k1)
				if p.chair_id ~= p1.chair_id then last_res[p.chair_id][p1.chair_id] = {normal = {},shoot = 0,special = {},qld = 0} end
			end)
			return last_res
		end)

        for i=1,#type_cards_ps do
            for j=i+1,#type_cards_ps do
				local chair_id_l = type_cards_ps[i].chair_id
				local chair_id_r = type_cards_ps[j].chair_id
                local cmp_res_l,cmp_res_r = type_cards_cmp_score(type_cards_ps[i].type_cards,type_cards_ps[j].type_cards)
				if #cmp_res_l == 1 then
					cmp_ret_scores[chair_id_l][chair_id_r].special = cmp_res_l
					cmp_ret_scores[chair_id_r][chair_id_l].special = cmp_res_r
				else
					cmp_ret_scores[chair_id_l][chair_id_r].normal = cmp_res_l
					cmp_ret_scores[chair_id_r][chair_id_l].normal = cmp_res_r
				end
            end
        end

		return cmp_ret_scores
    end
 
    local function caculate_flag_and_scores(p_type_cards)
		--���Ƶ÷����
		local cmp_scores = caculate_scores(p_type_cards)

		--��ǹ,ȫ�ݴ�
		table.walk(cmp_scores,function(s_l,k_l) 
			local shoot_count = table.agg(s_l,0,function(last_shoot_count,s_r,k_r)
				local win_dao_count = table.agg(s_r.normal,0,function(last,i_s,i_k)  
					return last + (i_s.win > 0 and 1 or (i_s.win < 0 and -1 or 0)) 
				end)
				if win_dao_count == 3 then 
					last_shoot_count = last_shoot_count + 1 
					s_r.shoot = s_r.shoot + 2
				elseif win_dao_count == -3 then
					s_r.shoot = s_r.shoot - 2
				end
				return last_shoot_count
			end)

			if shoot_count == 3 then
				table.walk(s_l,function(p_s,p_k)  p_s.qld = 2 end)
				table.walk(cmp_scores,function(p_s,p_k)  if k_l ~= p_k then p_s[k_l].qld = -2 end  end)
			end
		end)

		return cmp_scores
    end
	
	local type_cards = table.agg(player_cards,{},function(last_res,p,k)
		local p_type_cards = table.agg(p.cards,{},function(last_cards,cds,k) 
			table.push_back(last_cards,{type = self:get_card_type(cds),cards = cds}) 
			return last_cards
		end)
		table.push_back(last_res,{chair_id = p.chair_id,type_cards = p_type_cards})
		return last_res
	end)
	return caculate_flag_and_scores(type_cards)
end


function test()
	local table_cards = {}
	for i = 0, 3 do
		for j = 2,14 do
			table_cards[#table_cards + 1] = i * 15 + j
		end
	end

	local k = #table_cards
	local cards = {}
	for j=1,13 do
		local r = math.random(k)
		cards[#cards + 1] = table_cards[r]
		if r ~= k then 
			table_cards[r], table_cards[k] = table_cards[k], table_cards[r]
		end
		k = k - 1
	end
    
	--cards = {38,52,36,37,20,39,25,35,12,23,4,24,17}	--ͬ��+ͬ��˳
	--cards = {29,21,25,14,37,8,20,23,51,44,48,32,54}   -- β���к�«����ͬ����ѡ��ͬ�����?��/ͷ������
	--cards = {39,20,27,48,52,2,21,25,56,43,41,34,59}  -- special bug
	--cards = {8,9,10,11,2,3,4,5,6,7,12,13,14} --����
    --cards = {4,37,22,21,12,57,47,59,5,9,27,28,56} -- specialֻ��һ���������bug
	--cards = {4,41,29,8,19,26,18,9,32,6,39,22,5}	--special santonghua
--    cards = {17,23,25,32,35,36,40,42,48,49,52,56,58}
--    cards = {1,2,3,4,20, 21,22,23,39,40,41,57,58}
--	cards = {2,24,26,56,32,29,17,58,51,41,34,53,35}
    cards ={14,2,3,4,20, 22,23,39,40,26, 24,57,58}
	local l = logic:new()
    dump(l:compare({29,59,26,22,24},{14,44,47,27,28}))
--    cards_type = l:get_card_type(cards)
--    dump(cards_type)
--    local types = l:split_state_card(cards)
--    for k,v in pairs(types) do
--        dump(v)
--    end
end

--test()

return logic