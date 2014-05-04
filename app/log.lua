-- Oxypanel Core
-- File: app/log.lua
-- Desc: logging of all actions for Oxypanel

local os = os
local database, user, request = luawa.database, luawa.user, luawa.request

local function log()
    -- require both id & type for object
    local id, type = 0, ''
    if request.get.type and request.get.id then
        id = request.get.id
        type = request.get.type
    end

    -- insert the log
    local status, err = database:insert('log',
        { 'time', 'object_type', 'object_id', 'user_id', 'action', 'module', 'module_request', 'request' },
        {{
            os.time(),
            type,
            id,
            user:checkLogin() and user:getData().id or 0,
            request.get.action or 'view',
            request.get.module or '',
            request.get.module_request or '',
            request.get.request
        }},
        { delayed = true }
   )
end

return log