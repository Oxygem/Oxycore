--[[
    file: <service module>/get/dashboard
    desc: admin dashboard
]]

local template = oxy.template

template:wrap( template:loadModule( 'admin', 'dashboard', true ) )