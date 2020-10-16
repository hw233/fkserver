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
local base_money = require "game.lobby.base_money"
local club_money_type = require "game.club.club_money_type"
local club_money = require "game.club.club_money"
local player_money = require "game.lobby.player_money"
local player_club = require "game.lobby.player_club"
local club_commission = require "game.club.club_commission"
local club_team_template_conf = require "game.club.club_team_template_conf"
local club_team = require "game.club.club_team"
local club_partners = require "game.club.club_partners"
local util = require "util"
local club_conf = require "game.club.club_conf"
local club_member_partner = require "game.club.club_member_partner"
local club_team_money = require "game.club.club_team_money"
local club_partner_commission = require "game.club.club_partner_commission"
local club_partner_conf = require "game.club.club_partner_conf"

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
        status = 0,
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
    reddb:zadd("club:zmember:"..tostring(id),enum.CRT_BOSS,owner_guid)
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

    return c
end

function base_club:exit_from_parent()
    if self.parent and self.parent ~= 0 then
        reddb:srem(string.format("club:team:%d",self.parent),self.id)
    end
end

function base_club:dismiss()
    local money_id = club_money_type[self.id]
    reddb:del(string.format("club:money_type:%d",self.id))
    club_money_type[self.id] = nil

    for mid,_ in pairs(club_member[self.id] or {}) do
        reddb:srem(string.format("player:club:%d:%d",mid,self.type),self.id)
        reddb:hdel(string.format("player:money:%d",mid),money_id)
        player_club[mid][self.type][self.id] = nil
        player_money[mid][money_id] = nil
    end
    reddb:del(string.format("club:memeber:%d",self.id))
    club_member[self.id] = nil

    reddb:del(string.format("club:role:%d",self.id),mid)
    -- 不直接删除club:info,避免重用此club id
    reddb:hmset(string.format("club:info:%d",self.id),{status = 3})
    reddb:hdel(string.format("club:money:%d",self.id),money_id)
    club_money[self.id][money_id] = nil
    club_money[self.id][0] = nil
    reddb:del(string.format("club:commission:%d",self.id))
    club_commission[self.id] = nil
    for tid,_ in pairs(club_template[self.id] or {}) do
        reddb:del(string.format("template:%d",tid))
        reddb:del(string.format("team_conf:%d:%d",self.id,tid))
        club_team_template_conf[self.id][tid] = nil
        table_template[tid] = nil
    end
    reddb:del(string.format("club:template:%d",self.id))
    club_template[self.id] = nil
    if self.parent then
        reddb:srem(string.format("club:team:%d",self.parent),self.id)
    end
    channel.publish("db.?","msg","SD_DismissClub",{ club_id = self.id})
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
        if inviter_role == enum.CRT_ADMIN or inviter_role == enum.CRT_BOSS then
            local partner = club_partners[self.id][self.owner]
            log.dump(partner)
            partner:join(invitee)
        elseif inviter_role == enum.CRT_PARTNER then
            local partner = club_partners[self.id][inviter]
            partner:join(invitee)
        else
            return enum.ERROR_PLAYER_NO_RIGHT
        end

        self:join(invitee,inviter)
        channel.publish("db.?","msg","SD_LogClubActionMsg",{
            club = self.id,
            operator = inviter,
            type = enum.CLUB_ACTION_JOIN,
            msg = {
                team = inviter,
                guid = invitee,
            },
        })
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
    log.dump(request)
    local who = request.who
    local whoee = request.whoee

	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return enum.ERROR_PLAYER_NOT_EXIST
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
    return enum.ERROR_NONE
end

function base_club:reject_request(request)
    local whoee = request.whoee
	local player = base_players[whoee]
	if not player then
		log.error("agree club request,who is unkown,guid:%s",whoee)
		return enum.ERROR_PLAYER_NOT_EXIST
    end

    reddb:srem(string.format("player:request:%s",whoee),request.id)
    reddb:del(string.format("request:%s",request.id))
    return enum.ERROR_NONE
