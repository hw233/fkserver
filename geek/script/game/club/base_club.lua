local redisopt = require "redisopt"
local log = require "log"
require "functions"
local base_players = require "game.lobby.base_players"
local club_member = require "game.club.club_member"
local base_private_table = require "game.lobby.base_private_table"
local table_template = require "game.lobby.table_template"
local club_table_template = require "game.club.club_table_template"
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

local reddb = redisopt.default

local table_expire_seconds = 60 * 60 * 5

local base_club = {}

function base_club:create(id,name,icon,owner,tp,parent)
    id = tonumber(id)
    local owner_guid = type(owner) == "number" and owner or owner.guid
    local c = {
        name = name,
        icon = icon,
        id = id,
        owner = owner_guid,
        type = tp,
        parent = parent,
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
        return
    end

    if (not parent or parent == 0) and tp == enum.CT_UNION then
        reddb:hmset(string.format("money:info:%d",money_info.id),{
            id = money_info.id,
            club = id,
            type = enum.MONEY_TYPE_GOLD,
        })
    end

    reddb:set(string.format("club:money_type:%d",id),money_info.id)
    reddb:hset(string.format("club:money:%d",id),money_info.id,0)
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
    c.tables = {}
    setmetatable(c,base_club)
    base_club[id] = c

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
    if except then
        except = type(except) == "number" and except or except.guid
    end
    for guid,_ in pairs(club_member[self.id]) do
        if not except or except ~= guid then
            onlineguid.send(guid,msgname,msg)
        end
    end
end

function base_club:create_table(player,chair_count,round,conf,template)
    local member = club_member[self.id][player.guid]
    if not member then
        log.warning("create club table,but guid [%s] not exists",player.guid)
        return enum.ERROR_NOT_IS_CLUB_MEMBER
    end

    if template and not self:can_sit_down(template,player) then
        return enum.ERROR_LESS_MIN_LIMIT
    end

    local result,global_tid,tb = g_room:create_private_table(player,chair_count,round,conf)
    if result == enum.GAME_SERVER_RESULT_SUCCESS then
        reddb:hmset(string.format("table:info:%d",global_tid),{
            club_id = self.id,
            template = template and template.id or nil,
        })

        reddb:sadd("club:table:"..self.id,global_tid)
        reddb:expire("club:table:"..self.id,table_expire_seconds)
        base_private_table[global_tid].club_id = self.id
    end

    return result,global_tid,tb
end

--玩家坐下积分检测
function base_club:can_sit_down(template,player)
    local advanced_rule = template.advanced_rule
    if not advanced_rule then
        return true
    end

    local entry_score = advanced_rule.entry_score

    local money_id = club_money_type[self.id]
    local money = player_money[player.guid][money_id]
    dump(money)
    return money >= entry_score
end

--玩家积分破产
function base_club:is_player_bankrupt(template,player)
    local advanced_rule = template.advanced_rule
    if not advanced_rule then
        return false
    end

    local min_score = advanced_rule.min_score
    if not min_score then
        return false
    end

    local money_id = club_money_type[self.id]
    local money = player_money[player.guid][money_id]
    return min_score > money
end

function base_club:join_table(player,private_table,chair_count)
    local template = table_template[private_table.template]
    if template and not self:can_sit_down(template,player) then
        return enum.ERROR_LESS_MIN_LIMIT
    end

    return g_room:join_private_table(player,private_table,chair_count)
end


function base_club:create_table_template(game_id,desc,rule,advanced_rule)
    local ok,ruletb = pcall(json.decode,rule) 
    if not ok or not ruletb then
        return enum.ERORR_PARAMETER_ERROR
    end
    local id = tonumber(reddb:incr("template:global:id"))

    local info = {
        template_id = id,
        club_id = self.id,
        game_id = game_id,
        description = desc,
        rule = type(rule) == "string" and rule or json.encode(rule),
        advanced_rule = type(advanced_rule) == "string" and advanced_rule or json.encode(advanced_rule),
    }

    reddb:hmset(string.format("template:%d",id),info)
    reddb:sadd(string.format("club:template:%d",self.id),id)
    reddb:hmset(string.format("conf:%d:%d",self.id,id),
        redismetadata.conf:encode({
            visual = true,
            conf = {
                self_comission = 0,
            },
            club_id = self.id,
            template_id = id,
        })
    )

    club_template_conf[self.id][id] = nil
    club_table_template[self.id] = nil
    local _ = table_template[id]

    advanced_rule = type(advanced_rule) == "string" and json.decode(advanced_rule) or advanced_rule
    local tax = advanced_rule and advanced_rule.tax and advanced_rule.tax.AA or advanced_rule.tax.big_win[3][2] or 0
    
    self:broadcast("S2C_NOTIFY_TABLE_TEMPLATE",{
        sync = enum.SYNC_ADD,
        template = {
            template = info,
            club_id = self.id,
            visual = true,
            conf = json.encode({
                self_commission = 0,
                commission = tax,
            })
        }
    })

    return enum.ERROR_NONE,info
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
    club_table_template[self.id][template_id] = nil
    club_template_conf[self.id][template_id] = nil

    self:broadcast("S2C_NOTIFY_TABLE_TEMPLATE",{
        sync = enum.SYNC_DEL,
        template = {
            template = {
                template_id = template_id,
            },
            club_id = self.id,
        }
    })

    return enum.ERROR_NONE
end

function base_club:modify_table_template(template_id,game_id,desc,rule,advanced_rule)
    if not template_id then
        log.error("modify_table_template template_id is nil.")
        return enum.ERORR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)
    local template = table_template[template_id]
    if not template then
        log.error("modify_table_template template not exists.")
        return enum.ERORR_PARAMETER_ERROR
    end

    local info = {
        template_id = template_id,
        club_id = self.id,
        game_id = (game_id and game_id ~= 0) and game_id or template.game_id,
        description = (desc and desc ~= "") and desc or template.description,
        rule = rule or template.rule,
        advanced_rule = advanced_rule or template.advanced_rule
    }

    local rawtemp = redismetadata.privatetable.template:encode(info)
    reddb:hmset(string.format("template:%d",template_id),rawtemp)

    table_template[template_id] = nil
    club_table_template[self.id][template_id] = nil 
    
    local tax = advanced_rule and advanced_rule.tax and advanced_rule.tax.AA or advanced_rule.tax.big_win[3][2] or 0
    self:broadcast("S2C_NOTIFY_TABLE_TEMPLATE",{
        sync = enum.SYNC_UPDATE,
        template = {
            template = rawtemp,
            club_id = self.id,
            visual = true,
            conf = json.encode({
                self_commission = 0,
                commission =  tax,
            }),
        },
    })

    return enum.ERROR_NONE,info
