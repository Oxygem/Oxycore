local user = luawa.user

local admin = {
	user = oxy.object:new( 'user' )
}

--[[
    generate subnav (cached in session)
]]
function admin:subnav()
    local nav = {}

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
    table.insert( nav, settings )

    --users
    if user:checkPermission( 'ViewUser' ) then
        local users = { title = 'Users', link = '/users', admin = true, submenus = {} }
        if user:checkPermission( 'AddUser' ) then users.submenus = { { { title = 'Add User', link = '/users/add' } } } end
        table.insert( nav, users )
    end

    --groups
    if user:checkPermission( 'ViewUserGroup' ) then
        local groups = { title = 'Groups', link = '/groups', admin = true }
        if user:checkPermission( 'AddUserGroup' ) then groups.submenus = { { { title = 'Add Group', link = '/groups/add' } } } end
        table.insert( nav, groups )
    end

    --permissions
    if user:checkPermission( 'ViewPermission' ) then
        local permissions = { title = 'Permissions', link = '/permissions', admin = true }
        table.insert( nav, permissions )
    end

    return nav
end

return admin