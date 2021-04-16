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
local club_member_partner = require "game.club.club_member_partner"
local club_member_lock = require "game.club.club_member_lock"

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

local function recusive_broadcast(clubid,msgname,msg,except)
    local guids = recusive_get_members(clubid)
    onlineguid.broadcast(table.keys(guids),msgname,msg)
end

function club_partner:create(club_id,guid,parent)
    return club_member_lock[self.club_id][self.guid](function()
        club_id = tonumber(club_id)
        guid = type(guid) == "number" and guid or guid.guid
        
        channel.publish("db.?","msg","SD_CreatePartner",{
            club = club_id,
            guid = guid,
            parent = parent,
        })
        
        local cp = {
            club_id = club_id,
            guid = guid,
            parent = parent,
        }

        reddb:hset(string.format("club:member:partner:%s",club_id),guid,parent)
        reddb:hset(string.format("club:role:%s",club_id),guid,enum.CRT_PARTNER)
        reddb:zincrby(string.format("club:zmember:%s",club_id),enum.CRT_PARTNER - enum.CRT_PLAYER,guid)
        reddb:zincrby(string.format("club:partner:zmember:%s:%s",club_id,parent),enum.CRT_PARTNER - enum.CRT_PLAYER,guid)

        setmetatable(cp,{__index = club_partner})

        return enum.ERROR_NONE,cp
    end)
end

function club_partner:join(guid)
    return club_member_lock[self.club_id][self.guid](function()
        guid = tonumber(guid)

        channel.publish("db.?","msg","SD_JoinPartner",{
            club = self.club_id,
            partner = self.guid,
            guid = guid,
        })

        reddb:hset(string.format("club:member:partner:%s",self.club_id),guid,self.guid)
        reddb:sadd(string.format("club:partner:member:%s:%s",self.club_id,self.guid),guid)
        reddb:zadd(string.format("club:partner:zmember:%s:%s",self.club_id,self.guid),enum.CRT_PLAYER,guid)

        local partner  = self.guid
        while partner and partner ~= 0 do
            reddb:hincrby(string.format("club:team_player_count:%s",self.club_id),partner,1)
            partner = club_member_partner[self.club_id][partner]
        end

        return enum.ERROR_NONE
    end)
end

function club_partner:exit(mem)
    return club_member_lock[self.club_id][self.guid](function()
        local is_mem = club_partner_member[self.club_id][self.guid][mem]
        if not is_mem then
            return enum.ERROR_OPERATION_INVALID
        end

        reddb:hdel(string.format("club:member:partner:%s",self.club_id),mem)
        reddb:srem(string.format("club:partner:member:%s:%s",self.club_id,self.guid),mem)
        reddb:zrem(string.format("club:partner:zmember:%s:%s",self.club_id,self.guid),mem)
        channel.publish("db.?","msg","SD_ExitPartner",{
            club = self.club_id,guid = mem,partner = self.guid
        })

        local partner  = self.guid
        while partner and partner ~= 0 do
            reddb:hincrby(string.format("club:team_player_count:%s",self.club_id),partner,-1)
            partner = club_member_partner[self.club_id][partner]
        end
        
        return enum.ERROR_NONE
    end)
end

function club_partner:broadcast(msgname,msg,except)
    broadcast(self.club_id,self.guid,msgname,msg,except)
end

function club_partner:dismiss()
    return club_member_lock[self.club_id][self.guid](function()
        channel.publish("db.?","msg","SD_DismissPartner",{
            club = self.club_id,
            partner = self.guid
        })

        for guid,_ in pairs(club_partner_member[self.club_id][self.guid]) do
            reddb:hdel(string.format("club:member:partner:%s",self.club_id),guid)
        end

        reddb:zincrby(string.format("club:zmember:%s",self.club_id),enum.CRT_PLAYER - enum.CRT_PARTNER,self.guid)
        reddb:zincrby(string.format("club:partner:zmember:%s:%s",self.club_id,self.parent),enum.CRT_PLAYER - enum.CRT_PARTNER,self.guid)
        reddb:del(string.format("club:partner:member:%s:%s",self.club_id,self.guid))
        reddb:del(string.format("club:partner:zmember:%s:%s",self.club_id,self.guid))
        reddb:hdel(string.format("club:role:%s",self.club_id),self.guid)
        reddb:hdel(string.format("club:team_player_count:%s",self.club_id),self.guid)
        reddb:hdel(string.format("club:team_money:%s",self.club_id),self.guid)
        return enum.ERROR_NONE
    end)
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


return club_partner