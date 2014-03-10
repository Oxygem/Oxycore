-- Oxypanel Core
-- File: app/core.lua
-- Desc: Oxypanel core

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
    self.object = require( 'app/object' )
    --get & set template
    self.template = require( 'app/template' )
    --get & set email
    self.email = require( 'app/email' )
    --get brand
    self.brand = require( 'app/brand' )
    --users
    self.users = require( 'app/users' )
    --log
    self.log = require( 'app/log' )
end

--load module
function oxy:loadModule( module )
    --module folder exists?
    if not self.config[module] then return false end

    --need to load it?
    if not self[module] then
        self[module] = require( 'modules/' .. module .. '/' .. module )
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