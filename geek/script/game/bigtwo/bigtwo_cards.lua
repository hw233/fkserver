-- 斗地主出牌规则

local pb = require "pb_files"


local BT_Error = pb.enum("BIGTWO_CARD_TYPE", "BT_Error")
local BT_HIGH_CARD = pb.enum("BIGTWO_CARD_TYPE", "BT_HIGH_CARD")
local BT_ONE_PAIR = pb.enum("BIGTWO_CARD_TYPE", "BT_ONE_PAIR")
local BT_THREE_OF_A_KIND = pb.enum("BIGTWO_CARD_TYPE", "BT_THREE_OF_A_KIND")
local BT_STRAIGHT = pb.enum("BIGTWO_CARD_TYPE", "BT_STRAIGHT")
local BT_FLUSH = pb.enum("BIGTWO_CARD_TYPE", "BT_FLUSH")
local BT_FULL_HOUSE = pb.enum("BIGTWO_CARD_TYPE", "BT_FULL_HOUSE")
local BT_FOUR_OF_KIND = pb.enum("BIGTWO_CARD_TYPE", "BT_FOUR_OF_KIND")
local BT_STRAIT_FLUSH = pb.enum("BIGTWO_CARD_TYPE", "BT_STRAIT_FLUSH")


-- 得到牌大小
local function get_value(card)
	return math.floor(card / 4)
end
-- 0：方块3，1：梅花3，2：红桃3，3：黑桃3 …… 44：方块A, 45 梅花A, 46 红桃A, 47 黑桃A, 48：方块2，49：梅花2，50：红桃2，51：黑桃2，52：小王，53：大王

bigtwo_cards = {}

-- 创建
function bigtwo_cards:new()
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化
function bigtwo_cards:init(cards)
    self.cards_ = cards
    self.black_two = false
	self.score = 0
end
--设置黑桃二
function bigtwo_cards:SetBlackTwo()
	self.black_two = true
end
-- 获取
function bigtwo_cards:get_cards()	
    return self.cards_ 
end

-- 添加牌
function bigtwo_cards:add_cards(cards)
	for i,v in ipairs(cards) do
    	table.insert(self.cards_, v)
    end
end

-- 加炸弹
function bigtwo_cards:add_bomb_count()
	self.bomb_count_ = self.bomb_count_ + 1
end

-- 得到炸弹
function bigtwo_cards:get_bomb_count()
	return self.bomb_count_
end

-- 查找是否有拥有
function bigtwo_cards:find_card(card)
	for i,v in ipairs(self.cards_) do
		if v == card then
			return true
		end
	end
	return false
end

-- 删除牌
function bigtwo_cards:remove_card(card)
for i,v in ipairs(self.cards_) do
		if v == card then
			table.remove(self.cards_, i)
			return true
		end
	end
	return false
end

-- 检查牌是否合法
function bigtwo_cards:check_cards(cards)
	if not cards or #cards == 0 then
		return false
	end

	local set = {} -- 检查重复牌
	for i,v in ipairs(cards) do
		if v < 0 or v > 53 or set[v] then
			return false
		end

		if not self:find_card(v) then
			return false
		end

		set[v] = true
	end

	return true
end

-- 分析牌
function bigtwo_cards:analyseb_cards(cards)
	local ret = {{}, {}, {}, {}} -- 依次单，双，三，炸的数组
	local last_val = nil
	local i = 0

	for _, card in ipairs(cards) do
		local val = get_value(card)
		if last_val == val then
			i = i + 1
		else
			if i > 0 and i <= 4 then
				table.insert(ret[i], last_val)
			end
			last_val = val
			i = 1
		end
	end
	if i > 0 and i <= 4 then
		table.insert(ret[i], last_val)
	end
	return ret
end

function get_color(card)
	return card % 4
end

