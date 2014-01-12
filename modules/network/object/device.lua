-- File: object/device.lua
-- Desc: device object definition

-- Locals
local database, user, network, node, template, request, header, session, utils, json = luawa.database, luawa.user, oxy.network, oxy.network.node, oxy.template, luawa.request, luawa.header, luawa.session, luawa.utils, require( 'cjson.safe' )

-- Device object
local device = {}

-- Prepare function
function device:prepare()
    --get the device config
    self.configuration = network:getDeviceConfig( self.config )
end

-- When getting device (ie GET /device/id)
function device:prepareView()
    --add any js
    if self.configuration.js and request.get.type == 'device' then
        local js = {}
        for k, v in pairs( self.configuration.js ) do
            js[k] = 'network/js/' .. v
        end
        template:add( 'module_js', js )
    end

    --live stat request to autonode
    self.stat_request_key, self.stat_request_err = self:stat()
end

-- When getting edit page of device (ie GET /device/id/edit)
function device:prepareEdit()
    --get owned device groups
    local groups, err = network.group:getOwned()
    template:set( 'groups', groups or {} )
end

-- When getting console page of device (ie GET /device/id/console) - popup page
function device:prepareConsole()
    --console request to node
    local key, err = self:command( 'console' )
    if err then self.console_request_error = err else self.console_request_key = key end
end




-- Stats request function
-- does no permission checking
function device:stat()
    return node:stat( self.id )
end

-- Command functon
-- in: command name, arguments
function device:command( command, args )
	args = args or {}

	--get our commands list, check command
	if not self.configuration.commands[command] then
		return false, 'Invalid command'
	end
    local command = self.configuration.commands[command]

	--check we can do this command to this object
	if not network.device:permission( self.id, command.permission ) then
		return false, 'No permission'
	end

    --host, port & user
    local host, port, user = self.host, self.ssh_port, self.ssh_user
    --missing details?
    if not host or not port or not user then
        return false, 'Invalid SSH details'
    end

    --commands a function?
    if type( command.actions ) == 'function' then
        local actions, err = command.actions( args )
        if err then return false, err end
        command.actions = actions
    end

    --build request
    local request = {
        host = host,
        port = port,
        user = user,
        commands = command.actions
    }

	--make the request
	local status, err = node:request( request )
	if not status then
		return false, 'Could not connect to Node SSH-proxy'
	end
	return status
end




-- Allowed post functions (command => permission)
device.posts = { runCommand = 'view', ssh = 'edit', edit = 'edit', delete = 'delete' }

-- POST to request a command - API mode only (does own permission checks)
function device:runCommand( request )
    if not request.get._api then return template:error( 'API only' ) end

    --token validated by core module, add token here for api even if error
    template:set( 'token', session:getToken(), true )

    --no if suspended
    if self.status == 'Suspended' then return template:set( 'error', 'Device currently suspended', true ) end

    if not request.post.command then
        return template:set( 'error', 'Invalid command', true )
    end

    local key, err = self:command( request.post.command, request.post )
    if not key then
        template:set( 'error', err, true )
    else
        template:set( 'request_key', key, true )
    end
end

-- POST to edit - non API
function device:edit( request )
    if not utils.tableKeys( request.post, { 'name', 'host', 'status', 'type', 'config', 'group', 'stat_frequency' }) then
        return template:error( 'Please complete all fields' )
    end

    --make group number for immediate page load
    request.post.group = tonumber( request.post.group ) or 0
    --check we can use this group
    if request.post.group ~= 0 and not network.group:permission( request.post.group, 'edit' ) then
        return template:error( 'You do not have permission to add the device to that group' )
    end

    --set data
    local update, err = self:_edit({
        name = request.post.name,
        status = request.post.status,
        type = request.post.type,
        config = request.post.config,
        device_group_id = request.post.group,
        host = request.post.host,
        stat_frequency = request.post.stat_frequency
    })

    if not update then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', err )
    else
        return header:redirect( '/device/' .. self.id .. '/edit', 'success', 'Device updated' )
    end
end

-- POST to delete
function device:delete( request )
    local delete, err = self:_delete()

    if not delete then
        return header:redirect( '/device/' .. self.id, 'error', err )
    else
        return header:redirect( '/network/devices', 'success', 'Device deleted' )
    end
end

-- POST to edit ssh details
function device:ssh( request )
    if not utils.tableKeys( request.post, { 'port', 'user', 'password' }) then
        return template:error( 'Please complete all fields' )
    end

    --get actions for config
    local actions, err = self.configuration.commands.add.actions( request.post )
    if not actions then return template:error( err ) end

    --build request
    local req = {
        host = self.host,
        port = request.post.port,
        user = request.post.user,
        commands = actions
    }

    request.post.password = request.post.password:len() > 0 and request.post.password or false

    --make request
    local key, err = node:request( req, request.post.password )
    if not key then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', err )
    end

    --capture request
    local status, err = node:capture( key )
    if not status then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', err )
    end

    local data = json.decode( status[#status] )
    if not data or not data.event then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', 'Node misconfig, please check status' )
    end
    --make sure we completed the request
    if data.event ~= 'request_end' or data.data ~= 'COMPLETE' then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', luawa.utils.tableString( data.data ) )
    end

    --set data
    local update, err = self:_edit({
        ssh_port = request.post.port,
        ssh_user = request.post.user
    })

    if not update then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', err )
    else
        return header:redirect( '/device/' .. self.id .. '/edit', 'success', 'Device SSH details updated' )
    end
end


return device