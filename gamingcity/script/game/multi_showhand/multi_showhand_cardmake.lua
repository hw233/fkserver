
require "data.multi_showhand_data"
local multi_showhand_card_rate = multi_showhand_card_rate

local random = require "random"

local multi_showhand_cardmake = {}

local multi_showhand_cards = {}

--校验牌型
function veryfy_cards(cards)
	-- body
	local this_cards = {}
	for i,v in ipairs(cards) do
		for _,z in ipairs(v) do
			table.insert(this_cards,z)
		end
	end	
	table.sort(this_cards, function(a, b) return a < b end)
	
	if #this_cards < 10 then
		return false
	end

	local cards_veryfy = {}
	for i,v in ipairs(this_cards) do
		if v < 25 or v > 52 then
			return false
		end

		if not cards_veryfy[v] then
			cards_veryfy[v] = 1
		else
			return false
		end
	end
	return true
end

-- 存储原始cards ,cards必须有序
function multi_showhand_cardmake.init_cards(cards)
	-- body
	multi_showhand_cards = {}
	for i,v in ipairs(cards) do
		table.insert(multi_showhand_cards,v)
	end
end

--转为二维数组便于计算 
function multi_showhand_cardmake.create_my_cards()
	-- body
	local mycards = {}
	for i,v in ipairs(multi_showhand_cards) do
		-- 得到牌花色1-4
		local color = (v-1) % 4 + 1

		if not mycards[color] then
			mycards[color] = {}
		end
		table.insert(mycards[color],v)
	end
	return mycards
end

function multi_showhand_cardmake.need_make_card()
	-- body
	--概率等于基础概率加上浮动概率
	local rate = multi_showhand_card_rate.base_rate + random.boost_integer(0,multi_showhand_card_rate.float_rate)
	if random.boost_integer(1,100) <= rate then
		--print("make card---------------------->")
		return true
	end
	return false
end


