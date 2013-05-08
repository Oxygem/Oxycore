--[[
    modules/admin/config.lua
]]

local config = {
    --nice name
    name = 'Admin',
    objects = {
        user = {
            name = 'User',
            names = 'Users',
            search_fields = { 'name', 'email' },
            filters = { 'group' },
            fields = 'id, email, `group`, name, user_id, group_id, real_name'
        }
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