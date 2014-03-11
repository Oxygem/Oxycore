-- Oxypanel Core/Admin
-- File: get/logs.lua
-- Desc: browse logs

local database, user = luawa.database, luawa.user
local template = oxy.template

--login & permission check
if not user:checkPermission( 'ViewLog' ) then
    return template:error( 'You do not have permission to do that' )
end

local logs, err = database:select(
    'log LEFT JOIN user ON log.user_id = user.id',
    { 'log.*', 'user.name AS username' },
    false,
    { limit = 500, order = 'time DESC' }
)
if not logs then
    return template:error( err )
end

template:set( 'logs', logs )
template:wrap( 'admin', 'logs' )