--顺子和同花
function special_get_card_type(cards)	
	--变量定义
	local checkpos = 5 --检查顺子的位置
	local bSamcolor = true
	local bLineCard = true
	local FirstColor = get_color(cards[1])
	local FirstValue = get_value(cards[1])
	local Move_Value = 0 --偏移量
	--判断是否有2
	if get_value(cards[5]) == 12 then
		--判断是否有A
		if get_value(cards[4]) == 11 then 
			checkpos = 3
		else
			checkpos = 4
		end
		Move_Value = 1
		FirstValue = -1
	end

	--牌形分析
	local begin = 0
	if checkpos ~= 5 then
		begin = 1
	else
		begin = 2
	end
	for i = begin,5 do
		--数据分析
		if get_color(cards[i]) ~= FirstColor then
			bSamcolor = false
		end
		if (FirstValue ~= get_value(cards[i]) + 1 - i - Move_Value) and (i <= checkpos)then
			bLineCard = false
		end

		--结束判断
		if bSamcolor == false and bLineCard == false then
			print("error type special_get_card_type")
			return nil
		end
	end
	--获取最大值和花色
	FirstColor = get_color(cards[5])
	FirstValue = get_value(cards[5])
    --有2存在
	if checkpos ~= 5 and bLineCard == true then
		FirstColor = get_color(cards[checkpos])
		FirstValue = get_value(cards[checkpos])
	end

	--顺子类型
	if bSamcolor == false and bLineCard == true then
		return BT_STRAIGHT, FirstValue, FirstColor, 5
	end
	--同花类型
	if bSamcolor == true and bLineCard == false then
		return BT_FLUSH, FirstValue, FirstColor, 5
	end
	--同花顺类型
	if bSamcolor == true and bLineCard == true then
		return BT_STRAIT_FLUSH, FirstValue, FirstColor, 5
	end	
	return nil
end

-- 得到牌类型
function bigtwo_cards:get_cards_type(cards)
	local count = #cards
	local color = nil
	if count == 1 then
		return BT_HIGH_CARD, get_value(cards[1]), get_color(cards[1]), 1 -- 单牌
	elseif count == 2 then
		if get_value(cards[1]) == get_value(cards[2]) then
			if get_color(cards[1]) > get_color(cards[2]) then
				color = get_color(cards[1])
			else
				color = get_color(cards[2])
			end
			return BT_ONE_PAIR, get_value(cards[1]), color, 2 -- 对牌
		end
		return nil
	elseif count == 3 then
		if get_value(cards[1]) == get_value(cards[2]) and get_value(cards[3]) == get_value(cards[2]) then
			return BT_THREE_OF_A_KIND, get_value(cards[1]), -1, 3 -- 三条
		end
		return nil
	elseif count == 5 then
		local ret = self:analyseb_cards(cards)
		-- 判断四带一
		if #ret[4] == 1 then
			return BT_FOUR_OF_KIND, ret[4][1], -1, 5 -- 四带一
		elseif #ret[3] == 1 and #ret[2] == 1 then-- 判断三带二			
			return BT_FULL_HOUSE, ret[3][1], -1, 5 -- 三带二
		else
			return special_get_card_type(cards)
		end	
	else
		return nil
	end
end

-- 比较牌
function bigtwo_cards:compare_cards(cur, last)
	print("bigtwo_cards  compare_cards")
	if cur.cards_val ~= nil then
		print(string.format("cur [%d,%d,%d]", cur.cards_type , cur.cards_color, cur.cards_val))
	else
		print(string.format("cur [%d,%d]", cur.cards_type , cur.cards_color))
	end
	if last ~= nil then
		print(string.format("last [%d,%d,%d]", last.cards_type , last.cards_color, last.cards_val))
	end
	if not last then
		return true
	end
	if cur.cards_count ~= last.cards_count then
		print(string.format("error count last.cards_type:%d,cur.cards_count:%d]", last.cards_count , cur.cards_count))
		return false
	end
	--比牌型
	if cur.cards_type > last.cards_type then
		return true
	elseif cur.cards_type == last.cards_type then
	--比点数
		if cur.cards_val > last.cards_val then
			return true
		elseif cur.cards_val == last.cards_val then
	    --比花色
	        if cur.cards_color > last.cards_color then
				return true
	        else
				return false
			end	        	
		else
			return false
		end
	else
		return false
	end
