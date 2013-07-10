--locals
local database, user, network, ssh, template, request, header = luawa.database, luawa.user, oxy.network, oxy.network.ssh, oxy.template, luawa.request, luawa.header

--service object
local device = {}

--prepare function
function device:prepare()
    --get the device config
    self.config = network:getDeviceConfig( self.config )
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
    if self.config.js and request.get.type == 'device' then
        for k, v in pairs( self.config.js ) do
            self.config.js[k] = 'network/js/' .. v
        end
        template:add( 'module_js', self.config.js )
    end

    --status request to node
    local key, err = self:command( 'status' )
    if err then self.status_request_error = err else self.status_request_key = key end
end

--when getting edit page of device (ie GET /device/id/edit)
function prepareEdit()
    --get device groups <= owned?
end




--command functon
function device:command( command, args )
	args = args or {}

	--get our commands list, check command
	if not self.config.commands[command] then
		return false, 'Invalid command'
	end
    local command = self.config.commands[command]

    --function type?
    if type( command.ssh ) == 'function' then
        local status, err = command.ssh( args )
        if not status then
            return false, err
        end
        command.ssh = status
    end

	--check we can do this command to this object
	if not network.device:permission( self.id, command.permission ) then
		return false, 'No permission'
	end

    --host, port & user
    local host, port, user = self.ssh_host, self.ssh_port, self.ssh_user
    --missing details?
    if not host or not port or not user then
        return false, 'Invalid SSH details'
    end

    --commands a function?
    if type( command.actions ) == 'function' then
        local actions, err = command.actions( self )
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




--allowed post functions
device.posts = { runCommand = true, edit = true }

--POST to request a command
function device:runCommand()
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

--POST to edit (just name!)
function device:edit()
    if not request.post.name then
        return template:set( 'error', 'Please enter a name', true )
    end

    --set
    self.name = request.post.name

    --update service
    local update, err = database:update(
        'network_device',
        { name = request.post.name },
        { id = self.id }
    )
    if not update then
        template:set( 'error', err, true )
    else
        template:set( 'success', 'Device updated', true )
    end

    --just load this will load GET page
    luawa:processFile( 'app/get/object' )
end


return device