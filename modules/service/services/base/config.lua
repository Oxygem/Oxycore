--[[
    file: modules/service/services/base/config.lua
    desc: js includes on all services
]]
local config = {
    hidden = true, --no need to display anywhere

    --tabs
    tabs = {
        { name = 'Data', js = 'data', permission = 'data' },
    },

    --javascript file(s) to load on service page
    js = {
        'service/jquery.cookie.js',
        'service/socket.io.min.js',
        'service/ssh.js',
        'service/service.js'
    }
}

return config