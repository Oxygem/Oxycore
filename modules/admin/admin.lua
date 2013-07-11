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
    local admin, isadmin = {}, false
    local users = { title = 'Users', link = '/users', admin = true, submenus = {} }
    table.insert( admin, { title = 'Permissions', link = '/users/permissions' } )
    table.insert( admin, { title = 'Groups', link = '/users/add' } )
    table.insert( admin, { title = 'Add User', link = '/users/add' } )
    table.insert( users.submenus, admin )
    table.insert( nav, users )

    return nav
end

return admin