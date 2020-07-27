
local club_role = require "game.club.club_role"
local enum = require "pb_enums"
local club_partner = require "game.club.club_partner"
local club_member_partner = require "game.club.club_member_partner"

local club_partners = setmetatable({},{
    __index = function(_,club_id)
        return setmetatable({},{
            __index = function(_,guid)
                local role = club_role[club_id][guid]
                if role ~= enum.CRT_PARTNER and role ~= enum.CRT_BOSS then
                    return nil
                end

                local cp = setmetatable({
                    club_id = club_id,
                    guid = guid,
                    parent = club_member_partner[club_id][guid],
                },{
                    __index = club_partner,
                })

                return cp
            end
        })
    end
})

return club_partners