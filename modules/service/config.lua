--[[
    modules/service/config.lua
]]

local config = {
    --nice name
    name = 'Service',
    --objects we can get & post (/get/<object>, /post/<object>, /templates/objects/<object>)
    objects = {
        service = {
            name = 'Service',
            names = 'Services',
            title_meta = 'status',
            filters = { 'type', 'status', 'service_group_id' },
            search_fields = { 'name', 'type' },
            permissions = { 'data', 'suspend' } --for non view/edit/delete permissions (ie edit does most, but not suspend / data commands (for admins/certain groups/etc))
        },
        group = {
            name = 'Group',
            names = 'Groups',
            search_fields = { 'name' }
        },
        ipblock = {
            name = 'IP Block',
            names = 'IP Blocks',
            filters = { 'type', 'service_id', 'service_group_id' },
            search_fields = { 'name' }
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
        services = function()
            local services = {}
            for k, service in pairs( ls( 'modules/service/services' ) ) do
                --config
                service = service:sub( 0, -5 )
                local config = require( 'modules/service/services/' .. service )
                --add to list
                services[service] = { software = software, name = config.name, names = config.names, parent = config.parent, hidden = config.hidden }
            end
            return services
        end,
        --list software
        software = function()
            local software = {}
            for k, os in pairs( ls( 'modules/service/software' ) ) do
                os = os:sub( 0, -5 )
                local conf = require( 'modules/service/software/' .. os )
                software[os] = conf
            end
            return software
        end,
        --list os's
        oses = function()
            local oses = {}
            for k, os in pairs( ls( 'modules/service/oses' ) ) do
                os = os:sub( 0, -5 )
                local conf = require( 'modules/service/oses/' .. os )
                oses[os] = conf
            end
            return oses
        end
    },
    --permissions
    permissions = {
    },
    --node files to include
    node = {
        'ssh.js'
    }
}

return config