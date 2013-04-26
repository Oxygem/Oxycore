--[[
    file: app/template.lua
    desc: Oxypanel template class (deals w/ module templates)
        inherits from luawa.template
]]

--our template class
local template = {}
--set our template to inherit luawa.template's methods
luawa.template.__index = luawa.template
setmetatable( template, luawa.template )

function template:load( template )
    local dir = 'app/templates/' .. oxy.config.oxyngx.template .. '/' .. template

    return luawa.template:load( dir )
end

--loading module templates
function template:loadModule( module, template )
    local dir = 'modules/' .. module .. '/templates/' .. oxy.config.oxyngx.template .. '/' .. template

    return luawa.template:load( dir )
end

return template