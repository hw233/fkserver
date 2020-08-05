
local redisopt = require "redisopt"
local base_clubs = require "game.club.base_clubs"
local log = require "log"
local enum = require "pb_enums"

local reddb = redisopt.default

local request_meta = {}

function request_meta:agree()
    local club = base_clubs[self.club_id]
    if not club then
        log.error("unkown request club id:%s",self.club_id)
        return enum.ERROR_CLUB_NOT_FOUND
    end

    return club:agree_request(self)
end

function request_meta:reject()
    local club = base_clubs[self.club_id]
    if not club then
        log.error("unkown request club id:%s",self.club_id)
        return enum.ERROR_CLUB_NOT_FOUND
    end

    return club:reject_request(self)
end

local base_request = setmetatable({},{
    __index = function(t,req_id)
        local req = reddb:hgetall("request:"..tostring(req_id))
        if not req or table.nums(req) == 0 then
            return nil
        end
    
        setmetatable(req,{__index = request_meta})

        t[req_id] = req
        return req
    end,
})


return base_request