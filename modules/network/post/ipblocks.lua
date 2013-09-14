local request, template, database, network, ssh, user, header = luawa.request, oxy.template, luawa.database, oxy.network, oxy.network.ssh, luawa.user, luawa.header
local json = require( 'cjson.safe' )

if request.get.action == 'add' then
    --permission
    if not user:checkPermission( 'AddIPBlock' ) then
        return template:error( 'You do not have permission to add devices' )
    end

    --details
    if not request.post.name or not request.post.type or not request.post.prefix or not request.post.mask then
        return template:error( 'Please fill out all fields' )
    end

    --check the ip is valid (doesn't confirm the ip/mask == exact/broadcast)
    local info, err = network[request.post.type].blockInfo( network[request.post.type], request.post.prefix .. '/' .. request.post.mask )
    if err then
        return header:redirect( '/network/ipblocks/add', 'error', err )
    end

    --add to database
    local result, err = database:insert( 'network_ipblock',
        { 'user_id', 'name', 'type', 'subnet' },
        { { user:getData().id, request.post.name, request.post.type, request.post.prefix .. '/' .. request.post.mask } }
    )
    if not result or not result.insert_id then
        template:error( err )
    end
    
    --redirect to new block
    header:redirect( '/ipblock/' .. result.insert_id .. '/edit', 'success', 'IP Block added, assign to devices and groups below' )
end