end

function base_club:join(guid,inviter)
    channel.publish("db.?","msg","SD_JoinClub",{club_id = self.id,guid = guid})

    reddb:sadd(string.format("club:member:%s",self.id),guid)
    reddb:zadd(string.format("club:zmember:%s",self.id),enum.CRT_PLAYER,guid)
    reddb:sadd(string.format("player:club:%d:%d",guid,self.type),self.id)
    player_club[guid][self.type] = nil
end

function base_club:batch_join(guids)
    for _,guid in pairs(guids) do
        reddb:sadd(string.format("club:member:%s",self.id),guid)
        reddb:zadd(string.format("club:zmember:%s",self.id),enum.CRT_PLAYER,guid)
        reddb:sadd(string.format("player:club:%d:%d",guid,self.type),self.id)
        player_club[guid][self.type] = nil
    end

    channel.publish("db.?","msg","SD_BatchJoinClub",{club_id = self.id,guids = guids})
end

function base_club:exit(guid)
    local money_id = club_money_type[self.id]
    reddb:srem(string.format("club:member:%s",self.id),guid)
	reddb:zrem(string.format("club:zmember:%s",self.id),guid)
    reddb:srem(string.format("player:club:%d:%d",guid,self.type),self.id)
    reddb:hdel(string.format("player:money:%d",guid),money_id)
    reddb:hdel(string.format("club:role:%d",self.id),guid)

    club_member[self.id][guid] = nil
    player_money[guid][money_id] = nil
    player_club[guid][self.type] = nil
    club_role[self.id][guid] = nil
    channel.publish("db.?","msg","SD_ExitClub",{club_id = self.id,guid = guid})
end

function base_club:broadcast(msgname,msg,except)
    broadcast(self.id,msgname,msg,except)
end

function base_club:is_team_credit_block_play(guid)
    local function is_credit_less(cid,pid)
        local money_id = club_money_type[cid]
        local credit = club_partner_conf[cid][pid].credit or 0
        local team_money = (club_team_money[cid][pid] or 0) + player_money[pid][money_id]
        if team_money < credit then
            return true
        end
    end

    local is_block_switch_on = club_conf[self.id].credit_block_play
    if not is_block_switch_on then
        return 
    end

    local role = club_role[self.id][guid]
    local partner_id
    if role == enum.CRT_PARTNER or role == enum.CRT_BOSS then 
        partner_id = guid
    else
        partner_id = club_member_partner[self.id][guid]
    end

    while partner_id and partner_id ~= 0 do
        if is_credit_less(self.id,partner_id) then
            return true
        end

        partner_id = club_member_partner[self.id][partner_id]
    end
end

function base_club:create_table(player,chair_count,round,rule,template)
    local member = club_member[self.id][player.guid]
    if not member then
        log.warning("create club table,but guid [%s] not exists",player.guid)
        return enum.ERROR_NOT_MEMBER
    end

    if rule and not self:can_sit_down(rule,player) then
        return enum.ERROR_LESS_MIN_LIMIT
    end

    local is_credit_block = self:is_team_credit_block_play(player.guid)
    if is_credit_block then
        return enum.ERROR_CLUB_TEAM_IS_LOCKED
    end
   
    local result,global_tid,tb = g_room:create_private_table(player,chair_count,round,rule,self)
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

function base_club:is_block_in_block_group(tb,player)
    return table.logic_or(tb.players,function(p)
        local inters = reddb:sinter(
            string.format("club:block:player:group:%s:%s",self.id,p.guid),
            string.format("club:block:player:group:%s:%s",self.id,player.guid)
        )

        return table.nums(inters) > 0
    end)
end

function base_club:team_parents_within_layer(player,layer)
    local pids = {}
    local pid = player.guid
    local role = club_role[self.id][pid]
    if club_role[self.id][pid] == enum.CRT_PARTNER then
        table.insert(pids,pid)
    end
    
    for i = 1,layer or math.huge do
        pid = club_member_partner[self.id][pid]
        if not pid or pid == 0 then
            break
        end

        table.insert(pids,pid)
    end

    return pids
