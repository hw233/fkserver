
local tree = require "redisorm.meta"

tree.player.all = "set"
tree.player.all["%d+"] = "number"

tree.player.info["%d+"] = "hash"
tree.player.info["%d+"] = {
    guid = "number",
    account  = "string",
    nickname = "string",
    bank = "number",
    is_android = "number",
    level = "number",
    login_time = "number",
    logout_time = "number",
    login_award_day = "number",
    login_award_receive_day = "number",
    header_icon = "number",
    platform_id = "number",
    is_collapse = "number",
    sex = "number",
    icon = "string",
    app_id = "string",
    is_guest = "number",
    vip = "number",
    is_locked = "number",
    tickets = "number",
    user_type = "number",
    status = "number",
    role = "number",
    gps_latitude = "number",
    gps_longitude = "number",
}

tree.player.money["%d+"] = "number_hash" 
tree.player.money["%d+"]["%d+"] = "number"

tree.player.winlose["%d+"] = "number_hash" 
tree.player.winlose["%d+"]["%d+"] = "number"

tree.player.club["%d+"]["%d+"] = "set"
tree.player.club["%d+"]["%d+"]["%d+"] = "number"

tree.player.auth_id["%s+"] = "string"
tree.player.account["%s+"] = "number"
tree.player.phone_uuid["%d+"] = "string"

tree.player.online.count = "number"
tree.player.online.count["%s+"]["%d+"]["%d+"] = "number"
tree.player.online.count["%s+"]["%d+"]["%d+"]["%d+"] = "number"

tree.player.online.all = "set"
tree.player.online["%d+"] = "number"

tree.player.online.guid["%d+"] = "hash"
tree.player.online.guid["%d+"] = {
    gate = "number",
    server  = "number",
    first_game_type = "number",
    second_game_type = "number",
    room_id = "number",
    table_id = "number",
    chair_id = "number",
    table = "number",
    chair = "number",
    game = "number",
    global_table = "number",
}

tree.player.request["%d+"] = "set"
tree.player.request["%d+"]["%d+"] = "number"

tree.player.mail["%d+"] = "set"
tree.player.mail["%d+"]["%d+"] = "number"

tree.club.all = "set"
tree.club.all["%d+"] = "number"

tree.club.info["%d+"] = "hash"
tree.club.info["%d+"] = {
    id = "number",
    level = "number",
    status = "number",
    online_count = "number",
    owner = "number",
    type = "number",
    parent = "number",
    agentlevel = "number",
}

tree.club.game["%d+"] = "set"
tree.club.game["%d+"]["%d+"] = "number"
tree.club.member["%d+"] = "set"
tree.club.member["%d+"]["%d+"] = "number"
tree.club.member.count["%d+"] = "number"
tree.club.member.partner["%d+"] = "number_hash"
tree.club.member.partner["%d+"]["%d+"] = "number"
tree.club.member.online.count["%d+"] = "number"
tree.club.member.online.guid["%d+"] = "set"
tree.club.member.online.guid["%d+"]["%d+"] = "number"
tree.club.money["%d+"] = "number_hash"
tree.club.money["%d+"]["%d+"] = "number"
tree.club.money_type["%d+"] = "number"
tree.club.partner.member["%d+"]["%d+"] = "set"
tree.club.partner.member["%d+"]["%d+"]["%d+"] = "number"
tree.club.partner.commission["%d+"] = "number_hash"
tree.club.partner.commission["%d+"]["%d"] = "number"
tree.club.partner.commision.conf["%d+"] = "number_hash"
tree.club.partner.commision.conf["%d+"]["%d+"] = "json"
tree.club.role["%d+"] = "number_hash"
tree.club.role["%d+"]["%d+"] = "number"
tree.club.template["%d+"] = "set"
tree.club.template["%d+"]["%d+"] = "number"
tree.club.block.group.id = "number"
tree.club.block.groups["%d+"] = "set"
tree.club.block.groups["%d+"]["%d+"] = "number"
tree.club.block.player.group["%d+"]["%d+"] = "set"
tree.club.block.player.group["%d+"]["%d+"]["%d+"] = "number"
tree.club.block.group.player["%d+"]["%d+"] = "set"
tree.club.block.group.player["%d+"]["%d+"]["%d+"] = "number"

tree.club.block.tgroup.id = "number"
tree.club.block.team.group.all["%d+"] = "set"
tree.club.block.team.group.all["%d+"]["%d+"] = "number"
tree.club.block.team.group["%d+"]["%d+"] = "set"
tree.club.block.team.group["%d+"]["%d+"]["%d+"] = "number"
tree.club.block.group.team["%d+"]["%d+"] = "set"
tree.club.block.group.team["%d+"]["%d+"]["%d+"] = "number"

tree.club.blacklist.gaming["%d+"] = "set"
tree.club.blacklist.gaming["%d+"]["%d+"] = "number"

