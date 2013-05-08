--[[
    file: <service module>/service.lua
    desc: core service module file
]]

--get oxy & co
local oxy, user = oxy, luawa.user

--define the service module
local service = {
    --setup each object class
    service = oxy.object:new( 'service' ),
    ipblock = oxy.object:new( 'ipblock' ),
    group = oxy.object:new( 'group' ),

    --ssh connecting
    ssh = require( oxy.config.root .. 'modules/service/ssh' )
}

--[[
    home dashboard display
]]
function service:dashboard()
    return {'data', test = 'he'}
end

--[[
    generate subnav (cached in session)
]]
function service:subnav()
    local nav = {}

    --services
    local admin, isadmin = {}, false
    local services = { title = 'Services', link = '/services', submenus = {} }
    if user:cookiePermission( 'ViewAnyService' ) then isadmin = true
        table.insert( admin, { title = 'View All Services', link = '/services/all' } )
    end
    if user:cookiePermission( 'AddService' ) then isadmin = true
        table.insert( admin, { title = 'Add Service', link = '/services/add' } )
    end
    if isadmin then services.submenus['Admin'] = admin end
    services.submenus['Type'] = {}
    for k, v in pairs( self.config.services ) do
        if not v.hidden then
            local name = v.names or v.name
            table.insert( services.submenus['Type'], { title = name, link = '/services?type=' .. k } )
        end
    end
    services.submenus['Status'] = {}
    table.insert( services.submenus['Status'], { title = 'Active', link = '/services?status=active' } )
    table.insert( services.submenus['Status'], { title = 'Suspended', link = '/services?status=suspended' } )
    table.insert( services.submenus['Status'], { title = 'Cancelled', link = '/services?status=cancelled' } )
    table.insert( nav, services )

    --ipblocks
    admin, isadmin = {}, false
    local ipblocks = { title = 'IP Blocks', link = '/ipblocks', submenus = {} }
    if user:cookiePermission( 'ViewAnyIpblock' ) then isadmin = true
        table.insert( admin, { title = 'View All IP Blocks', link = '/ipblocks/all' } )
    end
    if user:cookiePermission( 'AddIpblock' ) then isadmin = true
        table.insert( admin, { title = 'Add IP Block', link = '/ipblocks/add' } )
    end
    if isadmin then ipblocks.submenus['Admin'] = admin end
    ipblocks.submenus['Type'] = {}
    table.insert( ipblocks.submenus['Type'], { title = 'IPv4', link = '/ipblocks?type=ipv4' } )
    table.insert( ipblocks.submenus['Type'], { title = 'IPv6', link = '/ipblocks?type=ipv6' } )
    table.insert( nav, ipblocks )

    --groups
    admin, isadmin = {}, false
    local groups = { title = 'Groups', link = '/groups' }
    if user:cookiePermission( 'ViewAnyGroup' ) then isadmin = true
        table.insert( admin, { title = 'View All Groups', link = '/groups/all' } )
    end
    if user:cookiePermission( 'AddGroup' ) then isadmin = true
        table.insert( admin, { title = 'Add Group', link = '/groups/add' } )
    end
    if isadmin then groups.submenus = {} groups.submenus['Admin'] = admin end
    table.insert( nav, groups )

    --automation
    table.insert( nav, { title = 'Automation', link = '/automation' } )

    return nav
end


--[[
    load a service type => deals with inheriting commands from parent services
]]
function service:getServiceConfig( type )
    --since we start with our service and work 'up' to the 'base' we must check each time before adding a command so as to not overwrite the lower config
    local object = require( oxy.config.root .. 'modules/service/services/' .. type )
    object.commands, object.js, object.tabs = object.commands or {}, object.js or {}, object.tabs or {}

    --sort out tabs
    local newtabs = {}
    for k, v in pairs( object.tabs ) do
        local order = v.order or k
        newtabs[order] = v
    end
    object.tabs = newtabs

    --parent?
    if object.parent then
        local parent = self:getServiceConfig( object.parent )
        --dont overwrite commands
        if parent.commands then
            for k, v in pairs( parent.commands ) do
                if not object.commands[k] then
                    object.commands[k] = v
                end
            end
        end
        --add filter if not got one
        if not object.filter and parent.filter then
            object.filter = parent.filter
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



return service