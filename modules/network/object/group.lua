--locals
local database = luawa.database

--object definition
local group = {}

--GET group/id
function group:prepareView()
    --load our devices
    local devices = database:select(
        'network_device', 'id, name, status, type, config',
        { device_group_id = self.id }
    )
    self.devices = devices or {}
end

return group