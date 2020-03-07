local redisopt = require "redisopt"
local log = require "log"
require "functions"
local base_players = require "game.lobby.base_players"
local club_member = require "game.club.club_member"
local base_private_table = require "game.lobby.base_private_table"
local table_template = require "game.lobby.table_template"
local club_template = require "game.club.club_template"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local json = require "cjson"
local channel = require "channel"
local base_mail = require "game.mail.base_mail"
local club_role = require "game.club.club_role"
local club_template_conf = require "game.club.club_template_conf"
local redismetadata = require "redismetadata"
local base_money = require "game.lobby.base_money"
local club_money_type = require "game.club.club_money_type"
local club_money = require "game.club.club_money"
local player_money = require "game.lobby.player_money"
local player_club = require "game.lobby.player_club"
local club_commission = require "game.club.club_commission"
local club_team = require "game.club.club_team"
local util = require "util"

local reddb = redisopt.default

local table_expire_seconds = 60 * 60 * 5

local base_club = {}

local function broadcast(clubid,msgname,msg,except)
    if except then
        except = type(except) == "number" and except or except.guid
    end
    local guids = {}
    for guid,_ in pairs(club_member[clubid]) do
        if not except or except ~= guid then
            table.insert(guids,guid)
        end
    end

    if table.nums(guids) ~= 0 then
        onlineguid.broadcast(guids,msgname,msg)
    end
end

local function recusive_get_members(club_id)
    local guids = club_member[club_id]
    for teamid,_ in pairs(club_team[club_id]) do
        table.mergeto(guids,recusive_get_members(teamid))
    end

    return guids
end

local function recusive_broadcast(clubid,msgname,msg)
    local guids = recusive_get_members(clubid)
    onlineguid.broadcast(table.keys(guids),msgname,msg)
end

function base_club:create(id,name,icon,owner,tp,parent)
    id = tonumber(id)
    local owner_guid = type(owner) == "number" and owner or owner.guid
    local c = {
        name = name,
        icon = icon,
        id = id,
        owner = owner_guid,
        type = tp,
        parent = parent or 0,
    }

    local money_info
    if parent and parent ~= 0 then
        local parent_money_id = club_money_type[parent]
        money_info = base_money[parent_money_id]
    else
        money_info = {
            id = reddb:incr("money:global"),
            club = id,
            type = enum.MONEY_TYPE_GOLD,
        }
    end

    if not channel.call("db.?","msg","SD_CreateClub",{
        info = c,
        money_info = money_info,
    }) then
        log.error("base_club:create SD_CreateClub failed.")
    end

    if (not parent or parent == 0) and tp == enum.CT_UNION then
        reddb:hmset(string.format("money:info:%d",money_info.id),{
            id = money_info.id,
            club = id,
            type = enum.MONEY_TYPE_GOLD,
        })
    end

    reddb:set(string.format("club:money_type:%d",id),money_info.id)
    reddb:hmset(string.format("club:money:%d",id),{
        [money_info.id] = 0,
        [0] = 0,
    })
    reddb:hmset("club:info:"..tostring(id),c)
    reddb:sadd("club:member:"..tostring(id),owner_guid)
    reddb:hset(string.format("player:money:%d",owner_guid),money_info.id,0)
    reddb:sadd(string.format("player:club:%d:%d",owner_guid,tp),id)
    reddb:sadd(string.format("club:team:%d",parent or 0),id)

    club_money[id] = nil
    club_money_type[id] = nil
    player_money[owner_guid][money_info.id] = nil
    player_club[owner_guid][tp] = nil

    reddb:hset(string.format("club:role:%d",id),owner_guid,enum.CRT_BOSS)
    club_role[id][owner_guid] = nil
    setmetatable(c,{__index = base_club})

    return id
end

function base_club:exit_from_parent()
    if self.parent and self.parent ~= 0 then
        reddb:srem(string.format("club:team:%d",self.parent),self.id)
    end
end

function base_club:dismiss()
    reddb:del("club:info:"..tostring(self.id))
    reddb:del("club:memeber:"..tostring(self.id))
    channel.call("db.?","msg","SD_DismissClub",self.id)
end

function base_club:request_join(guid)
	local req_id = reddb:incr("request:global:id")
	req_id = tonumber(req_id)
	local request = {
		id = req_id,
		type = "join",
		club_id = self.id,
        who = guid,
        whoee = self.owner,
    }

    reddb:hmset("request:"..tostring(req_id),request)
    reddb:sadd(string.format("club:request:%s",self.id),req_id)

    return req_id
end

function base_club:invite_join(invitee,inviter,inviter_club,type)
    if string.lower(type) == "invite_join" then
        local inviter_role = club_role[self.id][inviter]
        if inviter_role ~= enum.CRT_ADMIN and inviter_role ~= enum.CRT_PARTNER and inviter_role ~= enum.CRT_BOSS then
            return enum.ERORR_PARAMETER_ERROR
        end
        self:join(invitee,inviter)
        club_member[self.id] = nil
        return enum.ERROR_NONE
    end

    if string.lower(type) == "invite_create" then
        local mail_info = base_mail.create_mail(inviter_club.owner,invitee,"联盟邀请...",{
            type = type,
            club_id = self.id,
            whoee = invitee,
            who = inviter_club.owner,
        })

        base_mail.send_mail(mail_info)
        return enum.ERROR_NONE
    end
