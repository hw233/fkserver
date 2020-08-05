local redisopt = require "redisopt"
local log = require "log"
require "functions"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local channel = require "channel"
local club_role = require "game.club.club_role"
local club_partner_member = require "game.club.club_partner_member"
local club_money_type = require "game.club.club_money_type"
local club_partner_commission = require "game.club.club_partner_commission"
local player_money = require "game.lobby.player_money"
local base_players = require "game.lobby.base_players"
local util = require "util"

local reddb = redisopt.default

local club_partner = {}

local function broadcast(club_id,partner,msgname,msg,except)
    if except then
        except = type(except) == "number" and except or except.guid
    end
    local guids = {}
    for guid,_ in pairs(club_partner_member[club_id][partner]) do
        if not except or except ~= guid then
            table.insert(guids,guid)
        end
    end

    if table.nums(guids) ~= 0 then
        onlineguid.broadcast(guids,msgname,msg)
    end
end

local function recusive_get_members(club_id,partner)
    local guids = {}
    for guid,_ in pairs(club_partner_member[club_id][partner] or {}) do
        local role = club_role[club_id][guid]
        if role == enum.CRT_PARTNER then
            table.mergeto(guids,recusive_get_members(club_id,guid))
        end

        guids[guid] = true
    end

    return guids
end

local function recusive_broadcast(clubid,msgname,msg)
    local guids = recusive_get_members(clubid)
    onlineguid.broadcast(table.keys(guids),msgname,msg)
end

function club_partner:create(club_id,guid,parent)
    club_id = tonumber(club_id)
    guid = type(guid) == "number" and guid or guid.guid
    
    if not channel.call("db.?","msg","SD_CreatePartner",{
        club = club_id,
        guid = guid,
        parent = parent,
    }) then
        log.error("club_partner:create unknown db error.")
        return enum.ERROR_INTERNAL_UNKOWN
    end
    
    local cp = {
        club_id = club_id,
        guid = guid,
        parent = parent,
    }

    reddb:hset(string.format("club:member:partner:%s",club_id),guid,parent)
    reddb:hset(string.format("club:role:%s",club_id),guid,enum.CRT_PARTNER)

    setmetatable(cp,{__index = club_partner})

    return enum.ERROR_NONE,cp
end

function club_partner:join(guid)
    guid = tonumber(guid)

    if not channel.call("db.?","msg","SD_JoinPartner",{
        club = self.club_id,
        partner = self.guid,
        guid = guid,
    }) then
        log.error("club_partner:join unknown db error.")
        return enum.ERROR_INTERNAL_UNKOWN
    end

    reddb:hset(string.format("club:member:partner:%s",self.club_id),guid,self.guid)
    reddb:sadd(string.format("club:partner:member:%s:%s",self.club_id,self.guid),guid)
    return enum.ERROR_NONE
end

function club_partner:exit(mem)
    local is_mem = club_partner_member[self.club_id][self.guid][mem]
    if not is_mem then
        return enum.ERROR_OPERATION_INVALID
    end

    reddb:hdel(string.format("club:member:partner:%s",self.club_id),mem)
    reddb:srem(string.format("club:partner:member:%s:%s",self.club_id,self.guid),mem)
    return enum.ERROR_NONE
end

function club_partner:broadcast(msgname,msg,except)
    broadcast(self.club_id,self.guid,msgname,msg,except)
end

function club_partner:dismiss()
    if not channel.call("db.?","msg","SD_DismissPartner",{
        club = self.club_id,
        partner = self.guid
    }) then
        log.error("club_partner:dismiss unknown db error.")
        return enum.ERROR_INTERNAL_UNKOWN
    end

    for guid,_ in pairs(club_partner_member[self.club_id][self.guid]) do
        reddb:hdel(string.format("club:member:partner:%s",self.club_id),guid)
    end

    reddb:del(string.format("club:partner:member:%s:%s",self.club_id,self.guid))
    reddb:hdel(string.format("club:role:%s",self.club_id),self.guid)
    return enum.ERROR_NONE
end

function club_partner:recusive_broadcast(msgname,msg,except)
    recusive_broadcast(self.id,msgname,msg,except)
end

function club_partner:notify_money()
    local money_id = club_money_type[self.club_id]
    if not money_id then
        log.error("club_partner:notify_money unknown club money_id.")
        return
    end

    onlineguid.send(self.guid,"SYNC_OBJECT",util.format_sync_info(
        "PLAYER",{
            club_id = self.club_id,
            guid = self.guid,
        },{
            money = player_money[self.guid][money_id],
            commission = club_partner_commission[self.club_id][self.guid],
            money_id = money_id,
        }
    ))
end

function club_partner:incr_commission(money,round_id)
    if money == 0 then return end

    if not channel.call("db.?","msg","SD_LogPlayerCommission",{
        club = self.club_id,
        commission = money,
        round_id = round_id or "",
        money_id = club_money_type[self.club_id],
        guid = self.guid,
    }) then
        log.error("club_partner:incr_commission unknown db error.")
        return
    end

    local newmoney = reddb:hincrby(string.format("club:partner:commission:%d",self.club_id),self.guid,money)
    newmoney = newmoney and tonumber(newmoney) or 0
    club_partner_commission[self.club_id] = nil

    self:notify_money()
    return newmoney
end

function club_partner:exchange_commission(money)
    local commission = club_partner_commission[self.club_id][self.guid]
    if money < 0 then money = commission  end

    if money == 0 then return enum.ERROR_NONE end

    if money < 0 then  return enum.ERROR_PARAMETER_ERROR end

    if money > commission then return enum.ERROR_LESS_MIN_LIMIT  end

    reddb:hincrby(string.format("club:partner:commission:%s",self.club_id),self.guid,-math.floor(money))
    local money_id = club_money_type[self.club_id]
    base_players[self.guid]:incr_money({
        money_id = money_id,
        money = money,
    },enum.LOG_MONEY_OPT_TYPE_CLUB_COMMISSION)

    self:notify_money()

    return enum.ERROR_NONE
end

return club_partner