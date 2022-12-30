require "functions"
require "random_mt19937"
local chronos = require "chronos"

local math = math

local changpai_tile_dealer = {}

function changpai_tile_dealer:new(all_tiles)
    local o = {
        tiles = clone(all_tiles),
    }
    setmetatable(o,{__index = changpai_tile_dealer,})
    return o
end

function changpai_tile_dealer:load_tiles(tiles)
    self.tiles = clone(tiles)
end

function changpai_tile_dealer:shuffle()
    math.randomseed(math.floor(chronos.nanotime() * 10000))
	for _ = 1,10 do math.random() end

    local tiles = self.tiles
    for i = #tiles,2,-1 do
        local j = math.random(i - 1)
        tiles[j],tiles[i] = tiles[i],tiles[j]
    end

    self.remain_count = #self.tiles
end

function changpai_tile_dealer:arrange_tiles(tiles,begin)
    begin = begin or 1
    local k = self.remain_count
    local function back_indexof(tile,start)
        start = start or 1
        for i = k,start,-1 do
            if self.tiles[i] == tile then
                return i
            end
        end
    end

    for i,t in pairs(tiles) do
        local j = back_indexof(t)
        local m = begin + i - 1
        if j and j ~= m then
            self.tiles[j], self.tiles[m] = self.tiles[m], self.tiles[j]
        end
    end

    return
end

function changpai_tile_dealer:pick_tiles(tiles)
    for _,tile in pairs(tiles) do
        self:deal_one_on(function(t) return t == tile end)
    end

    return tiles
end

function changpai_tile_dealer:use_one()
    local k = self.remain_count
    local j = math.random(k)
    local tile = self.tiles[j]
    return tile
end

function changpai_tile_dealer:deal_one()
    local k = self.remain_count
    local j = math.random(k)
    local tile = self.tiles[j]
    if j ~= k then self.tiles[j], self.tiles[k] = self.tiles[k], self.tiles[j] end
    self.remain_count = self.remain_count - 1
    return tile
end

function changpai_tile_dealer:deal_one_on(func)
    local k = self.remain_count
    for j = 1,k do
        if func(self.tiles[j]) then
            local tile = self.tiles[j]
            if j ~= k then self.tiles[j], self.tiles[k] = self.tiles[k], self.tiles[j] end
            self.remain_count = self.remain_count - 1
            return tile
        end
    end

    return 0
end

function changpai_tile_dealer:deal_tiles(count)
    local tiles = {}
    for _ = 1,count do
        local c = self:deal_one()
        if c ~= 0 then table.push_back(tiles,c)  end
    end
    return tiles
end

function changpai_tile_dealer:deal_tiles_on(count,func)
    local tiles = {}
    for _ = 1,count do
        local c = self:deal_one_on(func)
        if c ~= 0 then table.push_back(tiles,c) end
    end
    return tiles
end

function changpai_tile_dealer:reserve_count(count)
    self.remain_count = self.remain_count + count
end

function changpai_tile_dealer:remain_tiles()
    return table.slice(self.tiles,1,self.remain_count)
end

return changpai_tile_dealer