tree.club.request["%d+"] = "set"
tree.club.request["%d+"]["%d+"] = "number"
tree.club.conf["%d+"] = "hash"
tree.club.conf["%d+"] = {
    block_partner_player = "bool",
    credit_block_play = "bool",
    credit_block_score = "bool",
    block_partner_player_branch = "bool",
    block_partner_player_2_layer = "bool",
    admin_analysis = "bool",
    auto_cash_commission = "json",
    allow_search_record_no_limit = "bool",
    limit_online_player_num = "bool",
    limit_table_num = "bool",
}
tree.club.table["%d+"] = "set"
tree.club.table["%d+"]["%d+"] = "number"

tree.club.team["%d+"] = "set"
tree.club.team["%d+"]["%d+"] = "number"


tree.club.commission.template.default["%d+"]["%d+"] = "number_hash"
tree.club.commission.template.default["%d+"]["%d+"]["%d+"] = "json"
tree.club.commission.template["%d+"]["%d+"] = "number_hash"
tree.club.commission.template["%d+"]["%d+"]["%d+"] = "json"

tree.club.partner.conf["%d+"]["%d+"] = "hash"
tree.club.partner.conf["%d+"]["%d+"] = {
    credit = "number",
    status = "number",
    commission = "json",
}

tree.club.agentlevel["%d+"] = "number_hash"
tree.club.agentlevel["%d+"]["%d+"] = "number"

tree.club.notice["%d+"] = "set"
tree.club.notice["%d+"]["%d+"] = "number"
tree.club.team.exchange.time["%d+"] = "hash"
tree.club.team.exchange.time["%d+"]["%d+"] = "number"

tree.conf["%d+"] = "hash"
tree.conf["%d+"] = {
    commission = "number",
    commission_rate = "number",
    visual = "bool",
    club_id = "number",
    template_id = "number",
    team_commission_rate = "number",
    partner_id = "number",
}

tree.request.all = "set"
tree.request.all["%d+"] = "number"
tree.request.global.id = "number"
tree.request["%d+"] = "hash"
tree.request["%d+"] = {
    club_id = "number",
    id = "number",
    type = "string",
    who = "number",
    whoee = "number",
}

tree.table.all = "set"
tree.table.all["%d+"] = "number"

tree.table.info["%d+"] = "hash"
tree.table.info["%d+"] = {
    club_id = "number",
    table_id = "number",
    game_type = "number",
    rule = "json",
    owner = "number",
    real_table_id = "number",
    room_id = "number",
    create_time = "number",
    template = "number",
}

tree.template.all = "set"
tree.template.all["%d+"] = "number"

tree.template["%d+"] = "hash"
tree.template["%d+"] = {
    template_id = "number",
    game_type = "number",
    rule = "json",
    description = "string",
    game_id = "number",
    club_id = "number",
    advanced_rule = "json",
}

tree.mail.all = "set"
tree.mail["%d+"] = "hash"
tree.mail["%d+"] = {
    email_id = "string",
    sender = "number",
    reciever = "number",
    expire = "number",
    content = "json",
    status = "number",
    create_time = "number",
}

tree.money.all = "set"
tree.money.all["%d+"] = "number"
tree.money.global = "number"
tree.money.info["%d+"] = "hash"
tree.money.info["%d+"] = {
    id = "number",
    club = "number",
    type = "number",
}

tree.notice.all = "set"
tree.notice.all["%d+"] = "string"
tree.notice.info["%S+"] = "hash"
tree.notice.info["%S+"] = {
    id = "string",
    club_id = "number",
    club = "number",
    type = "number",
    where = "number",
    content = "string",
    expiration = "number",
    create_time = "number",
    status = "number",
    start_time = "number",
    end_time = "number",
    play_count = "number",
    interval = "number",
}

tree.runtime_conf.private_fee["-?%d+"] = "number"
tree.runtime_conf.global.h5_login = "number"
tree.runtime_conf.channel_game["%S+"] = "set"
tree.runtime_conf.channel_game["%S+"]["%d+"] = "number"
tree.runtime_conf.promoter_game["%S+"] = "set"
tree.runtime_conf.promoter_game["%S+"]["%d+"] = "number"
tree.runtime_conf.club_game["%S+"] = "set"
tree.runtime_conf.club_game["%S+"]["%d+"] = "number"
tree.runtime_conf.game_maintain_switch["%d+"] = "bool"
tree.runtime_conf.global.maintain_switch = "bool"
tree.club.team.template["%d+"]["%d+"] = "set"
tree.club.team.template["%d+"]["%d+"]["%d+"] = "number"


tree.game.all = "set"
tree.game.all["%d+"] = "number"

tree.game.level["%d+"] = "set"
tree.game.level["%d+"]["%d+"] = "number"

tree.verify.ip_accounts["%s+"] = "set"
tree.verify.ip_accounts["%s+"]["%d+"] = "number"
tree.verify.imei_accounts["%s+"] = "set"
tree.verify.imei_accounts["%s+"]["%d+"] = "number"


tree.verify.password_error_counts["%d+"] = "hash"
tree.verify.password_error_counts["%d+"]["%s+"] = "number"

tree.verify.account_lock_imei["%d+"] = "set"

tree.verify.ip_auth_accounts["%d+"] = "hash"
tree.verify.ip_auth_accounts["%d+"] = {
    limit = "number",
    curcount = "number",
    limitstart = "number",
}

tree.verify.imei_error_count["%s+"] = "number"

return tree
