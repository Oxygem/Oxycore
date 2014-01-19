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

--wrap template w/ header+footer (template inline)
--don't use template as name because can either be loadModule or load
function template:wrap( template )
    self:load( 'head' )
    self:load( 'header' )
    self:put( template )
    self:load( 'footer' )
end

--error only w/ api
function template:error( message )
    luawa.session:addMessage( 'error', message )
    self:load( 'header' )
    self:load( 'footer' )
end

return template