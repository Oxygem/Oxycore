-- File: config.lua
-- Desc: network module config

local config = {
    --nice name
    name = 'Network',
    order = 1,
    --objects we can get & post (/get/<object>, /post/<object>, /templates/objects/<object>)
    objects = {
        device = {
            name = 'Device',
            names = 'Devices',
            title_meta = '{host}',
            filters = { 'type', 'config', 'status', 'device_group_id' },
            actions = { console = { permission = 'console', wrap = false } }, --action = { permission / wrap template }
            searches = { 'name' },
            permission = 'Device',
            permissions = { 'Console' } --for non view/edit/delete permissions
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
            title_meta = '{subnet}',
            permission = 'IPBlock',
            filters = { 'type' },
            --search_fields = { 'name' }
        }
    },
    --requests to capture
    requests = {
        get = {
            default = { file = 'get/dashboard' }
        },
        post = {
            devices = { file = 'post/devices' },
            ipblocks = { file = 'post/ipblocks' },
            groups ={ file = 'post/groups' }
        }
    },
    --auto config
    autoconf = {
        --list services & available software
        devices = function()
            local devices = {}
            for k, device in pairs( ls( 'modules/network/devices/*.lua' ) ) do
                --config
                local a, b, device = device:find( 'modules/network/devices/([a-z]+)\.lua' )
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
        'ngx/core.js'
    },
    autonode = {
        'auto/core.js'
    }
}

return config