end

function base_club:is_block_in_same_team_branch(tb,player)
    if club_conf[self.id].block_partner_player_branch then
        local pids = table.reverse(self:team_parents_within_layer(player))
        return table.logic_or(tb.players,function(p)
            local other_pids = table.reverse(self:team_parents_within_layer(p))
            for i = 2,math.min(#pids,#other_pids) do
                if pids[i] == other_pids[i] then
                    return true
                end
            end
        end)
    end
end

function base_club:is_block_play_in_same_team_layer(tb,player)
    if club_conf[self.id].block_partner_player then
        local pids = self:team_parents_within_layer(player,1)
        return table.logic_or(tb.players,function(p)
            local other_pids = self:team_parents_within_layer(p,1)
            local inter = table.intersect(pids,other_pids,function(l,r) return l == r end)
            return #inter > 0
        end)
    end
end

function base_club:is_block_in_2_team_layer(tb,player)
    if club_conf[self.id].block_partner_player_2_layer then
        local pids = table.reverse(self:team_parents_within_layer(player,2))
        if pids[1] == self.owner then
            table.remove(pids,1)
        end
        return table.logic_or(tb.players,function(p)
            local other_pids = self:team_parents_within_layer(p,2)
            if other_pids[1] == self.owner then
                table.remove(pids,1)
            end
            local inter = table.intersect(pids,other_pids,function(l,r) return l == r end)
            log.dump(inter)
            return #inter > 0
        end)
    end
end

function base_club:join_table(player,private_table,chair_count)
    local rule = private_table.rule
    if rule and not self:can_sit_down(rule,player) then
        return enum.ERROR_LESS_GOLD
    end

    if self:is_team_credit_block_play(player.guid) then
        return enum.ERROR_CLUB_TEAM_IS_LOCKED
    end

    local tb = g_room:find_table(private_table.real_table_id)
    if  self:is_block_in_block_group(tb,player) or
        self:is_block_play_in_same_team_layer(tb,player) or
        self:is_block_in_same_team_branch(tb,player) or
        self:is_block_in_2_team_layer(tb,player)
    then
        return enum.ERROR_CLUB_TABLE_JOIN_BLOCK
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
            if  type(tax.big_win) ~= "table" or
                table.nums(tax.big_win) == 0 or
                not table.logic_and(tax.big_win,function(v) return type(v) == "table" end)
            then
                return
            end
        end
    end

    return rule
end

function base_club:create_table_template(game_id,desc,rule)
    rule = check_rule(rule)
    if not rule then
        return enum.ERROR_PARAMETER_ERROR
    end

    local id = tonumber(reddb:incr("template:global:id"))

    local info = {
        template_id = id,
        club_id = self.id,
        game_id = game_id,
        description = desc,
        rule = rule,
    }

    reddb:hmset(string.format("template:%d",id),info)
    reddb:sadd(string.format("club:template:%d",self.id),id)

    club_template_conf[self.id][id] = nil
    club_template[self.id] = nil
    local _ = table_template[id]

    channel.publish("db.?","msg","SD_CreateClubTemplate",{
        club_id = self.id,
        rule = rule,
        description = desc,
        game_id = game_id,
        id = id,
    })
    
    return enum.ERROR_NONE,info
end


function base_club:recusive_broadcast(msgname,msg,except)
    recusive_broadcast(self.id,msgname,msg,except)
end

function base_club:remove_table_template(template_id)
    if not template_id then
        return enum.ERROR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)
    reddb:hmset(string.format("template:%d",template_id),{ status = 1 })
    reddb:del(string.format("template:%d:%d",self.id,template_id))
    reddb:srem(string.format("club:template:%d",self.id),template_id)
    table_template[template_id] = nil
    club_template[self.id][template_id] = nil
    club_template_conf[self.id][template_id] = nil

    channel.publish("db.?","msg","SD_RemoveClubTemplate",{
        id = template_id,
    })

    return enum.ERROR_NONE
