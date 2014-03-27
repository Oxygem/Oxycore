--[[
    modules/admin/config.lua
]]

local config = {
    --nice name
    name = 'Admin',
    order = 7,
    objects = {
    },
    --requests to capture
    requests = {
        get = {
            default = { file = 'get/dashboard' },
            users = { file = 'get/users' },
            permissions = { file = 'get/permissions' },
            groups = { file = 'get/groups' },
            logs = { file = 'get/logs' },
            debug = { file = 'get/debug' }
        },
        post = {
            users = { file = 'post/users' },
            permissions = { file = 'post/permissions' },
            groups = { file = 'post/groups' }
        }
    },
    --additional permissions
    permissions = {
        'ViewStatus',

        'AddUser',
        'ViewUser',
        'EditUser',
        'DeleteUser',

        'ViewPermission',
        'EditPermission',

        'AddUserGroup',
        'ViewUserGroup',
        'EditUserGroup',
        'DeleteUserGroup',

        'ViewLog',
        'ViewDebug'
    }
}

return config