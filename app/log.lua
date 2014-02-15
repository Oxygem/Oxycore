-- Oxypanel
-- File: app/log.lua
-- Desc: logging of all actions for Oxypanel

local os = os
local database, user = luawa.database, luawa.user

local function log()
    local request = luawa.request

    local status, err = database:insert( 'log',
        { 'time', 'object_type', 'object_id', 'user_id', 'action', 'module', 'module_request', 'request' },
        {{
            os.time(),
            request.get.type or '',
            request.get.id or 0,
            user:checkLogin() and user:getData().id or 0,
            request.get.action or 'view',
            request.get.module or '',
            request.get.module_request or '',
            request.func
        }},
        { delayed = true }
    )
end

return log