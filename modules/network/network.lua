--[[
    file: <network module>/network.lua
    desc: core network module file
]]

--get oxy & co
local oxy, user = oxy, luawa.user

--define the network module
local network = {
    --setup each object class
    device = oxy.object:new( 'device' ),
    ipblock = oxy.object:new( 'ipblock' ),
    group = oxy.object:new( 'group' ),

    --ssh connecting
    ssh = require( oxy.config.root .. 'modules/network/ssh' ),

    --ip/subnet processing
    ipv4 = require( oxy.config.root .. 'modules/network/ipv4' ),
    ipv6 = require( oxy.config.root .. 'modules/network/ipv6' )
}


--home dashboard display
function network:dashboard()
    return {'data', test = 'he'}
end


--generate subnav (cached in session)
function network:subnav()
    local nav = {}

    --servers (+define nav)
    if user:checkPermission( 'ViewOwnDevice' ) then
        local servernav = { title = 'Devices', link = '/devices', submenus = {} }

        local admin = {}
        if user:checkPermission( 'ViewAnyDevice' ) then table.insert( admin, { title = 'View All', link = '/devices/all' } ) end
        if user:checkPermission( 'AddDevice' ) then table.insert( admin, { title = 'Add Device', link = '/devices/add' } ) end
        if #admin > 0 then servernav.submenus['Admin'] = admin end

        local devices = self:getDeviceList()
        for k, v in pairs( devices ) do
            local links = {}
            for c, d in pairs( v ) do
                table.insert( links, { title = d, link = '/devices?type=' .. c } )
            end
            servernav.submenus['Config'] = links
        end
        servernav.submenus['Type'] = {
            { title = 'Server', link = '/devices?type=server' },
            { title = 'Storage', link = '/devices?type=storage' }
        }

        table.insert( nav, servernav )
    end

    --ip blocks
    if user:checkPermission( 'ViewOwnIPBlock' ) then
        local ipblocknav = { title = 'IP Blocks', link = '/ipblocks', submenus = {} }

        local admin = {}
        if user:checkPermission( 'ViewAnyIPBlock' ) then table.insert( admin, { title = 'View All', link = '/ipblocks/all' } ) end
        if user:checkPermission( 'AddIPBlock' ) then table.insert( admin, { title = 'Add IP Block', link = '/ipblocks/add' } ) end
        if #admin > 0 then ipblocknav.submenus['Admin'] = admin end

        ipblocknav.submenus['Type'] = {
            { title = 'IPv4', link = '/ipblocks?type=ipv4' },
            { title = 'IPv6', link = '/ipblocks?type=ipv6' }
        }
        table.insert( nav, ipblocknav )
    end

    --groups
    if user:checkPermission( 'ViewOwnGroup' ) then
        local groupnav = { title = 'Groups', link = '/groups' }
        local admin = {}
        if user:checkPermission( 'ViewAnyGroup' ) then table.insert( admin, { title = 'View All', link = '/groups/all' } ) end
        if user:checkPermission( 'AddGroup' ) then table.insert( admin, { title = 'Add Group', link = '/groups/add' } ) end
        if #admin > 0 then groupnav.submenus = { ['Admin'] = admin } end
        table.insert( nav, groupnav )
    end

    --automation
    table.insert( nav, { title = 'Automation', link = '/automation' } )

    return nav
end


--load a server type => deals with inheriting commands from parent services
function network:getDeviceConfig( type )
    --since we start with our service and work 'up' to the 'base' we must check each time before adding a command so as to not overwrite the lower config
    local config = require( oxy.config.root .. 'modules/network/devices/' .. type )
    config.tabs, config.commands, config.js = config.tabs or {}, config.commands or {}, config.js or {}

    --setup new object
    config.__index = config
    local object = {}
    setmetatable( object, config )

    --sort out tabs
    local tabs = {}
    for k, v in pairs( config.tabs ) do
        if v.order then
            tabs[v.order] = v
        else
            table.insert( tabs, v )
        end
    end
    object.tabs = tabs

    --parent?
    if config.parent then
        local parent = self:getDeviceConfig( config.parent )
        --dont overwrite commands
        if parent.commands then
            for k, v in pairs( parent.commands ) do
                if not object.commands[k] then
                    object.commands[k] = v
                end
            end
        end
        --add js
        if parent.js then
            for k, v in pairs( parent.js ) do
                table.insert( object.js, v )
            end
        end
        --add tabs
        if parent.tabs then
            for k, v in pairs( parent.tabs ) do
                local order = v.order or #object.tabs + 1
                table.insert( object.tabs, order, v )
            end
        end
    end
    return object
end


--convert configured service list into parent-aware table
function network:getDeviceList()
    local out = {}

    --loop servers
    for k, v in pairs( self.config.devices ) do
        --group MUST be defined on visible server types
        if not out[v.group] then out[v.group] = {} end
        out[v.group][k] = v.name
    end

    return out
end


return network