end

function base_club:modify_table_template(template_id,game_id,desc,rule)
    if not template_id or not rule or not game_id then
        log.error("modify_table_template template_id is nil.")
        return enum.ERROR_PARAMETER_ERROR
    end

    template_id = tonumber(template_id)
    local template = table_template[template_id]
    if not template then
        log.error("modify_table_template template not exists.")
        return enum.ERROR_PARAMETER_ERROR
    end

    if game_id ~= template.game_id then
        log.error("modify_table_template template game_id is modifyed.")
        return enum.ERROR_PARAMETER_ERROR
    end

    if rule then
        rule = check_rule(rule)
        if not rule then
            return enum.ERROR_PARAMETER_ERROR
        end
    end

    local info = {
        template_id = template_id,
        club_id = self.id,
        game_id = (game_id and game_id ~= 0) and game_id or template.game_id,
        description = (desc and desc ~= "") and desc or template.description,
        rule = rule or template.rule,
    }

    reddb:hmset(string.format("template:%d",template_id),info)

    table_template[template_id] = nil
    club_template[self.id][template_id] = nil

    channel.publish("db.?","msg","SD_EditClubTemplate",{
        club_id = self.id,
        rule = rule,
        description = desc,
        game_id = game_id,
        id = template_id,
    })

    return enum.ERROR_NONE,info
end

