-- 斗地主出牌ai


-- 0：方块3，1：梅花3，2：红桃3，3：黑桃3 …… 48：方块2，49：梅花2，50：红桃2，51：黑桃2，52：小王，53：大王

local pdk_ai = {}

-- 创建
function pdk_ai:new()
    local o = {} 

    setmetatable(o, {__index = self})
	
    return o 
end

-- cards_chair1、cards_chair2、cards_chair3：chiar_id=1、2、3的牌，land_chair_id：地主桌号
function pdk_ai:init(cards_chair1,cards_chair2,cards_chair3,land_chair_id)
    local cards1_ = {
    	cards = cards_chair1, --剩余的牌
    	last_cards = {} 	  --上一次出手的牌
	}
    local cards2_ = {
    	cards = cards_chair2,
    	last_cards = {}
	}
    local cards3_ = {
    	cards = cards_chair3,
    	last_cards = {}
	}
	self.chair_cards_ = {[1] = cards1_,[2] = cards2_,[3] = cards3_}
	self.land_chair_id_ = land_chair_id
end


function pdk_ai:set_cards(cards_chair1,cards_chair2,cards_chair3)
    self.chair_cards_[1].cards = cards_chair1
    self.chair_cards_[2].cards = cards_chair2
    self.chair_cards_[3].cards = cards_chair3
end

return pdk_ai