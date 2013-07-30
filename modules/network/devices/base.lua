--[[
    file: modules/service/services/base/config.lua
    desc: js includes on all services
]]
local config = {
    hidden = true, --no need to display anywhere
    name = 'Base',

    --tabs
    tabs = {
        { name = 'Console', js = 'console', permission = 'edit', order = 98, buttons = {
            { name = 'Start Console', command = 'status', color = 'lightgreen' }
        } },

        { name = 'Monitors', js = 'monitor', permission = 'view', order = 99, buttons = {
            { name = 'Add Monitor', command = 'status', color = 'lightgreen' }
        } }
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