function base_club:notify_money(money_id)
    local admins = table.series(club_role[self.id][nil],function(_,guid) return guid end)
    onlineguid.broadcast(admins,"SYNC_OBJECT",util.format_sync_info(
        "CLUB",{
            id = self.id,
        },{
            money = club_money[self.id][money_id],
            commission = club_commission[self.id],
            money_id = money_id,
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
        parent = self.parent,
        club = self.id,
        commission = money,
        round_id = round_id or "",
        money_id = money_id,
    })

    self:notify_money(money_id)
    return newmoney
end

function base_club:exchange_commission(count)
    local commission = club_commission[self.id]
    if count < 0 then count = commission  end

    if count == 0 then return enum.ERROR_NONE end

    if count < 0 then  return enum.ERROR_PARAMETER_ERROR end
    if count > commission then return enum.ERROR_LESS_MIN_LIMIT  end

    reddb:incrby(string.format("club:commission:%d",self.id),-math.floor(count))
    local money_id = club_money_type[self.id]
    self:incr_money({
        money_id = money_id,
        money = count,
    },enum.LOG_MONEY_OPT_TYPE_CLUB_COMMISSION)
    self:notify_money(money_id)

    return enum.ERROR_NONE
end

function base_club:incr_money(item,why,why_ext)
    log.dump(item)
	local oldmoney = tonumber(club_money[self.id][item.money_id]) or 0
	log.info("base_club:incr_money club[%d] money_id[%d]  money[%d]" ,self.id, item.money_id, item.money)
    log.info("base_club:incr_money money[%d] - p[%d]" , oldmoney,item.money)
    
    if oldmoney + item.money <= 0 then
        log.warning("base_club:incr_money club[%d] money_id [%d] money[%d] not enough.",self.id,item.money_id,item.money)
        return
    end

	local changes = channel.call("db.?","msg","SD_ChangeClubMoney",{{
		club = self.id,
		money = item.money,
		money_id = item.money_id,
	}},why,why_ext)

	if table.nums(changes) == 0 or table.nums(changes[1]) == 0 then
		log.error("db incr_money error,club[%d] money_id[%d] oldmoney[%d]",self.id,item.money_id,oldmoney)
		-- return
	end
	
	local dboldmoney = tonumber(changes[1].oldmoney)
	local dbnewmoney = tonumber(changes[1].newmoney)
    log.dump(dboldmoney)
    log.dump(oldmoney)
	if dboldmoney ~= oldmoney then
		log.error("db incrmoney error,club[%s] money_id[%s] dboldmoney[%s] oldmoney[%s] ",self.id,item.money_id,oldmoney,dboldmoney)
		-- return
    end

    local newmoney = tonumber(reddb:hincrby(string.format("club:money:%d",self.id),math.floor(item.money_id),math.floor(item.money)))
    log.dump(dbnewmoney)
    log.dump(newmoney)
    if dbnewmoney ~= newmoney then
        log.error("db incrmoney error,club[%s] money_id[%s] dbnewmoney[%s] newmoney[%s]",self.id,item.money_id,newmoney,dbnewmoney)
        -- return
    end
    
    club_money[self.id][item.money_id] = nil
	log.info("incr_money  end oldmoney[%s] new_money[%s]" , oldmoney, newmoney)
	self:notify_money(item.money_id)
	return oldmoney,newmoney
end

function base_club:incr_redis_money(money_id,money)
    local newmoney = tonumber(reddb:hincrby(string.format("club:money:%d",self.id),math.floor(money_id),math.floor(money)))
    self:notify_money(money_id)
    return newmoney
end

function base_club:check_money_limit(money,money_id)
    local self_money = club_money[self.id][money_id] or 0
    return self_money < money
end

function base_club:incr_member_money(guid,delta_money,why,why_ext)
    local player = base_players[guid]
    if not player or not club_member[self.id][guid] then
        log.error("base_club:incr_member_money got nil player or not member,club:%s,guid:%s",self.id,guid)
        return
    end

    delta_money = math.floor(delta_money)
    player:incr_money({
            money_id = club_money_type[self.id],
            money = delta_money,
        },why,why_ext)

    local partner = club_member_partner[self.id][guid]
    while partner and partner ~= 0 do
        reddb:hincrby(string.format("club:team_money:%s",self.id),partner,delta_money)
        partner = club_member_partner[self.id][partner]
    end
end

function base_club:incr_member_redis_money(guid,delta_money)
    local player = base_players[guid]
    if not player or not club_member[self.id][guid] then
        log.error("base_club:incr_member_money got nil player or not member,club:%s,guid:%s",self.id,guid)
        return
    end

    local money_id = club_money_type[self.id]
    local new_money = player:incr_redis_money(money_id,delta_money,self.id)

    local partner = club_member_partner[self.id][guid]
    while partner and partner ~= 0 do
        reddb:hincrby(string.format("club:team_money:%s",self.id),partner,delta_money)
        partner = club_member_partner[self.id][partner]
    end

    return new_money
end

function base_club:exchange_team_commission(partner_id,money)
    local commission = club_partner_commission[self.id][partner_id]
    if money < 0 then money = commission  end

    if money == 0 then return enum.ERROR_NONE end

    if money < 0 then  return enum.ERROR_PARAMETER_ERROR end

    if money > commission then return enum.ERROR_LESS_MIN_LIMIT  end

    money = math.floor(money)
    reddb:hincrby(string.format("club:partner:commission:%s",self.id),partner_id,-money)
    self:incr_member_money(partner_id,money,enum.LOG_MONEY_OPT_TYPE_CLUB_COMMISSION)
    club_partners[self.id][partner_id]:notify_money()

    return enum.ERROR_NONE
end

function base_club:incr_team_commission(partner_id,money,round_id)
    if money == 0 then return end

    if not channel.call("db.?","msg","SD_LogPlayerCommission",{
        club = self.id,
        commission = money,
        round_id = round_id or "",
        money_id = club_money_type[self.id],
        guid = partner_id,
    }) then
        log.error("base_club:incr_team_commission unknown db error.")
        return
    end

    local newmoney = reddb:hincrby(string.format("club:partner:commission:%d",self.id),partner_id,money)
    newmoney = newmoney and tonumber(newmoney) or 0
    club_partner_commission[self.id] = nil

    club_partners[self.id][partner_id]:notify_money()
    return newmoney
end

return base_club