--[[
    modules/admin/config.lua
]]

local config = {
    --nice name
    name = 'Admin',
    objects = {
    },
    --requests to capture
    requests = {
        get = {
            default = { file = 'get/dashboard' },
            users = { file = 'get/users' }
        },
        post = {}
    }
}

return config