function multi_showhand_cardmake.make_cards(player_count)
	
	local make_success = true
	local players_cards = {}
	local mycards = multi_showhand_cardmake.create_my_cards()
	local good_cards_num = 2
	if player_count > 2 then
		good_cards_num = random.boost_integer(1,2) + 2 --随机2~3个好牌
	end 

	for i=1,good_cards_num do
		local success,player_cards = multi_showhand_cardmake.do_make_cards(mycards)
		if success then
			--换2张牌，混淆一下
			local x = random.boost(#player_cards)
			local y = random.boost(#player_cards)
			if x ~= y then
				player_cards[x], player_cards[y] = player_cards[y], player_cards[x]
			end

			table.insert(players_cards,player_cards)
		else
			make_success = false
		end
	end

	local left_cards = {}
	local left_cards_num = 0
	for i,v in ipairs(mycards) do
		for _,z in ipairs(v) do
			if z ~= 0 then
				table.insert(left_cards,z)
				left_cards_num = left_cards_num + 1
			end
		end
	end	

		--每局总共做随机2~3首好牌,剩下2首随机洗牌
	local left_player_num = player_count - good_cards_num
	if left_player_num > 0 then
		local k = left_cards_num
		for i=1,left_player_num do
			local left_player_cards = {}
			-- 洗牌
			for j=1,5 do
				local r = random.boost(k)
				left_player_cards[j] = left_cards[r]
				if r ~= k then
					left_cards[r], left_cards[k] = left_cards[k], left_cards[r]
				end
				k = k-1
			end
			table.insert(players_cards,left_player_cards)
		end
	end
	
	local veryfy_ret = veryfy_cards(players_cards)

	if veryfy_ret == false then
		print("veryfy failed------------>")
		make_success = false
	end

	if make_success == true and player_count > 2 then
		--打乱顺序
		local len = #players_cards
		for i=1,len do
			local x = random.boost_integer(1,len)
			local y = random.boost_integer(1,len)
			if x ~= y then
				players_cards[x], players_cards[y] = players_cards[y], players_cards[x]
			end
			len = len - 1
		end
	end

	return make_success,players_cards

end

function multi_showhand_cardmake.set_card_rate(card_rate)
	-- body
	multi_showhand_card_rate = card_rate
end

function multi_showhand_cardmake.do_make_cards(mycards)

	local card_rates = {
	{rate = multi_showhand_card_rate.rate_tonghua_shun, func = multi_showhand_cardmake.make_tonghua_shun},
	{rate = multi_showhand_card_rate.rate_four,         func = multi_showhand_cardmake.make_four},
	{rate = multi_showhand_card_rate.rate_hulu,         func = multi_showhand_cardmake.make_hulu},
	{rate = multi_showhand_card_rate.rate_tonghua,      func = multi_showhand_cardmake.make_tonghua},
	{rate = multi_showhand_card_rate.rate_shunzi,       func = multi_showhand_cardmake.make_shunzi},
	{rate = multi_showhand_card_rate.rate_three,        func = multi_showhand_cardmake.make_three},
	{rate = multi_showhand_card_rate.rate_double_two,   func = multi_showhand_cardmake.make_double_two},
	{rate = multi_showhand_card_rate.rate_double,       func = multi_showhand_cardmake.make_double}
	}

	for i,v in ipairs(card_rates) do
		if random.boost_integer(1,100) <= v.rate then
			local make_success, player_cards = v.func(mycards)
			if make_success then
				return make_success,player_cards 
			end
		end
	end

	return false,nil
end


--找出一张牌,可能已经被抽出
function get_random_card(mycards,start_idnex,end_index)
	-- body
	--随机一种花色
	local color = random.boost_integer(1,4)
	--随机找一张牌
	local card_index = random.boost_integer(start_idnex,end_index)

	local color_size = #mycards
	local card_size = end_index - start_idnex + 1

	for i=1,color_size * card_size do
		if mycards[color][card_index] > 0 then
			return color,card_index
		end

		card_index = card_index + 1

		if card_index > end_index then
			card_index = start_idnex
			color = color + 1
			if color > color_size then
				color = 1
			end
		end
	end
	print("can not find card---------------------")
	return color,card_index
end

--某张牌剩余数量
function  get_card_count(mycards,card_index)
	-- body
	local count = 0
	for color=1,4 do
		if mycards[color][card_index] > 0 then
			count = count + 1
		end
	end
	return count
end

--将牌从src_cards移动到dest_cards
function move_card_by_index_color(dest_cards,src_cards,card_index,color)
	-- body
	if src_cards[color][card_index] > 0 then
		table.insert(dest_cards,src_cards[color][card_index] )
		src_cards[color][card_index] = 0
		return true
	end
	return false
end


--将一定数量的牌从src_cards移动到dest_cards
function move_cards_by_index_count(dest_cards,src_cards,card_index,move_count)
	-- body
	local count = 0
	for color=1,4 do
		if move_card_by_index_color(dest_cards,src_cards,card_index,color) then
			count = count + 1
			if count >= move_count then
				return true
			end
		end
	end
	return false
end


function  multi_showhand_cardmake.make_tonghua_shun(mycards)
	-- body
	local player_cards = {}

	--随机找一张牌，最后4张牌不能找
	local color,card_index = get_random_card(mycards,1,#mycards[1] - 4)

	local count = 0
	--判断5张连续的牌还在
	for j=card_index,card_index + 4  do
		--这张牌存在
		if mycards[color][j] > 0 then
			count = count + 1
		end
	end
		
	--找到了
	if count == 5 then
		for j=card_index,card_index + 4 do
			move_card_by_index_color(player_cards,mycards,j,color)
		end
		return true,player_cards
	end

	return false,nil
end

function  multi_showhand_cardmake.make_four(mycards)
	-- body
	local player_cards = {}

	--随机找两张牌
	local color,card_index   = get_random_card(mycards,1,#mycards[1])
	local color_another,card_another = get_random_card(mycards,1,#mycards[1])

	--两张牌相同 或者单张牌不存在
	if card_index == card_another or mycards[color_another][card_another] == 0 then
		return false,nil
	end

	local count = get_card_count(mycards,card_index)

	--4种花色都存在
	if count == 4 then
		move_cards_by_index_count(player_cards,mycards,card_index,4)
		move_card_by_index_color(player_cards,mycards,card_another,color_another)
		return true,player_cards
	end

	return false,nil
end

function  multi_showhand_cardmake.make_hulu(mycards)
	-- body
	local player_cards = {}
	--随机找两张牌
	local color_three,card_index_three = get_random_card(mycards,1,#mycards[1])
	local color_two,  card_index_two   = get_random_card(mycards,1,#mycards[1])

	if card_index_three == card_index_two then
		return false,nil
	end

	local count1 =  get_card_count(mycards,card_index_three)
	local count2 =  get_card_count(mycards,card_index_two)

	--存在
	if count1 >= 3 and count2 >= 2 then

		move_cards_by_index_count(player_cards,mycards,card_index_three,3)
		move_cards_by_index_count(player_cards,mycards,card_index_two,2)

		return true,player_cards 
	end

	return false,nil
end

function  multi_showhand_cardmake.make_tonghua(mycards)
	-- body
	local player_cards = {}

	--随机一种花色
	local color_ = random.boost_integer(1,4)
	local cards = {}

	--找出所有存在的牌
	for j,v in ipairs(mycards[color_]) do
		if v > 0 then
			table.insert(cards,{
				color = color_,
				card_index = j
				})
		end
	end

	local len = #cards

	if len < 5 then
		return false,nil
	end
	
	for j=1,5 do
		local r = random.boost(len)

		move_card_by_index_color(player_cards,mycards,cards[r].card_index,cards[r].color)
		if r ~= len then
			cards[r], cards[len] = cards[len], cards[r]
		end
		len = len-1
	end	

	return true,player_cards 
end

function  multi_showhand_cardmake.make_shunzi(mycards)
	-- body
	local player_cards = {}

	--随机找一张牌，最后4张牌不能找
	local color_,card_index = get_random_card(mycards,1,#mycards[1] - 4)

	local cards = {}
	for j=card_index,card_index+4 do
		--这张牌存在
		if mycards[color_][j] > 0 then
			table.insert(cards,{
				color = color_,
				card_index = j
				})
		end

		color_ = random.boost_integer(1,4)
	end

	if #cards == 5 then
		for i,v in ipairs(cards) do
			move_card_by_index_color(player_cards,mycards,v.card_index,v.color)
		end
		return true,player_cards 
	end

	return false,nil
end

function  multi_showhand_cardmake.make_three(mycards)
	-- body
	local player_cards = {}
	--随机找三张牌
	local color_three,card_index_three = get_random_card(mycards,1,#mycards[1])
	local color_another1,card_another1 = get_random_card(mycards,1,#mycards[1])
	local color_another2,card_another2 = get_random_card(mycards,1,#mycards[1])

	if card_index_three == card_another1 or  card_index_three == card_another2 or card_another1 == card_another2 then
		return false,nil
	end

	local count1 =  get_card_count(mycards,card_index_three)
	local count2 =  get_card_count(mycards,card_another1)
	local count3 =  get_card_count(mycards,card_another2)

	--存在
	if count1 >= 3 and count2 >= 1 and count3 >= 1  then

		move_cards_by_index_count(player_cards,mycards,card_index_three,3)
		move_cards_by_index_count(player_cards,mycards,card_another1,1)
		move_cards_by_index_count(player_cards,mycards,card_another2,1)

		return true,player_cards 
	end

	return false,nil
end

function  multi_showhand_cardmake.make_double_two(mycards)
	-- body
	local player_cards = {}

	--随机找三张牌
	local color_double1,card_index_double1 = get_random_card(mycards,1,#mycards[1])
	local color_double2,card_index_double2 = get_random_card(mycards,1,#mycards[1])
	local color_another,card_another = get_random_card(mycards,1,#mycards[1])

	if card_index_double1 == card_index_double2 or  card_index_double1 == card_another or card_index_double2 == card_another then
		return false,nil
	end

	local count1 =  get_card_count(mycards,card_index_double1)
	local count2 =  get_card_count(mycards,card_index_double2)
	local count3 =  get_card_count(mycards,card_another)

	--存在
	if count1 >= 2 and count2 >= 2 and count3 >= 1  then

		move_cards_by_index_count(player_cards,mycards,card_index_double1,2)
		move_cards_by_index_count(player_cards,mycards,card_index_double2,2)
		move_cards_by_index_count(player_cards,mycards,card_another,1)

		return true,player_cards 
	end

	return false,nil
end

function  multi_showhand_cardmake.make_double(mycards)
	-- body
	local player_cards = {}
	--随机找一张牌
	local color_double,card_index_double = get_random_card(mycards,1,#mycards[1])

	local count1 =  get_card_count(mycards,card_index_double)

	if count1 < 2 then
		return false,nil
	end
	move_cards_by_index_count(player_cards,mycards,card_index_double,2)

	for i=1,3 do
		local color_another,card_another = get_random_card(mycards,1,#mycards[1])
		move_card_by_index_color(player_cards,mycards,card_another,color_another)
	end
	
	return true,player_cards
end


return multi_showhand_cardmake
