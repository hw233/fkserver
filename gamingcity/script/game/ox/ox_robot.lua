--����ţţ�������߼�

--local room = g_room
local pb = require "pb"
require "game.lobby.base_character"
local base_table = require "game.lobby.base_table"
require "table_func"
require "game.lobby.base_player"
require "game.lobby.base_android"
require "game.lobby.android_manager"
--require "game.ox.ox_table"
--require "game.ox.ox_room"
require "data.land_data"
local robot_ip_area = robot_ip_area
local random = require "random"
-- ��ׯ������
local TYPE_ROBOT_BANKER = 1

-- ��ׯ�����˳�ʼUID
local BANKER_ROBOT_INIT_UID = 1000000

-- ��ע�����˳�ʼUID
local BET_ROBOT_INIT_UID = 2000000

-- ���������UIDϵ��
local ROBOT_UID_COEFF = 100000

-- ��ע������
local TYPE_ROBOT_BET = 2

-- ��ׯ�����˳�ʼ���
local BANKER_ROBOT_START_MONEY = 10000000

-- ��ע�����˳�ʼ���
local BET_ROBOT_START_MONEY = 100000

-- ��ע�����˳�ʼ��ҵ������ֵ
local RAND_MONEY = 20000

-- ��ע����
local BET_AREA_TOTAL = 4




--[[if not ox_robot then
	ox_robot = base_character:new()
end--]]
ox_robot = {}

function ox_robot:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- �����˳�ʼ��
function ox_robot:init(guid_, account_, nickname_)
	-- base_character.init(self, guid_, account_, nickname_)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.guid = guid_
	self.is_player = false
	self.nickname = nickname_
	self.chair_id = 0
	self.money = 0
	self.header_icon = -1
	local ip_index = random.boost_integer(1,#robot_ip_area)
	self.ip = ""
	self.ip_area =  robot_ip_area[ip_index]
end


-- ���ֶ��������������,���ٴ����ݿ��ж�ȡ
-- guid,nickname_,money,account,
-- ��ׯ������guid���䷶Χ[10000~~20000],��ע������guid���䷶Χ[20000~~30000]
temp_number = 0
-- ����������(��Ϸ�����ô���)
function ox_robot:creat_robot(robot_type, robot_num, uid, money)
	if TYPE_ROBOT_BANKER == robot_type then --  ������ׯ������
		local banker_robot = ox_robot:new()
		local robot_uid = uid + math.random(ROBOT_UID_COEFF)
		banker_robot:init(robot_uid, "test_banker_robot", "system_banker")
		--banker_robot.money = self:get_money(TYPE_ROBOT_BANKER)
		banker_robot.money = money
		return banker_robot
	elseif TYPE_ROBOT_BET == robot_type then --  ������ע������
		local tb_bet_robot = {}
		local robot_ret_uid = uid + math.random(ROBOT_UID_COEFF)
		for i=1,robot_num,1
		do
			local bet_robot = ox_robot:new()
			bet_robot:init(robot_ret_uid, "test_bet_robot", "bet_robot")
			--bet_robot.money = self:get_money(TYPE_ROBOT_BET)
			math.randomseed(os.time() + temp_number)
			local rand_num = math.random(RAND_MONEY)
			temp_number = temp_number + math.random(10)
			bet_robot.money = money + math.random(rand_num+1)
			table.insert(tb_bet_robot,bet_robot)
			robot_ret_uid = robot_ret_uid + 1
		end
		return tb_bet_robot
	else
		log.error("creat_robot error.")
		return	
	end	
	
	return
end

-- ��ý��
function ox_robot:get_money(robot_type)
	if TYPE_ROBOT_BANKER == robot_type then
		return BANKER_ROBOT_START_MONEY
	elseif TYPE_ROBOT_BET == robot_type then --todo++ ���������������� math.random(RAND_MONEY)
		return BET_ROBOT_START_MONEY + math.random(RAND_MONEY)
	else 
		log.error("get_money error.")
		return 0
	end
end

-- �ӽ��
function ox_robot:robot_add_money(robot,robot_earn_money)
	local old_money = robot.money
	
	if robot_earn_money <= 0 then
		return false
	end
	
	local new_money = old_money + robot_earn_money
	robot.money = new_money
	return true
end

-- �����
function ox_robot:robot_cost_money(robot,robot_earn_money)
	local old_money = robot.money
	
	if robot_earn_money <= 0 then
		return false
	end
	
	local new_money = old_money - robot_earn_money
	robot.money = new_money
	return true
end


-- ��ׯ�����˳�ʼ������(�������,��ׯ��������,guid,nickname,money��)
function ox_robot:banker_robot_init()
	
end

-- ��ע�����˳�ʼ������(��ʼ������,��ע�ܽ������,�ܴ������Ƶ�)
function ox_robot:bet_robot_init()
	
end


-- ������Ϸ����(�ص�:��ν��뷿�����Ӳ�����������б���?)
function ox_robot:Enter_Game()
	
end

-- ��ע�����������ע(�������,��������)
function ox_robot:control_bet_robot()
	
end

