--[[
    file: app/get/dashboard.lua
    desc: Display the main dashboard
]]

--get template
local template, header, user = oxy.template, luawa.header, luawa.user

--dashboard is not public
if not user:checkLogin() then
    return header:redirect( '/login' )
end

--build dashboard objects from each module
local dashboard = {}
for k, module in pairs( oxy.config.modules ) do
    local m = oxy:loadModule( module )
    if m.dashboard then
        dashboard[module] = m:dashboard()
    end
end
template:set( 'dashboard', dashboard )

--page title
template:set( 'page_title', 'Dashboard' )

--load header
template:load( 'header' )
template:load( 'dashboard' )
template:load( 'footer' )