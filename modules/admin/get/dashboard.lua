--[[
    file: <service module>/get/dashboard
    desc: admin dashboard
]]

local template = oxy.template

template:load( 'core/header' )
template:loadModule( 'admin', 'dashboard' )
template:load( 'core/footer' )