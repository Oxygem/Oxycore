--locals
local database, user, network, ssh, template, request, header, session, json = luawa.database, luawa.user, oxy.network, oxy.network.ssh, oxy.template, luawa.request, luawa.header, luawa.session, require( 'cjson.safe' )

--service object
local device = {}

--prepare function
function device:prepare()
    --get the device config
    self.configuration = network:getDeviceConfig( self.config )
end

--when getting device (ie GET /device/id)
function device:prepareView()
    --get device IP's
    local service_ips = database:select(
        'network_ipblock_ip', '`address`',
        { device_id = self.id }
    )
    self.ips = service_ips or {}

    --add any js
    if self.configuration.js and request.get.type == 'device' then
        local js = {}
        for k, v in pairs( self.configuration.js ) do
            js[k] = 'network/js/' .. v
        end
        template:add( 'module_js', js )
    end

    --status request to node
    local key, err = self:command( 'status' )
    if err then self.status_request_error = err else self.status_request_key = key end
end

--when getting edit page of device (ie GET /device/id/edit)
function device:prepareEdit()
    --get owned device groups
    local groups, err = network.group:getOwned()
    template:set( 'groups', groups or {} )
end

--when getting console page of device (ie GET /device/id/console) - popup page
function device:prepareConsole()
    --console request to node
    local key, err = self:command( 'console' )
    if err then self.console_request_error = err else self.console_request_key = key end
end




--command functon
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
	local status, err = ssh:request( request )
	if not status then
		return false, err
	end
	return status
end




--allowed post functions (command => permission)
device.posts = { runCommand = 'view', edit = 'edit', ssh = 'edit', snmp = 'edit' }

--POST to request a command - API mode only
function device:runCommand()
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

--POST to edit - non API
function device:edit()
    if not request.post.name or not request.post.host or not request.post.status or not request.post.type or not request.post.config or not request.post.group then
        return template:error( 'Please complete all fields' )
    end

    --make group number for immediate page load
    request.post.group = tonumber( request.post.group ) or 0
    --check we can use this group
    if request.post.group ~= 0 and not network.group:permission( request.post.group, 'edit' ) then
        return template:error( 'You do not have permission to add the device to that group' )
    end

    --set
    self.name = request.post.name
    self.status = request.post.status
    self.type = request.post.type
    self.config = request.post.config
    self.device_group_id = request.post.group
    self.host = request.post.host

    --update service
    local update, err = database:update(
        'network_device',
        {
            name = request.post.name,
            status = request.post.status,
            type = request.post.type,
            config = request.post.config,
            device_group_id = request.post.group,
            host = request.post.host
        }, { id = self.id }
    )
    if not update then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', err )
    else
        return header:redirect( '/device/' .. self.id .. '/edit', 'success', 'Device updated' )
    end
end

--POST to edit ssh details
function device:ssh()
    if not request.post.port or not request.post.user or not request.post.password or request.post.password:len() == 0 then
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

    --make request
    local key, err = ssh:request( req, request.post.password )
    if not key then
        return header:redirect( '/device/' .. self.id .. '/edit', 'error', err )
    end

    --capture request
    local status, err = ssh:capture( key )
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

    return header:redirect( '/device/' .. self.id .. '/edit', 'success', 'Device SSH details updated' )
end

--POST to edit snmp details
function device:snmp()
end

return device