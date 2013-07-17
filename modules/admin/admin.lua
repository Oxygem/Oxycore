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
    local users = { title = 'Users', link = '/users', admin = true, submenus = {} }
    table.insert( users.submenus, { { title = 'Add User', link = '/users/add' } } )
    table.insert( nav, users )

    --groups
    local groups = { title = 'Groups', link = '/groups', admin = true, submenus = {} }
    table.insert( groups.submenus, { { title = 'Add Group', link = '/groups/add' } } )
    table.insert( nav, groups )

    --permissions
    local permissions = { title = 'Permissions', link = '/permissions', admin = true }
    table.insert( nav, permissions )

    return nav
end

return admin