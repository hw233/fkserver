local skynet = require "skynetproto"
local json = require "cjson"
local log = require "log"
local redisopt = require "redisopt"
local club_notice = require "game.notice.club_notice"

local reddb = redisopt.default

local mail_expaired_seconds = 60 * 60 * 24 * 7

local base_notice = {}

local function new_notice_id()
	return string.format("%d-%d",skynet.time() * 1000,math.random(10000))
end

function base_notice.create(type,where,content,club)
        club = type(club) == "table" and club.id or club

        local info = {
                id = new_notice_id(),
                expiration = os.time() + mail_expaired_seconds,
                create_time = os.time(),
                content = content,
                where = where,
                club = club,
                status = 0,
        }

        reddb:hmset("notice:"..info.id,info)
        if club and club ~= 0 then
                reddb:sadd(string.format("club:notice:%d",club),info.id)
                club_notice[club] = nil
        end
        
        local _ = base_notice[info.id]
        
        return info
end

return base_notice