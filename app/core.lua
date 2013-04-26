--[[
    file: app/core.lua
    desc: Oxypanel core
]]


--localize lua
local require = require

--oxypanel core
local oxy = {
    config = {}
}

--set config & setup
function oxy:setConfig( config )
    self.config = config
    --get & set object
    self.object = require( self.config.root .. 'app/object' )
    --get & set template
    self.template = require( self.config.root .. 'app/template' )
    --get & set email
    self.email = require( self.config.root .. 'app/email' )
end

--load module
function oxy:loadModule( module )
    --module folder exists?
    if not self.config.modules[module] then return false end

    --need to load it?
    if not self[module] then
        self[module] = require( self.config.root .. 'modules/' .. module .. '/' .. module )
        self[module].config = self.config[module]
    end

    --return the module
    return self[module]
end


return oxy