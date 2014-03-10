-- Oxypanel Core
-- File: app/template.lua
-- Desc: extends luawa.template to extend functionality

--our template class
local template = {}

function template:setup()
    if luawa.request.get._api then
        luawa.template:setApi( true )
    end
end

function template:load( template, inline )
    local dir = 'app/templates/' .. template
    return getmetatable( self ).__index.load( self, dir, inline )
end

--loading module templates
function template:loadModule( module, template, inline )
    local dir = 'modules/' .. module .. '/templates/' .. template
    return getmetatable( self ).__index.load( self, dir, inline )
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

--set our template to inherit luawa.template's methods
setmetatable( template, { __index = luawa.template })
--allow access to this from template files
luawa.template.parent = template
return template