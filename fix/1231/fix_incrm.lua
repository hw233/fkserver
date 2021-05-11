

local base_club = require "game.club.base_club"
local base_players = require "game.lobby.base_players"
local log = require "log"
local club_money_type = require "game.club.club_money_type"
local club_member = require "game.club.club_member"
local redisopt = require "redisopt"
local club_member_partner = require "game.club.club_member_partner"

local reddb = redisopt.default

function base_club:incr_member_money(guid,delta_money,why,why_ext)
	log.info("base_club:incr_member_money")
    local player = base_players[guid]
    if not player then
        log.error("base_club:incr_member_money got nil player,club:%s,guid:%s",self.id,guid)
        return
    end
    
    delta_money = math.floor(delta_money)
    player:incr_money({
            money_id = club_money_type[self.id],
            money = delta_money,
        },why,why_ext)

    if not club_member[self.id][guid] then
        log.error("base_club:incr_member_money not member,club:%s,guid:%s",self.id,guid)
        return
    end

    local partner = club_member_partner[self.id][guid]
    while partner and partner ~= 0 do
        reddb:hincrby(string.format("club:team_money:%s",self.id),partner,delta_money)
        partner = club_member_partner[self.id][partner]
    end
end