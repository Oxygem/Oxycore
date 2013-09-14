--[[
    file: modules/service/services/base/config.lua
    desc: js includes on all services
]]
local config = {
    hidden = true, --no need to display anywhere
    name = 'Base',

    --tabs
    tabs = {
    },

    commands = {
        --ssh console
        console = {
            permission = 'console',
            actions = {
                { action = 'console' }
            }
        },
    },

    --javascript file(s) to load on service page
    js = {
        'lib/jquery.cookie.js',
        'lib/socket.io.min.js',
        'ssh.js',
        'device.js'
    }
}

return config