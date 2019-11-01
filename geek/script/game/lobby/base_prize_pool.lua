-- game room

local pb = require "pb_files"
require "functions"
local random = require "random"
require "game.net_func"
local base_player = require "game.lobby.base_player"
require "data.prize_pool_robot_name"
require "table_func"
local log = require "log"
local redisopt = require "redisopt"
local json = require "cjson"

local base_prize_pool = {}

local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

function base_prize_pool:new()  
    local o = {}
    setmetatable(o, {__index = self})
    self:prize_pool_init()
    return o 
end

--奖池系统
function base_prize_pool:prize_pool_init()
	local str = '{"open":0,"time_start":0,"time_end":0,"pool_origin":1,"pool_prize":10,"pool_max":5,"pool_lucky":0.5,"bet_add":5,"prize_count":100,"prize_limit":47900,"showpool_add":70,"showpool_sub":30,"showpool_add_min":100,"showpool_add_max":5000,"showpool_sub_min":300,"showpool_sub_max":1000,"showpool_led":25,"robot_time":300}'
	self.prizepool = {pool = 0,show = 0,count = 0,prize = 0}
	self.prizepool_show_time = get_second_time() + 3
	self.prizepool_cfg = json.decode(str)
	self.prizepool.show = random.boost_integer(10000,100000)
	self.prizepool_led = {}
	if not self.player_list then
		self.player_list = {}
	end
	self.run_flag = false
	self.player_bet_info = {}
	self.robot_name = {}
	self.robot_name_time = {}
	self.game_log_id = {}
	self.log_money_type = def_first_game_type * 1000 + def_second_game_type
	if prize_pool_robot_name and type(prize_pool_robot_name) == "table" and 
		prize_pool_robot_name[def_first_game_type] and type(prize_pool_robot_name[def_first_game_type]) and 
		prize_pool_robot_name[def_first_game_type][def_second_game_type] and 
		type(prize_pool_robot_name[def_first_game_type][def_second_game_type])  == "table" then
		self.robot_name = prize_pool_robot_name[def_first_game_type][def_second_game_type]
	end
end


--是否开放
function base_prize_pool:prize_pool_is_open()
	if self.prizepool_cfg.open == 1 then
		local now = get_second_time()
		--log.info("start[%d] end[%d] now[%d]" , self.prizepool_cfg.time_start , self.prizepool_cfg.time_end  , now)
		if self.prizepool_cfg.time_start < now and now < self.prizepool_cfg.time_end then
			self.run_flag = true
			return true
		elseif self.run_flag then
			self.run_flag = false

			log.info("prize_pool_is_open =============================== %s",self.player_list)
			for room_id , room in pairs(self.player_list) do
				log.info("roooid [%d] ============== prize pool close table_count[%d]" , room_id,getNum(room))
				for table_id , _ in pairs(room) do
					log.info("room_id[%d] table[%d] send SC_PrizePool_show = 0 ",room_id , table_id)
					self:broadcast2client(room_id , table_id, "SC_PrizePool_show",{money = 0})
				end
			end


		end
	end
	return false
end

--更新奖池
function base_prize_pool:prize_pool_show(room_id ,table_id)
	if self:prize_pool_is_open() == false then
		return
	end
	if get_second_time() < self.prizepool_show_time then
		return
	end
	self.prizepool_show_time = get_second_time() + 3
	local show_ra = random.boost_integer(1,100)
	if show_ra < self.prizepool_cfg.showpool_add and self.prizepool.show < 100000000 then
		self.prizepool.show = self.prizepool.show + random.boost_integer(self.prizepool_cfg.showpool_add_min,self.prizepool_cfg.showpool_add_max)
	elseif show_ra >= self.prizepool_cfg.showpool_add and show_ra < self.prizepool_cfg.showpool_sub + self.prizepool_cfg.showpool_add then
		self.prizepool.show = self.prizepool.show - random.boost_integer(self.prizepool_cfg.showpool_sub_min,self.prizepool_cfg.showpool_sub_max)
	end

	if self.prizepool.show < 0 then
		self.prizepool.show = 0
	end
	--通知更新奖池
	log.info("============SC_PrizePool_show room_id[%d] table_id[%d] [%d]",room_id , table_id,self.prizepool.show)
	self:broadcast2client(room_id , table_id , "SC_PrizePool_show",{money = self.prizepool.show})
end

-- 广播桌子中所有人消息
function base_prize_pool:broadcast2client(room_id , table_id, msg_name, pb)
	if not self.player_list[room_id] then
		log.info("no ======== room_id")
		return
	end
	if not self.player_list[room_id][table_id] then
		log.info("no ======== table_id")
		return
	end
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in pairs(self.player_list[room_id][table_id] ) do
		if p and type(p) == "table" then
			log.info("============send guid[%d]",p.guid)
			send2client_pb(p,msg_name,pb)
		end
	end
end

