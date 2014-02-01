-- File: app/log.lua
-- Desc: logging of all actions for Oxypanel

local os = os
local database, user = luawa.database, luawa.user

local function log()
    local request = luawa.request

    database:delayed( 'log',
        { 'time', 'object_type', 'object_id', 'user_id', 'action', 'module', 'request' },
        {
            { os.time(), request.get.type or '', request.get.id or 0, user:getData().id, request.get.action or 'view', request.get.module or '', request.get.module_request or '' }
        },
        false, true
    )
end

return log