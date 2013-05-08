--[[
    file: service/services/dedicated/config.lua
    desc: file does nothing, everything inherits from generic linux (but need to be called 'dedicated', vm's use this as a base too!)
]]
local config = {
    parent = 'base',
	name = 'Dedicated/Single',
    names = 'Dedicated/Single'
}

return config