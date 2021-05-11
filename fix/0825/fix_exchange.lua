
local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local club_role = require "game.club.club_role"
local club_partner_commission = require "game.club.club_partner_commission"
local club_utils = require "game.club.club_utils"
local log = require "log"

local function on_cs_exchagne_club_commission(msg,guid)
	log.info("on_cs_exchagne_club_commission %s,%s",guid,msg.partner_id)
    local club_id = msg.club_id
    local count = msg.count
    local partner_id = msg.partner_id
    if not partner_id or partner_id == 0 then
        partner_id = guid
    end

    if not count or not club_id then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_PARAMETER_ERROR,
        })
        return
    end

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_CLUB_NOT_FOUND,
        })
        return
    end

    local role = club_role[club_id][partner_id]
    if role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
        })
        return
    end

    if  role == enum.CRT_PARTNER and
        guid ~= partner_id and
        not club_utils.is_recursive_in_team(club,guid,partner_id)
    then
        onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
            result = enum.ERROR_PLAYER_NO_RIGHT,
        })
        return
    end

    local commission = club_partner_commission[club_id][partner_id]
    if count < 0 then
        count = commission
    end

    local result = club:exchange_team_commission(partner_id,count)
    onlineguid.send(guid,"S2C_EXCHANGE_CLUB_COMMISSON_RES",{
        result = result,
        club_id = club_id,
        partner_id = partner_id,
    })
end

local msgopt = require "msgopt"

msgopt.C2S_EXCHANGE_CLUB_COMMISSON_REQ = on_cs_exchagne_club_commission