local skynet = require "skynetproto"

skynet.start(function() 
    require "login.logind"
end)