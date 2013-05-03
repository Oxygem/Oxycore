--locals
local database, user, oxyservice, ssh, template, request, header = luawa.database, luawa.user, oxy.service, oxy.service.ssh, oxy.template, luawa.request, luawa.header

--service object
local service = {
    posts = { command = true, setdata = true, edit = true }
}

--prepare function
function service:prepare()
    --get service_data
    local service_data = database:select(
        'service_service_data', '`key`, value',
        { service_id = self.id }
    )
    self.data = {}
    --add each key/value pair
    for k, v in pairs( service_data ) do
        self.data[v.key] = v.value
    end

    --get the service config
    self.config = oxyservice:getServiceConfig( self.type )
end

--when getting service (ie GET /service/id)
function service:get()
    --get service IP's
    local service_ips = database:select(
        'service_ipblock_ip', '`address`',
        { service_id = self.id }
    )
    self.ips = service_ips or {}

    --get service_software
    local service_software = database:select(
        'service_service_software', 'software, directory',
        { service_id = self.id }
    )
    self.software = service_software

    --add any js
    if self.config.js and request.get.type == 'service' then
        template:add( 'module_js', self.config.js )
    end

    --status request to node
    local key, err = self:commandRequest( 'status' )
    if err then self.status_request_error = err else self.status_request_key = key end
end

--when getting edit page of service
function getEdit()
    --get service groups <= owned?
end


--command functon
function service:commandRequest( command, args )
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
	if not oxyservice.service:permission( self.id, command.permission ) then
		return false, 'No permission'
	end

    --host, port & user
    local host, port, user = self.data.ssh_host, self.data.ssh_port, self.data.ssh_user

    --command acting on parent?
    if command.parent then
        local parent_data = {}
        local data = database:select(
            'service_service_data', '`key`, value',
            { service_id = self.service_parent_id }
        )
        for k, v in pairs( data ) do
            parent_data[v.key] = v.value
        end
        host, port, user = parent_data.ssh_host, parent_data.ssh_port, parent_data.ssh_user
    end

    --missing details?
    if not host or not port or not user then
        return false, 'Invalid SSH details'
    end

    --work out our ssh options
    local commands
    local os_type, os_version = self.data.os_type or 'none', self.data.os_version or 0
    --match os type and version?
    if command.ssh[os_type .. '_' .. os_version] then
        commands = command.ssh[os_type .. '_' .. os_version]
    --match os type?
    elseif command.ssh[os_type] then
        commands = command.ssh[os_type]
    elseif command.ssh.all then
        commands = command.ssh.all
    end

    --no commands?
    if not commands then
        return false, 'No compatible SSH commands found for this OS'
    end

    --build request
    local request = {
        host = host,
        port = port,
        user = user,
        commands = commands
    }

	--make the request
	local status, err = ssh:request( request )
	if not status then
		return false, err
	end
	return status
end

--POST to request a command
function service:command()
    if not request.post.command then
        return template:set( 'error', 'Invalid command', true )
    end

    local key, err = self:commandRequest( request.post.command, request.post )
    if not key then
        template:set( 'error', err, true )
    else
        template:set( 'request_key', key, true )
    end
end

--POST to edit date
function service:setdata()
    if not request.post.key or not request.post.value then
        return template:set( 'error', 'Invalid details', true )
    end

    local update, err = database:update(
        'service_service_data',
        { value = request.post.value },
        { service_id = self.id, key = request.post.key }
    )
    if not update then
        template:set( 'error', err, true )
    else
        template:set( 'data_set', 'true', true )
    end
end

--POST to edit (just name!)
function service:edit()
    template:set( 'success', 'Service updated' )

    --just load this will load GET page
    luawa:processFile( 'app/get/object' )
end


return service