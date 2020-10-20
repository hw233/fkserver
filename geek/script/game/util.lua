
local runtime_conf = require "game.runtime_conf"

local util = {}

function util.is_private_fee_free(club)
    return (not runtime_conf.private_fee_switch[0]) or
        (club and not runtime_conf.private_fee_agency_switch[club.owner]) or
        (club and not runtime_conf.private_fee_club_switch[club.id])
end

return util