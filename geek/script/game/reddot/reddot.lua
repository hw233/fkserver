local onlineguid = require "netguidopt"

local reddot = {}

function reddot.push(guid,info)
    onlineguid.send(guid,"SC_RED_DOT",{
        red_dots = {info}
    })
end

return reddot