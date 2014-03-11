local user = luawa.user
local oxy = oxy

local admin = {
    user = oxy.object:new( 'user' )
}

-- Build subnav
function admin:subnav()
    local nav = {}

    --status
    if user:checkPermission( 'ViewStatus' ) then
        --table.insert( nav, { title = 'Status', link = '/status', admin = true })
    end

    --settings
    local settings = { title = 'Settings', link = '/settings', submenus = {}, admin = true }
    settings.submenus['Core'] = {
        { title = 'Basics', link = '' },
        { title = 'Modules', link = '' },
        { title = 'Brands', link = '' }
    }

    local modules = {}
    for k, module in pairs( oxy.config.modules ) do
        table.insert( modules, { title = oxy.config[module].name, link = '' } )
    end
    settings.submenus['Modules'] = modules
    --table.insert( nav, settings )

    --users
    if user:checkPermission( 'ViewUser' ) then
        local users = { title = 'Users', link = '/users', admin = true, submenus = {} }
        if user:checkPermission( 'AddUser' ) then users.submenus = {{{ title = 'Add User', link = '/users/add' }}} end
        table.insert( nav, users )
    end

    --groups
    if user:checkPermission( 'ViewUserGroup' ) then
        local groups = { title = 'Groups', link = '/groups', admin = true }
        if user:checkPermission( 'AddUserGroup' ) then groups.submenus = {{{ title = 'Add Group', link = '/groups/add' }}} end
        table.insert( nav, groups )
    end

    --permissions
    if user:checkPermission( 'ViewPermission' ) then
        local permissions = { title = 'Permissions', link = '/permissions', admin = true }
        table.insert( nav, permissions )
    end

    --objects
    local owner_objects = { title = 'Objects', link = '/objects', admin = true }
    local objects = {}
    for name, object in pairs( oxy.config.objects ) do
        if user:checkPermission( 'OwnerAny' .. object.permission ) then
            table.insert( objects, { title = object.name, link = '/objects/' .. name  })
        end
    end
    if #objects > 0 then
        owner_objects.submenus = { objects }
        --table.insert( nav, owner_objects )
    end

    --logging
    if user:checkPermission( 'ViewLog' ) then
        local logs = { title = 'Logs', link = '/logs', admin = true }
        table.insert( nav, logs )
    end

    return nav
end

return admin