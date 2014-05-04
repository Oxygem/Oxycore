-- Oxypanel Core / Admin
-- File: get/debug.lua
-- Desc: debug page for Oxypanel

local database, user = luawa.database, luawa.user
local template, config = oxy.template, oxy.config

--login & permission check
if not user:checkPermission('ViewDebug') then
    return template:error('You do not have permission to do that')
end

template:set('config', config)
template:wrap('admin', 'debug')