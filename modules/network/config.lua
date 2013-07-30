--[[
    modules/network/config.lua
]]

local config = {
    --nice name
    name = 'Network',
    --objects we can get & post (/get/<object>, /post/<object>, /templates/objects/<object>)
    objects = {
        device = {
            name = 'Device',
            names = 'Devices',
            title_meta = 'status',
            filters = { 'type', 'config', 'status', 'device_group_id' },
            searches = { 'name' },
            permission = 'Device',
            permissions = {} --for non view/edit/delete permissions (ie edit does most, but not suspend / data commands (for admins/certain groups/etc))
        },
        group = {
            name = 'Group',
            names = 'Groups',
            permission = 'Group',
            --search_fields = { 'name' }
        },
        ipblock = {
            name = 'IP Block',
            names = 'IP Blocks',
            title_meta = 'subnet',
            permission = 'IPBlock',
            filters = { 'type', 'server_id', 'server_group_id' },
            --search_fields = { 'name' }
        }
    },
    --requests to capture
    requests = {
        get = {
            default = { file = 'get/dashboard' },
            publictest = { file = 'get/publictest', public = true }
        },
        post = {
        }
    },
    --auto config
    autoconf = {
        --list services & available software
        devices = function()
            local devices = {}
            for k, device in pairs( ls( 'modules/network/devices' ) ) do
                --config
                device = device:sub( 0, -5 )
                local config = require( 'modules/network/devices/' .. device )
                if not config.hidden then
                    --add to list
                    devices[device] = { software = software, name = config.name, group = config.group }
                end
            end
            return devices
        end,
        --list software
        software = function()
            local software = {}
            for k, os in pairs( ls( 'modules/network/software' ) ) do
                os = os:sub( 0, -5 )
                local conf = require( 'modules/network/software/' .. os )
                software[os] = conf
            end
            return software
        end
    },
    --node files to include
    ngxnode = {
        'ngx.js'
    },
    autonode = {
        'auto.js'
    }
}

return config