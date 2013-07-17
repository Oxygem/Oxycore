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

function template:setup()
    if luawa.request.get._api then
        luawa.template.api = true
    end
end

function template:load( template, inline )
    local dir = 'app/templates/' .. oxy.config.oxyngx.template .. '/' .. template

    return luawa.template:load( dir, inline )
end

--loading module templates
function template:loadModule( module, template, inline )
    local dir = 'modules/' .. module .. '/templates/' .. oxy.config.oxyngx.template .. '/' .. template

    return luawa.template:load( dir, inline )
end

--wrap template w/ header+footer
function template:wrap( template, inline )
    self:load( 'core/header' )
    self:put( template )
    self:load( 'core/footer' )
end

--error only w/ api
function template:error( message )
    self:set( 'error', message, true )
    self:load( 'core/header' )
    self:load( 'core/footer' )
end

return template