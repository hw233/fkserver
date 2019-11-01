-- 奖池
local redisopt = require "redisopt"
local log = require "log"
require "timer"
local add_timer = add_timer
local def_get_redis_bonus = 10 + math.random(1,5) -- 定时获取一次奖池
local def_wirte_db_bonus  = 60 + math.random(1,10)-- 定时写数据库
local MAX_BONUS = 999999

local prize_pool = {}

local reddb = redisopt.default

-- 创建
function prize_pool:new()
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

function prize_pool:init(game_name)
    self.game_name_         = game_name
    self.total_bonus_money_ = 0   --所有游戏服总的奖池金额

    --向数据库请求初始值
    local function get_db_bonus()
        send2db_pb("SD_GetBonusPoolMoney", {
          bonus_pool_name = self:get_redis_key()
        })
    end
    add_timer(3, get_db_bonus)

    -- 定时更新
    local function get_redis_bonus()
        local redis_key = self:get_redis_key()
        local reply = reddb:get(redis_key)
        if type(reply) == "string" or type(reply) == "number" then
            self.total_bonus_money_ = tonumber(reply) 
            -- log.info("get_redis_bonus total_bonus_money [%d]",self.total_bonus_money_)
        end 

        add_timer(def_get_redis_bonus, get_redis_bonus)
    end
    add_timer(5, get_redis_bonus)

    -- 定时写数据库
    local function write_db_bonus()
        send2db_pb("SD_UpdateBonusPool", {
            bonus_pool_name = self:get_redis_key(),
            money = self.total_bonus_money_
            })

        add_timer(def_wirte_db_bonus, write_db_bonus)
    end
    add_timer(def_wirte_db_bonus, write_db_bonus)
end

function prize_pool:get_redis_key()
    return string.format("bonuspool:%s",self.game_name_)
end

function prize_pool:add_money(money)
	local redis_key = self:get_redis_key()
    if self.total_bonus_money_ >= MAX_BONUS then
        local reply = reddb:get(redis_key)
        if reply then
            self.total_bonus_money_ = tonumber(reply) 
        end
		return 0
	end
	
    self.total_bonus_money_ = self.total_bonus_money_ + money

    local reply = reddb:incrby(redis_key,money)
    if reply then
        self.total_bonus_money_ = tonumber(reply)
        -- log.info("add_money[%d] total_bonus_money [%d]",money,self.total_bonus_money_)
    end

	return money
end

function prize_pool:get_total_bonus()
    if self.total_bonus_money_ <= 0 then
      return 0
    end
    return self.total_bonus_money_ 
end

function prize_pool:remove_money(money)
	if money < 0 then
		log.warning("prize_pool:remove_money [%d] money [%d]",self.total_bonus_money_,money)
		return 0
	end

    if self.total_bonus_money_ > (MAX_BONUS + 100000) then
        local redis_key = self:get_redis_key()
        local reply = reddb:set(redis_key,0)
        if reply then
            self.total_bonus_money_ = 0
			log.warning("remove_money set  total_bonus_money [%d]",self.total_bonus_money_)
        end
		return 0
    end

	if self.total_bonus_money_ <= 0 then 
		return 0
	end

    local money_real_cost = 0
    if self.total_bonus_money_ >= money then
        money_real_cost = money
    else
        money_real_cost = self.total_bonus_money_
    end
    self.total_bonus_money_ = self.total_bonus_money_ - money_real_cost

    local redis_key = self:get_redis_key()
    local reply = reddb:decrby(redis_key,money_real_cost)
    if reply then
        self.total_bonus_money_ = reply
        log.info("remove_money[%d] total_bonus_money [%d]",money_real_cost,self.total_bonus_money_)
    end

    return money_real_cost
end

function prize_pool:force_remove_money(money)
    self.total_bonus_money_ = self.total_bonus_money_ - money

    local redis_key = self:get_redis_key()

    local reply = reddb:decrby(redis_key,money)
    if reply then
        self.total_bonus_money_ = reply
        log.info("remove_money[%d] total_bonus_money [%d]",money,self.total_bonus_money_)
    end
end

return prize_pool