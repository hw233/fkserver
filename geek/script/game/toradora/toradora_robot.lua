-- 斗地主消息处理

local pb = require "pb_files"

require "data.land_data"
local robot_ip_area = robot_ip_area

local ITEM_PRICE_TYPE_GOLD = pb.enum("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

local random = require "random"
require "game.net_func"
local send2client_pb = send2client_pb

toradora_robot = {}
-- 创建
function toradora_robot:new()
    local o = {}
    setmetatable(o, {__index = self})

    return o
end

function toradora_robot:init(guid_, account_, nickname_)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.guid = guid_
	self.is_player = false
	self.is_android = true
	self.nickname = nickname_
	self.chair_id = 0
	self.money = 0
	self.header_icon = random.boost_integer(1,10) --机器人头像随机
	local ip_index = random.boost_integer(1,#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
	self.win_or_loss = 0
end

function toradora_robot:creat_robot(guid, money)
	local frobot = toradora_robot:new()
	frobot:init(guid, "test_toradora_robot", "system_toradora_robot")
	frobot.money = money
	return frobot
end

function toradora_robot:get_header_icon()
	-- body
	return self.header_icon
end

function toradora_robot:get_money()
	-- body
	return self.money
end

-- 加钱
function toradora_robot:add_money(price, opttype)
	local money = self.money
	local oldmoney = money

	for _, p in ipairs(price) do
		if p.money_type == ITEM_PRICE_TYPE_GOLD then
			if p.money <= 0 then
				return false
			end
			money = money + p.money
		end
	end

	self.money = money
	self.win_or_loss = 1
	return true
end

-- 花钱
function toradora_robot:cost_money(price, opttype, bRet)
	local money = self.money
	local oldmoney = money
	local iRet = true
	for _, p in ipairs(price) do
		p.money = math.ceil(p.money)
		if p.money_type == ITEM_PRICE_TYPE_GOLD then
			if p.money <= 0 or money < p.money then
				money = p.money
			end
			money = money - p.money
		end
	end

	self.money = money
	self.win_or_loss = 2
	return iRet
end

function toradora_robot:dispatch_msg(msgname, msg)
	-- body
end