end

function base_club:notify_money(why,oldmoney,changemoney,money_id)
    
end

function base_club:incr_money(item,why)
	local oldmoney = tonumber(club_money[self.id][item.money_id]) or 0
	log.info("club[%d] money_id[%d]  money[%d]" ,self.id, item.money_id, item.money)
	log.info("money[%d] - p[%d]" , oldmoney,item.money)

	local changes = channel.call("db.?","msg","SD_ChangeClubMoney",{{
		club = self.id,
		money = item.money,
		money_id = item.money_id,
	}},why)

	if table.nums(changes) == 0 or table.nums(changes[1]) == 0 then
		log.error("db incr_money error,club[%d] money_id[%d] oldmoney[%d]",self.id,item.money_id,oldmoney)
		return
	end
	
	local dboldmoney = tonumber(changes[1].oldmoney)
	local dbnewmoney = tonumber(changes[1].newmoney)
    dump(dboldmoney)
    dump(oldmoney)
	if dboldmoney ~= oldmoney then
		log.error("db incrmoney error,club[%d] money_id[%d] oldmoney[%d] dboldmoney[%d]",self.id,item.money_id,oldmoney,dboldmoney)
		return
	end

    local newmoney = tonumber(reddb:hincrby(string.format("club:money:%d",self.id),item.money_id,item.money))
    dump(dbnewmoney)
    dump(newmoney)
    if dbnewmoney ~= newmoney then
        log.error("db incrmoney error,club[%d] money_id[%d] newmoney[%d] dbnewmoney[%d]",self.id,item.money_id,newmoney,dbnewmoney)
        return
    end
    
    club_money[self.id][item.money_id] = nil
	log.info("incr_money  end oldmoney[%d] new_money[%d]" , oldmoney, newmoney)
	self:notify_money(why,oldmoney,newmoney-oldmoney,item.money_id)
	return oldmoney,newmoney
end



return base_club