end

-- 出牌
function bigtwo_cards:out_cards(cards)
	print("remove_card: "..table.concat( cards, ", "))
	for i,v in ipairs(cards) do
		if v == 51 then--出黑桃二
			self.black_two = false
		end
		self:remove_card(v)
	end
	print(string.format("card_count[%d],cards[%s]",#self.cards_ , table.concat( self.cards_, ", ")))
	return #self.cards_ > 0
end

function bigtwo_cards:get_score()
	local n = #self.cards_
	if n == 13 then
		self.score = n * 4
	elseif n >= 10 then
		self.score = n * 3
	elseif n >= 8 then
		self.score = n * 2
	else
		self.score = n
	end
	if self.black_two then
		self.score = self.score * 2
	end
	print("xxxxxxxxxxxxxxxxxxxxx", self.score )
end

--迭代器
function pairsByKeys(t)      
    local a = {}      
    for n in pairs(t) do          
        a[#a+1] = n      
    end      
    table.sort(a)      
    local i = 0      
    return function()          
    i = i + 1          
    return a[i], t[a[i]]      
    end  
end

--查找更大牌型
function bigtwo_cards:get_out_card(cards_type, cards_color, cards_val, sequence_cards)	
	local out_card_list = {}
	local out_card_find = nil
	if sequence_cards == nil and cards_type ~= BT_HIGH_CARD then
		sequence_cards = {}	
	    for _,v in ipairs(self.cards_) do
	        local value = get_value(v)
	        sequence_cards[value] = sequence_cards[value] or {}
	        table.insert(sequence_cards[value],v)
	        sequence_cards[value].key = value
	    end	    
	end

	if cards_type == BT_HIGH_CARD then					--单牌类型		
    	for k,v in pairs(self.cards_) do
    		if get_value(v) == cards_val and get_color(v) >  cards_color then
    			table.insert(out_card_list, v)
    			return out_card_list
    		elseif get_value(v) > cards_val then
    			table.insert(out_card_list, v)
    			return out_card_list
    		end
    	end
    	return nil
	elseif cards_type == BT_ONE_PAIR then						--对子类型
		if #self.cards_ < 2 then
			return nil
		end
		local split_cards = nil --拆分队列
	    for k,v in pairsByKeys(sequence_cards) do
	    	print("BT_ONE_PAIR-----------v:", k, #v)
	        if #v == 2 then
	            if k == cards_val then --找到相等的对子 判断花色
	            	for x,y in ipairs(v) do
	            		if get_color(y) > cards_color then
    						return v
	            		end
	            	end
	            elseif k > cards_val then
					return v
	            end
	        elseif split_cards == nil and #v > 2 and  k >= cards_val then
	        		split_cards = {}
					table.insert(split_cards, v[1])
					table.insert(split_cards, v[2])
	        end
	    end
	    if split_cards ~= nil then
	    	return split_cards
	    end
    	return nil
	elseif cards_type == BT_THREE_OF_A_KIND then					--三条类型
		if #self.cards_ < 3 then
			return nil
		end

		local split_cards = nil --拆分队列
	    for k,v in pairsByKeys(sequence_cards) do
	    	print("BT_THREE_OF_A_KIND-----------v:", k, #v)
	        if #v == 3 then
	            if  k > cards_val then
					return v
	            end
	        elseif split_cards == nil and #v > 3 and  k >= cards_val then
	        		split_cards = {}
					table.insert(split_cards, v[1])
					table.insert(split_cards, v[2])
					table.insert(split_cards, v[3])
	        end
	    end
	    if split_cards ~= nil then
	    	return split_cards
	    end
    	return nil
	elseif cards_type == BT_STRAIGHT then				--顺子类型
		if #self.cards_ < 5 then
			return nil
		end

		local cards_num = #self.cards_
		local bspecial = 0   	--是否特殊牌形
		local last_num = 0      --顺子起始位置
		local line_num = 0      --顺子长度
		local split_cards = nil --拆分队列
		local bfind  = false	--是否找到
		local find_index = 1    --花色索引
		local beg_in = 0		--开始位置
		local end_in = 0		--结束位置

		if cards_val <= 2 then        --当为A2345时			
			if sequence_cards[11] ~= nil and sequence_cards[12] ~= nil then
				last_num = -2
				line_num = 2
				bspecial = 11
				cards_num = cards_num - 1
			elseif sequence_cards[12] ~= nil then
				last_num = -1
				line_num = 1
				bspecial = 12
				cards_num = cards_num - 1
			end
		elseif cards_val <= 3 and sequence_cards[12] ~= nil then     --当为23456时
				last_num = -1
				line_num = 1
				bspecial = 12
				cards_num = cards_num - 1
		end

	    for k,v in pairsByKeys(sequence_cards) do
	    	if cards_num + line_num < 5 then --剩余数+牌数小于5
	    		print ("--lost card < 5", cards_num, line_num)
	    		break
	    	else	    		
				cards_num = cards_num - 1
	    	end
	    	if k < 12 then --顺子2不能做最大值
		    	if line_num == 0 then
		    		last_num = k
		    		line_num = 1
		    	else--非初始判断
		    		if last_num + line_num ~= k then
		    			line_num = 1
		    			last_num = k
		    			if bspecial ~= 0 then
		    				bspecial = 0
		    			end
		    		else--如果k为下一顺值
		    			line_num = line_num + 1
		    			if line_num == 5 then --判断值
		    				if k == cards_val then --相等判断花色	    					
				            	for x,y in ipairs(v) do
				            		if get_color(y) > cards_color then
			    						bfind = true
			    						find_index = x
			    						break
				            		end
				            	end
		    				elseif k > cards_val then	    					
	    						bfind = true
		    				end

		    				if bfind == true then
		    					--找到，返回值
		    					out_card_list = {}
		    					end_in = k
		    					if bspecial == 11 then 
		    						beg_in = 0
		    						line_num = 3
	    							table.insert(out_card_list, sequence_cards[11][1])
	    							table.insert(out_card_list, sequence_cards[12][1])
		    					elseif bspecial == 12 then
		    						beg_in = 0
		    						line_num = 4
	    							table.insert(out_card_list, sequence_cards[12][1])
		    					else
		    						beg_in = k - 4
		    					end
								for i = beg_in, end_in do
									if beg_in ~= end_in then
    									table.insert(out_card_list, sequence_cards[i][1])
    								else
    									table.insert(out_card_list, sequence_cards[i][find_index])
    								end
    								line_num = line_num - 1
    								if line_num == 0 then
    									break
    								end
    							end
		    					return out_card_list
		    				else
		    					--顺子找到，但不大于相比值，找下一顺子
		    					line_num = 4 
		    					last_num = last_num + 1
		    					if bspecial == 11 then
		    						bspecial = 12
		    					elseif bspecial == 12 then
		    						bspecial = 0
		    					end
		    				end
		    			end
		    		end
		    	end
		    end
	    end
	elseif cards_type == BT_FLUSH then					--同花类型
		if #self.cards_ < 5 then
			return nil
		end

		local lost_value = 0
		local lost_color = 0

   		local color_list = {{},{},{},}    --花色
	    color_list[0] = {}
	    for _,v in ipairs(self.cards_) do
	        local value = get_color(v)
	        table.insert(color_list[value], v)
	    end

	    for k, v in pairs(color_list) do
	        table.sort(v,function(a,b) return a < b end)
	        if #v >= 5 then
	            for x = 5, #v do
	                if (get_value(v[x]) > cards_val) or (get_value(v[x]) == cards_val and k > cards_color) then
	                	local bchange = false
	                	if out_card_find == nil then
	                		bchange = true
	                	else
	                		--查找最小同花
	                		if (lost_value > get_value(v[x])) or (lost_value == get_value(v[x] and k < lost_color)) then
	                			bchange = true
	                		end
	                	end
	                	if bchange == true then
	                		out_card_list = {}
	                		out_card_find = 1
	                		for i = x - 4, x do
	    						table.insert(out_card_list, v[i])
	                		end
	                		lost_value = get_value(v[x])
	                		lost_color = k
	                	end
	                	--不需要再向上找
	                    break
	                end
	            end
	        end
	    end
	    if out_card_find ~= nil then
	    	return out_card_list
	    end
	elseif cards_type == BT_FULL_HOUSE then					--葫芦类型
		if #self.cards_ < 5 then
			return nil
		end
		local vice_in = nil       --对子位置
		local vice_num = 0        --折分对子数量
		local A_max_in = nil      --主牌索引
		local B_max_in = nil      --主牌索引 拆分
	    for k,v in pairsByKeys(sequence_cards) do
	    	--查找 三张的位置	  
	    	local bGetValue = false -- 本轮进行过赋值  	
	        if #v == 3 and A_max_in == nil then
	            if k > cards_val then 
	            	A_max_in = k
	            	bGetValue = true
	            end
	        elseif #v > 3 and B_max_in == nil then
	            if k > cards_val then 
	            	B_max_in = k
	            	bGetValue = true
	            end
	        end
	    	--查找 对子的位置
	        if bGetValue ~= true then
	        	if  #v >= 2 and (vice_in == nil or vice_num > #v)  then
        			vice_in = k
        			vice_num = #v
		        end
	        end
	    end

	    local f_max_in = nil
	    local f_vice_in = nil
	    if A_max_in ~= nil then
	    --主体不拆
	    	f_max_in = A_max_in
	    	if vice_in ~= nil then
	    		f_vice_in = vice_in
	    	elseif B_max_in ~= nil then
	    		f_vice_in = B_max_in
	    	end
	    elseif B_max_in ~= nil then
	    --主体要拆
	    	f_max_in = B_max_in
	    	if vice_in ~= nil then
	    		f_vice_in = vice_in
	    	end
	    end
	    --组合完成，赋值
	    if f_max_in ~= nil and f_vice_in ~= nil then
	    	for i = 1, 3 do 
	    		table.insert(out_card_list, sequence_cards[f_max_in][i])
	    	end
	    	for i = 1, 2 do 
	    		table.insert(out_card_list, sequence_cards[f_vice_in][i])
	    	end
	    	return out_card_list
	    end

	elseif cards_type == BT_FOUR_OF_KIND then						--四条类型
		if #self.cards_ < 5 then
			return nil
		end

		local vice_in = nil       --对子位置
		local vice_num = 0        --折分对子数量
		local max_in = nil      --主牌索引
	    for k,v in pairsByKeys(sequence_cards) do
	    	--查找 四张的位置	  
	    	local bGetValue = false -- 本轮进行过赋值  	
	        if #v == 4 and A_max_in == nil then
	            if k > cards_val then 
	            	max_in = k
	            	bGetValue = true
	            end
	        end
	    	--查找 对子的位置
	        if bGetValue ~= true then
	        	if  vice_in == nil or vice_num > #v  then
        			vice_in = k
        			vice_num = #v
		        end
	        end
	    end

	    --组合完成，赋值
	    if max_in ~= nil and vice_in ~= nil then
	    	for i = 1, 4 do 
	    		table.insert(out_card_list, sequence_cards[max_in][i])
	    	end
	    	table.insert(out_card_list, sequence_cards[vice_in][1])
	    	return out_card_list
	    end

	elseif cards_type == BT_STRAIT_FLUSH then						--同花顺型
		if #self.cards_ < 5 then
			return nil
		end

		local lost_value = 0
		local lost_color = 0

		local color_list = {{},{},{},}    --花色
   		local value_list = {{},{},{},} 
	    color_list[0] = {}
	    value_list[0] = {}
	    for _,v in ipairs(self.cards_) do
	        local color_ = get_color(v)
	        local value_ = get_value(v)
	        table.insert(color_list[color_], v)
	        value_list[color_][value_] = v
	    end

	    for k, v in pairs(color_list) do
	        table.sort(v,function(a,b) return a < b end)
	        if #v >= 5 then

				local cards_num = #v
				local bspecial = 0   	--是否特殊牌形
				local last_num = 0      --顺子起始位置
				local line_num = 0      --顺子长度
				local split_cards = nil --拆分队列
				local find_index = 1    --花色索引
				local beg_in = 0		--开始位置
				local end_in = 0		--结束位置

				if cards_val <= 2 then        --当为A2345时			
					if value_list[k][11] ~= nil and value_list[k][12] ~= nil then
						last_num = -2
						line_num = 2
						bspecial = 11
						cards_num = cards_num - 1
					elseif value_list[k][12] ~= nil then
						last_num = -1
						line_num = 1
						bspecial = 12
						cards_num = cards_num - 1
					end
				elseif cards_val <= 3 and value_list[k][12] ~= nil then     --当为23456时
						last_num = -1
						line_num = 1
						bspecial = 12
						cards_num = cards_num - 1
				end

				for _, t in ipairs(v) do
	        	local temp_cards_list = {}
				local bfind  = false	--是否找到					
			    	if cards_num + line_num < 5 then --剩余数+牌数小于5
			    		print ("--lost card < 5", cards_num, line_num)
			    		break
			    	else		    		
						cards_num = cards_num - 1
			    	end    
			    	local t_v = get_value(t)
			    	if t_v < 12 then
			    		if line_num == 0 then
				    		last_num = t_v
				    		line_num = 1
				    	else--非初始判断
				    		if last_num + line_num ~= t_v then
				    			line_num = 1
				    			last_num = t_v
				    			if bspecial ~= 0 then
				    				bspecial = 0
				    			end
				    		else--如果k为下一顺值
				    			line_num = line_num + 1
				    			if line_num == 5 then --判断值
				    				if t_v == cards_val and k > cards_color then --相等判断花色
			    						bfind = true
				    				elseif t_v > cards_val then    					
			    						bfind = true
				    				end					    				

				    				if bfind == true then
				    					--找到，返回值
				    					end_in = _
				    					beg_in = 1
				    					if bspecial == 11 then 
				    						line_num = 3
			    							table.insert(temp_cards_list, value_list[k][11])
			    							table.insert(temp_cards_list, value_list[k][12])
				    					elseif bspecial == 12 then
				    						line_num = 4
			    							table.insert(temp_cards_list, value_list[k][12])
				    					else
				    						beg_in = _ - 4
				    					end
				    					print("t h :",beg_in, end_in)
										for i = beg_in, end_in do
		    								table.insert(temp_cards_list, v[i])
		    								line_num = line_num - 1
		    								if line_num == 0 then
		    									break
		    								end
		    							end

		    							if (out_card_find == nil) or (t_v == lost_value and k < lost_color) or (t_v < lost_value) then
		    								print("lost:", lost_value, lost_color, t_v, k )
		    								out_card_find = 1
		    								out_card_list = temp_cards_list
											lost_value = t_v
											lost_color = k
		    							end
				    				else
				    					--顺子找到，但不大于相比值，找下一顺子
				    					line_num = 4 
				    					last_num = last_num + 1
				    					if bspecial == 11 then
				    						bspecial = 12
				    					elseif bspecial == 12 then
				    						bspecial = 0
				    					end
				    				end
				    			end
				    		end
				    	end
			    	end

				end

	        end
	    end
	    if out_card_find ~= nil then
	    	return out_card_list
	    end
	else
		--无类型
		return nil
	end
	return self:get_out_card(cards_type + 1, -1, -1, sequence_cards)	
end