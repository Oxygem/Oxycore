--[[
    file: service/services/dedicated.lua
    desc: adds hardware info for dedicated Linux
]]
local config = {
    parent = 'linux',
	name = 'Dedicated',
    names = 'Dedicated',

    tabs = {
        { name = 'Hardware', js = 'hardware', permission = 'view', order = 7 }
	}
}

return config