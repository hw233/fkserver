local base_mail = require "game.mail.base_mail"
local reddot = require "game.reddot.reddot"


function on_cs_red_dot(msg,guid)
    local mail_reddot = base_mail.get_reddot_info(guid)
    reddot.push(guid,mail_reddot)
end