--计算参与的玩家
function base_prize_pool:prize_pool_players(table_id)
	if self:prize_pool_is_open() == false then
		return {}
	end
	if not self.player_bet_info[table_id] then
		return {}
	end
	local users = {}
	for guid,v in pairs(self.player_bet_info[table_id]) do
		if v.player and v.bet > 0 and v.player.is_guest == false then
			local ra = self.prizepool_cfg.bet_add * (v.bet / 100000)
			if ra > self.prizepool_cfg.bet_add then
				ra = self.prizepool_cfg.bet_add
			end
			ra = ra + self.prizepool_cfg.pool_lucky
			users[guid] = ra
		end
	end

	return users
end

--抽奖
function base_prize_pool:prize_pool_game(users,money,gamelog)
	if self:prize_pool_is_open() == false then
		return {}
	end
	gamelog.prizepool = 0
	gamelog.prizemoney = 0
	gamelog.prizeusers = {}
	local luckyusers = {}
	--增加实际奖池
	if money > 0 and self.prizepool.pool + money < self.prizepool_cfg.pool_max * self.prizepool_cfg.prize_limit then
		self.prizepool.pool = self.prizepool.pool + math.ceil(money * self.prizepool_cfg.pool_origin / 100)
		if self.prizepool.pool > self.prizepool_cfg.pool_max * self.prizepool_cfg.prize_limit then
			self.prizepool.pool = self.prizepool_cfg.pool_max * self.prizepool_cfg.prize_limit
		end
	end
	--检查是否已达发奖上限
	if self.prizepool.prize >= self.prizepool_cfg.prize_limit then
		if random.boost_integer(1,100) < self.prizepool_cfg.showpool_led then
			--机器人中间LED
			local money = math.ceil(self.prizepool.pool * self.prizepool_cfg.pool_prize / 100)
			if money > 100 then
				local nickname = self.robot_name[random.boost_integer(1,#self.robot_name)]
				local nickname_time = self.robot_name_time[nickname]
				if (nickname_time and nickname_time - self.prizepool_cfg.robot_time > get_second_time()) or not nickname_time then
					self.robot_name_time[nickname] = get_second_time()
					table.insert(self.prizepool_led,{ nickname = nickname ,money = money / 100})
				end
			end
		end
	else
		for k,v in pairs(users) do
			if random.boost_integer(1,100) < v and self.prizepool.prize < self.prizepool_cfg.prize_limit then
				local prize = math.ceil(self.prizepool.pool * self.prizepool_cfg.pool_prize / 100)
				self.prizepool.prize = self.prizepool.prize + prize
				self.prizepool.pool = self.prizepool.pool - prize
				--通知中奖玩家
				gamelog.prizeusers[tostring(k)] = prize
				gamelog.prizemoney = gamelog.prizemoney + prize
				luckyusers[k] = prize
			end
		end
	end
	self.prizepool.count = self.prizepool.count + 1
	if self.prizepool.count > self.prizepool_cfg.prize_count then
		self.prizepool.count = 0
		self.prizepool.prize = 0
	end
	gamelog.prizepool = self.prizepool.pool
	return luckyusers
end

-- 发送中奖玩家奖金
function base_prize_pool:send_prize_pool_money(table_id , table_self , user_list)
	for k,v in pairs(user_list) do
		local v = self.player_bet_info[table_id][k]

		log.info("=========================1  guid[%d]",k)
		if v then
			local smoney = v.player:get_money()
			local money = user_list[v.player.guid]

			log.info("=========================1  guid[%d] smoney[%d] money[%d]",k ,smoney , money)
			if money > 100 then
				local notify = {}
				notify.prize_money = money
				notify.prize_join = 1
				v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money}}, self.log_money_type)				
				notify.player_money = v.player:get_money()
				log.info("guid[%d] old_money[%d] new_money[%d]" , k, smoney, v.player:get_money())
				table_self:player_money_log(v.player,2,smoney,0,money,self.game_log_id[table_id])
				notify.cur_money = v.player:get_money()
				table.insert(self.prizepool_led,{nickname = v.player.nickname,money = money / 100})

				log.info("guid[%d] name[%s] money[%d]" ,v.player.guid ,  v.player.nickname , money)
				send2client_pb(v.player,"SC_Prize_Pool_Result",notify)
			end
		else
			log.info("=========================1  guid[%d] not find",k)
		end
	end

	for _,v in pairs(self.prizepool_led) do
		broadcast_world_marquee(def_first_game_type,def_second_game_type,1,v.nickname,v.money)
	end
	-- 清空当前table的下注玩家
	self.prizepool_led = {}
	self.player_bet_info[table_id] = {}
	self.game_log_id[table_id] = nil

	-- self:player_money_log(player,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
end


function base_prize_pool:tick(room_id , table_id)
	self:prize_pool_show(room_id , table_id)
end

----------------------------------
---- 游戏调用

function base_prize_pool:set_table_player_list(room_id , table_id , player_list)
	-- body
	log.info("room_id[%d] , table_id [%d]" , room_id , table_id)

	if not self.player_list then
		self.player_list = {}
	end
	if not self.player_list[room_id] then
		self.player_list[room_id] = {}
	end
	self.player_list[room_id][table_id] = player_list

	log.info("set_table_player_list roooid [%d] ============== prize pool open table_count[%d]" , room_id,getNum(self.player_list[room_id]))
end

-- ingame 游戏调用了 base_table:player_sit_down 不用处理 如果没有需要在游戏中处理
function base_prize_pool:into_game(player)
	-- body
	if self:prize_pool_is_open() then
		self:send_player_show(player)
	end
end

-- robot_name 分房间以second_type为区分
function base_prize_pool:set_robot_name( robot_name )
	-- body
	self.robot_name = robot_name
end

local game_name_list = {
	ox = 1,
}

function base_prize_pool:load_lua_cfg(room_id , cfgstr )
	-- body
	log.info("%s" , cfgstr)
	if game_name_list[def_game_name] == 1 then
		local jsonStr = cfgstr
		if def_first_game_type == 8 then
			local funtemp = load(cfgstr)
			local ox_config = funtemp()
			-- jsonStr = ox_config.prizepool
			if ox_config.prizepool then
				jsonStr = '{ "prizepool" : ' .. ox_config.prizepool .. '}'
			else
				jsonStr = '{ "prizepool" : {} }'
			end
		end
		log.info("%s" , jsonStr)
		local cfg = json.decode(jsonStr)
		local is_open = self:prize_pool_is_open()

		if cfg and type(cfg) == "table" and cfg.prizepool and type(cfg.prizepool) == "table" then
			for k,v in pairs(self.prizepool_cfg) do
				print(k , v)
				if k and cfg and cfg.prizepool and cfg.prizepool[k] then
					print("---3" , k , self.prizepool_cfg[k] , cfg.prizepool[k])
					self.prizepool_cfg[k] = tonumber(cfg.prizepool[k])
				end
			end
			if is_open and not self:prize_pool_is_open() then
				log.info("close prize_pool ===============================1 %s",self.player_list)
				for room_id , room in pairs(self.player_list ) do
					log.info("roooid [%d] ============== prize pool close table_count[%d]" , room_id,getNum(room))
					for table_id , _ in pairs(room) do
						log.info("room_id[%d] table[%d] send SC_PrizePool_show = 0 ",room_id , table_id)
						self:broadcast2client(room_id , table_id, "SC_PrizePool_show",{money = 0})
					end
				end
				if self.prizepool_cfg.open == 0 then
					self:prize_pool_init()
				end
			elseif not is_open and self:prize_pool_is_open() then
				log.info("close prize_pool ===============================2 %s",self.player_list)
				for room_id , room in pairs(self.player_list ) do
					log.info("roooid [%d] ============== prize pool open table_count[%d]" , room_id,getNum(room))
					for table_id , _ in pairs(room) do
						log.info("room_id[%d] table[%d] send SC_PrizePool_show ",room_id , table_id)
						self:prize_pool_show(room_id ,table_id)
					end
				end
			end
		end
	end
end



-- 断线重连调用一次
function base_prize_pool:send_player_show( player )
	--通知更新奖池
	if self:prize_pool_is_open() then
		log.info("============SC_PrizePool_show guid[%d]",player.guid)
		send2client_pb(player,"SC_PrizePool_show",{money = self.prizepool.show})
	end
end

-- 游戏开始时
function base_prize_pool:game_start(room_id , table_id , game_log_id)
	-- body
	if self:prize_pool_is_open() then
		log.info("game_start table_id [%d] game_log_id [%s] " , table_id , game_log_id)
		self.game_log_id[table_id] = game_log_id
	elseif self.prizepool_cfg.open == 0 then
		self:prize_pool_init()
		log.info("room_id[%d] table_id[%d] send SC_PrizePool_show = 0 ",room_id , table_id)
		self:broadcast2client(room_id , table_id , "SC_PrizePool_show",{money = 0})
	end
end

-- 下注结束时添加所有下注玩家 也可以结算的时候 添加 必须在game_end 前调用
function base_prize_pool:input_bet_list( table_id , player, bet_money )
	-- body
	if self:prize_pool_is_open() and self.game_log_id[table_id] then
		log.info("input_bet_list table_id [%d] guid [%d] bet_money[%d]" , table_id , player.guid , bet_money)
		if not self.player_bet_info[table_id] then
			self.player_bet_info[table_id] = {}
		end
		self.player_bet_info[table_id][player.guid] = { player = player , bet = bet_money }
	end
end

-- 游戏结束时
function base_prize_pool:game_end(table_id ,table_self, money , gamelog)
	if self:prize_pool_is_open() and self.game_log_id[table_id] then
		local money_old = self.prizepool.pool
		log.info("input_bet_list table_id [%d] end_money [%d] " , table_id , money )
		local join_users = self:prize_pool_players(table_id)
		print("========join_users==============")
		dump(join_users)
		local lucky_users = self:prize_pool_game(join_users , money , gamelog)

		print("========lucky_users==============")
		dump(lucky_users)
		self:send_prize_pool_money(table_id , table_self , lucky_users)
		log.info("self.prizepool.pool end by table[%d]  [%d]====> [%d]" ,table_id , money_old , self.prizepool.pool)
	end
end

return base_prize_pool