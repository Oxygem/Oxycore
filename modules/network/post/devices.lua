local request, template, database, network, node, user, header, json = luawa.request, oxy.template, luawa.database, oxy.network, oxy.network.node, luawa.user, luawa.header, require( 'cjson.safe' )

if request.get.action == 'add' then
    --permission
    if not user:checkPermission( 'AddDevice' ) then
        return template:error( 'You do not have permission to add devices' )
    end

    --details
    if not request.post.name or not request.post.config or not network.config.devices[request.post.config] or not request.post.hostname or not request.post.port or not request.post.user or not request.post.password then
        return template:error( 'Please fill out all fields' )
    end

    --get config
    local config = network:getDeviceConfig( request.post.config )

    --get actions for config
    local actions, err = config.commands.add.actions( request.post )
    if not actions then return template:error( err ) end

    --build request
    local req = {
        host = request.post.hostname,
        port = request.post.port,
        user = request.post.user,
        commands = actions
    }

    request.post.password = request.post.password:len() > 0 and request.post.password or false

    --make request
    local key, err = node:request( req, request.post.password )
    if not key then
        return header:redirect( '/network/devices/add', 'error', err )
    end

    --capture request
    local status, err = node:capture( key )
    if not status then
        return header:redirect( '/network/devices/add', 'error', err )
    end

    local data = json.decode( status[#status] )
    if not data.event then
        return header:redirect( '/network/devices/add', 'error', 'Node misconfig, please check status' )
    end
    --make sure we completed the request
    if data.event ~= 'request_end' or data.data ~= 'COMPLETE' then
        return header:redirect( '/network/devices/add', 'error', luawa.utils.tableString( data.data ) )
    end

    --continue adding...
    local result, err = database:insert( 'network_device',
        { 'user_id', 'name', 'config', 'host', 'ssh_port', 'ssh_user' },
        { { user:getData().id, request.post.name, request.post.config, request.post.hostname, request.post.port, request.post.user } }
    )
    if not result or not result.insert_id then
        template:error( err )
    end

    --redirect to new device
    header:redirect( '/device/' .. result.insert_id .. '/edit', 'success', 'Device added, assign it to a group &amp; more below' )
end