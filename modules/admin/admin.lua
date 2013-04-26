local user = luawa.user

local admin = {
	user = oxy.object:new( 'user' )
}

--[[
    generate subnav (cached in session)
]]
function admin:subnav()
    local nav = {}

    --users
    local admin, isadmin = {}, false
    local users = { title = 'Users', link = '/users', submenus = {} }
    if user:cookiePermission( 'ViewAnyUser' ) then isadmin = true
        table.insert( admin, { title = 'View All Users', link = '/users/all' } )
    end
    if user:cookiePermission( 'AddUser' ) then isadmin = true
        table.insert( admin, { title = 'Add User', link = '/users/add' } )
    end
    if isadmin then users.submenus['Admin'] = admin end
    table.insert( nav, users )

    --settings
    local admin, isadmin = {}, false
    local settings = { title = 'Settings', link = '/settings', submenus = {}, admin = true }
    if user:cookiePermission( 'ViewAnyUser' ) then isadmin = true
        table.insert( admin, { title = 'Basics', link = '/users/all' } )
    end
    if user:cookiePermission( 'AddUser' ) then isadmin = true
        table.insert( admin, { title = 'Modules', link = '/users/add' } )
    end
    table.insert( admin, { title = 'Brands', link = '' } )
    table.insert( admin, { title = 'Automation', link = '' } )
    if isadmin then settings.submenus['Core'] = admin end

    local modules = {}
    for k, module in pairs( oxy.config.modules ) do
        table.insert( modules, { title = oxy.config[module].name, link = '' } )
    end
    settings.submenus['Modules'] = modules

    table.insert( nav, settings )

    return nav
end

return admin