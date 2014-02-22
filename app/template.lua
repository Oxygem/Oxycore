-- Oxypanel Core
-- File: app/template.lua
-- Desc: extends luawa.template to extend functionality

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

function template:load( template )
    local dir = 'app/templates/' .. oxy.config.template .. '/' .. template

    return luawa.template:load( dir )
end

--loading module templates
function template:loadModule( module, template )
    local dir = 'modules/' .. module .. '/templates/' .. oxy.config.template .. '/' .. template

    return luawa.template:load( dir )
end

--wrap template w/ header+footer
function template:wrap( module, template )
    self:load( 'head' )
    self:load( 'header' )
    if module then
        self:loadModule( module, template )
    else
        self:load( template )
    end
    self:load( 'footer' )
    self:load( 'foot' )
end

--error only w/ api
function template:error( message )
    luawa.session:addMessage( 'error', message )
    self:load( 'head' )
    self:load( 'header' )
    self:load( 'footer' )
    self:load( 'foot' )
end

return template