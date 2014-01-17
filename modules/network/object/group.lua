-- File: object/group.lua
-- Desc: device group object definition

--locals
local database, request, header = luawa.database, luawa.request, luawa.header

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


--posts
group.posts = { edit = 'edit', delete = 'delete', removeDevice = 'edit' }

-- POST to edit
function group:edit( request )
	if not request.post.name then
		return template:error( 'Please complete all fields' )
	end

	--update db
	local update, err = self:_edit({
        name = request.post.name
    })

	if not update then
        return header:redirect( '/group/' .. self.id .. '/edit', 'error', err )
    else
        return header:redirect( '/group/' .. self.id .. '/edit', 'success', 'Group updated' )
    end
end

-- POST to delete
function group:delete( request )
    local delete, err = self:_delete()

    if not delete then
        return header:redirect( '/group/' .. self.id, 'error', err )
    else
        return header:redirect( '/network/groups', 'success', 'Group deleted' )
    end
end

-- POST to remove device
function group:removeDevice( request )
    if not request.post.device_id then
        return template:error( 'Invalid device id' )
    end

    --remove device from group (IF in it!)
    local delete, err = database:update(
        'network_device',
        { device_group_id = 0 },
        { id = request.post.device_id, device_group_id = self.id }
    )

    if not delete then
        return header:redirect( '/group/' .. self.id, 'error', err )
    else
        return header:redirect( '/group/' .. self.id, 'success', 'Device removed' )
    end
end

return group