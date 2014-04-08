-- Oxypanel Core
-- File: app/core.lua
-- Desc: Oxypanel core

--localize lua
local require = require

--oxypanel core
local oxy = {
    config = {},
    modules = {
        'object',
        'template',
        'email',
        'brand',
        'users',
        'log'
    }
}

--set config & setup
function oxy:setConfig( config )
    if self.init then return end

    self.config = config

    for k, v in pairs( self.modules ) do
        self[v] = require( config.root .. 'app/' .. v )
    end

    self.init = true
end

--load module
function oxy:loadModule( module )
    --module folder exists?
    if not self.config[module] then return false end

    --need to load it?
    if not self[module] then
        self[module] = require( self.config.root .. 'modules/' .. module .. '/' .. module )
        self[module].config = self.config[module]
    end

    --return the module
    return self[module]
end

--setup (post luawa setup)
function oxy:setup()
    self.log()
    self.object:setup()
    self.brand:setup()
    self.template:setup()
end


return oxy