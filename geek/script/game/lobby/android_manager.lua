-- 机器人管理

local android_manager = {} 
function android_manager:new()  
    local o = {}  
    setmetatable(o, {__index = self})
    return o 
end

-- 保存从db中查询出来的数据
function android_manager:load_from_db(ls)
	self.android_list_ = self.android_list_ or {}
	for _, item in ipairs(ls) do
		table.insert(self.android_list_, item)
		if not self.max_guid_ then
			self.max_guid_ = item.guid
		elseif self.max_guid_ < item.guid then
			self.max_guid_ = item.guid
		end
	end
end

-- 得到最大的guid
function android_manager:get_max_guid()
	return self.max_guid_
end

-- 得到可用的机器人
function android_manager:create_android(game_id, count)
	local ret = {}
	if self.android_list_ then
		local i = 0
		for _, item in ipairs(self.android_list_) do
			if item.game_id == 0 then
				item.game_id = game_id
				table.insert(ret, item)
				i = i + 1
				if i >= count then
					break
				end
			end
		end
	end
	return ret
end

-- 回收游戏服务器机器人
function android_manager:destroy_android(ls)
	if self.android_list_ then
		for _, item in ipairs(self.android_list_) do
			for _, v in ipairs(ls) do
				if item.guid == v then
					item.game_id = 0
					break
				end
			end
		end
	end
end

return android_manager