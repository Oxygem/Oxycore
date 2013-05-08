--locals
local database = luawa.database

--object definition
local group = {}

--GET group/id
function group:get()
    --load our services
    local services = database:select(
        'service_service', 'id, name, status, type',
        { service_group_id = self.id }
    )
    self.services = services or {}
end

return group