end

function base_club:agree_request(request)
    dump(request)
    local who = request.who
    local whoee = request.whoee

	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return
    end

    if request.type == "join" then
        self:join(who)
        reddb:srem(string.format("club:request:%s",request.club_id),request.id)
    elseif request.type == "exit" then
        self:exit(who)
        reddb:srem(string.format("club:request:%s",request.club_id),request.id)
    elseif request.type == "invite" then
        self:join(whoee)
        reddb:srem(string.format("club:request:%s",request.club_id),request.id)
    end

    club_member[self.id] = nil
    reddb:del(string.format("request:%s",request.id))
    return true
end

function base_club:reject_request(request)
    local whoee = request.whoee
	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return
    end

    reddb:srem(string.format("player:request:%s",whoee),request.id)
    reddb:del(string.format("request:%s",request.id))
    return true
end

function base_club:join(guid,inviter)
    channel.publish("db.?","msg","SD_JoinClub",{club_id = self.id,guid = guid})

    reddb:sadd(string.format("club:member:%s",self.id),guid)
    reddb:sadd(string.format("player:club:%d:%d",guid,self.type),self.id)
    player_club[guid][self.type] = nil
end

function base_club:exit(guid)
    channel.publish("db.?","msg","SD_ExitClub",{club_id = self.id,guid = guid})
	reddb:srem(string.format("club:member:%s",self.id),guid)
    reddb:srem(string.format("player:club:%d:%d",guid,self.type),self.id)
    player_club[guid][self.type] = nil
end

function base_club:broadcast(msgname,msg,except)
    broadcast(self.id,msgname,msg,except)
end


function base_club:create_table(player,chair_count,round,conf,template)
    local member = club_member[self.id][player.guid]
    if not member then
        log.warning("create club table,but guid [%s] not exists",player.guid)
        return enum.ERROR_NOT_IS_CLUB_MEMBER
    end

    if conf and not self:can_sit_down(conf,player) then
        return enum.ERROR_LESS_MIN_LIMIT
    end

    local result,global_tid,tb = g_room:create_private_table(player,chair_count,round,conf,self)
    if result == enum.GAME_SERVER_RESULT_SUCCESS then
        reddb:hmset(string.format("table:info:%d",global_tid),{
            club_id = self.id,
            template = template and template.template_id or nil,
        })

        reddb:sadd("club:table:"..self.id,global_tid)
        -- reddb:expire("club:table:"..self.id,table_expire_seconds)
        base_private_table[global_tid] = nil
    end

    return result,global_tid,tb
end

--玩家坐下积分检测
function base_club:can_sit_down(rule,player)
    if not rule or not rule.union then
        return true
    end

    local entry_score = rule.union.entry_score or 0
    local money_id = club_money_type[self.id]
    local money = player_money[player.guid][money_id]
    return money >= entry_score
end

--玩家积分破产
function base_club:is_player_bankrupt(template,player)
    if not template.rule or not template.rule.union then
        return false
    end

    local min_score = template.rule.union.min_score
    if not min_score then
        return false
    end

    local money_id = club_money_type[self.id]
    local money = player_money[player.guid][money_id]
    return min_score > money
end

function base_club:join_table(player,private_table,chair_count)
    local rule = private_table.rule
    if rule and not self:can_sit_down(rule,player) then
        return enum.ERROR_LESS_MIN_LIMIT
    end

    return g_room:join_private_table(player,private_table,chair_count)
end

local function check_rule(rule)
    if type(rule) == "string" then
        local ok
        ok,rule = pcall(json.decode,rule)
        if not ok or not rule then
            return
        end
    end

    if rule.union then
        local tax = rule.union.tax
        if not tax or (not tax.AA and not tax.big_win) then
            return
        end
        if tax.big_win then
            if table.nums(tax.big_win) == 0 then
                return
            end

            local last_money,last_tax = 0,0
            for _,v in ipairs(tax.big_win) do
                if v[1] < last_money or v[2] < last_tax then
                    return
                end
            end
        end
    end

    return rule
end

function base_club:create_table_template(game_id,desc,rule)
    rule = check_rule(rule)
    if not rule then
        return enum.ERORR_PARAMETER_ERROR
    end

    local id = tonumber(reddb:incr("template:global:id"))

    local info = {
        template_id = id,
        club_id = self.id,
        game_id = game_id,
        description = desc,
        rule = json.encode(rule),
    }

    reddb:hmset(string.format("template:%d",id),info)
    reddb:sadd(string.format("club:template:%d",self.id),id)

    club_template_conf[self.id][id] = nil
    club_template[self.id] = nil
    local _ = table_template[id]
    
    return enum.ERROR_NONE,info
end



function base_club:recusive_broadcast(msgname,msg,except)
    recusive_broadcast(self.id,msgname,msg,except)
end

