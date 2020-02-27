local base_clubs = require "game.club.base_clubs"

local utils = {}

function utils.parent(club)
    club = type(club) == "table" and club or base_clubs[club]
    if club.parent and club.parent ~= 0 then
        return base_clubs[club.parent]
    end
end

function utils.root(club)
    if not club then return end
    club = type(club) == "table" and club or base_clubs[club]
    local parent = utils.parent(club)
    return (parent and utils.root(parent) or club)
end

function utils.level(club,level)
    level = level and level + 1 or 1
    if not club then return level end
    club = type(club) == "table" and club or base_clubs[club]
    local parent = utils.parent(club)
    return parent and utils.level(parent,level) or level
end

return utils