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
group.posts = { edit = 'edit' }

function group:edit( request )
	if not request.post.name then
		return template:error( 'Please complete all fields' )
	end

	--update group
	self.name = request.post.name

	--update db
	local update, err = database:update(
		'network_group',
		{ name = request.post.name },
		{ id = self.id }
	)

	if not update then
        return header:redirect( '/group/' .. self.id .. '/edit', 'error', err )
    else
        return header:redirect( '/group/' .. self.id .. '/edit', 'success', 'Group updated' )
    end
end

return group