function base_club:remove_table_template(template_id)
    if not template_id then
        return enum.ERORR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)
    reddb:del(string.format("template:%d",template_id))
    reddb:del(string.format("template:%d:%d",self.id,template_id))
    reddb:srem(string.format("club:template:%d",self.id),template_id)
    table_template[template_id] = nil
    club_template[self.id][template_id] = nil
    club_template_conf[self.id][template_id] = nil

    return enum.ERROR_NONE
end

function base_club:modify_table_template(template_id,game_id,desc,rule)
    if not template_id or not rule or not game_id then
        log.error("modify_table_template template_id is nil.")
        return enum.ERORR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)
    local template = table_template[template_id]
    if not template then
        log.error("modify_table_template template not exists.")
        return enum.ERORR_PARAMETER_ERROR
    end

    if game_id ~= template.game_id then
        log.error("modify_table_template template game_id is modifyed.")
        return enum.ERORR_PARAMETER_ERROR
    end

    if rule then
        rule = check_rule(rule)
        if not rule then
            return enum.ERORR_PARAMETER_ERROR
        end
    end

    local info = {
        template_id = template_id,
        club_id = self.id,
        game_id = (game_id and game_id ~= 0) and game_id or template.game_id,
        description = (desc and desc ~= "") and desc or template.description,
        rule = rule or template.rule,
    }

    local rawtemp = redismetadata.privatetable.template:encode(info)
    reddb:hmset(string.format("template:%d",template_id),rawtemp)

    table_template[template_id] = nil
    club_template[self.id][template_id] = nil

    return enum.ERROR_NONE,info
end

function base_club:notify_money()
    onlineguid.send(self.owner,"SYNC_OBJECT",util.format_sync_info(
        "CLUB",{
            id = self.id,
        },{
            money = club_money[self.id][club_money_type[self.id]],
            commission = club_commission[self.id],
        }
    ))
end

function base_club:incr_commission(money,round_id)
    if money == 0 then return end

    local money_id = club_money_type[self.id]
    if not money_id then
        log.error("base_club:incr_commission [%d] got nil money_id",self.id)
        return
    end

    local newmoney = reddb:incrby(string.format("club:commission:%d",self.id),money)
    newmoney = newmoney and tonumber(newmoney) or 0
    club_commission[self.id] = nil

    channel.call("db.?","msg","SD_LogClubCommission",{
        club = self.id,
        commission = money,
        round_id = round_id or "",
        money_id = money_id,
    })

    self:notify_money()
    return newmoney
end

function base_club:exchange_commission(count)
    local commission = club_commission[self.id]
    if count < 0 then count = commission  end

    if count == 0 then return enum.ERROR_NONE end

    if count < 0 then  return enum.ERORR_PARAMETER_ERROR end
    if count > commission then return enum.ERROR_LESS_MIN_LIMIT  end

    reddb:incrby(string.format("club:commission:%d",self.id),-math.floor(count))
    self:incr_money({
        money_id = club_money_type[self.id],
        money = count,
    },enum.LOG_MONEY_OPT_TYPE_CLUB_COMMISSION)
    self:notify_money()

    return enum.ERROR_NONE
end

function base_club:incr_money(item,why)
    dump(item)
	local oldmoney = tonumber(club_money[self.id][item.money_id]) or 0
	log.info("base_club:incr_money club[%d] money_id[%d]  money[%d]" ,self.id, item.money_id, item.money)
    log.info("base_club:incr_money money[%d] - p[%d]" , oldmoney,item.money)
    
    if oldmoney + item.money_id <= 0 then
        log.warning("base_club:incr_money club[%d] money_id [%d] money[%d] not enough.",self.id,item.money_id,item.money)
        return
    end

	local changes = channel.call("db.?","msg","SD_ChangeClubMoney",{{
		club = self.id,
		money = item.money,
		money_id = item.money_id,
	}},why)

	if table.nums(changes) == 0 or table.nums(changes[1]) == 0 then
		log.error("db incr_money error,club[%d] money_id[%d] oldmoney[%d]",self.id,item.money_id,oldmoney)
		-- return
	end
	
	local dboldmoney = tonumber(changes[1].oldmoney)
	local dbnewmoney = tonumber(changes[1].newmoney)
    dump(dboldmoney)
    dump(oldmoney)
	if dboldmoney ~= oldmoney then
		log.error("db incrmoney error,club[%d] money_id[%d] dboldmoney[%d] oldmoney[%d] ",self.id,item.money_id,oldmoney,dboldmoney)
		-- return
	end

    local newmoney = tonumber(reddb:hincrby(string.format("club:money:%d",self.id),item.money_id,item.money))
    dump(dbnewmoney)
    dump(newmoney)
    if dbnewmoney ~= newmoney then
        log.error("db incrmoney error,club[%d] money_id[%d] dbnewmoney[%d] newmoney[%d]",self.id,item.money_id,newmoney,dbnewmoney)
        -- return
    end
    
    club_money[self.id][item.money_id] = nil
	log.info("incr_money  end oldmoney[%d] new_money[%d]" , oldmoney, newmoney)
	self:notify_money()
	return oldmoney,newmoney
end



return base_club