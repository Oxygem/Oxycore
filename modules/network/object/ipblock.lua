--locals
local database, network, template, request, utils, header = luawa.database, oxy.network, oxy.template, luawa.request, luawa.utils, luawa.header

--service object
local ipblock = {}

--prepare
function ipblock:prepare()
	--for ipv6 get our mask, take from 128 and /4 to calculate max number of bits for auto-generate ips
	if self.type == 'IPv6' then
		local a, b, ip, mask = self.subnet:find( '([%w%:]+)/(%d+)$' )
		self.ip = ip
		self.mask = tonumber( mask )
	else
		local a, b, ip, mask = self.subnet:find( '([%d%.]+)/(%d+)$' )
		self.ip = ip
		self.mask = tonumber( mask )
	end
end

--get
function ipblock:prepareView()
	--get ip's
	local ips, err = database:select(
		'network_ipblock_ip', 'address, status',
		{ ipblock_id = self.id }
	)
	self.ips = ips or {}
end

--edit
function ipblock:prepareEdit()
    --get owned device groups
    local groups, err = network.group:getOwned()
    template:set( 'groups', groups or {} )

    --get owned devices
    local devices, err = network.device:getOwned()
    template:set( 'devices', devices or {} )
end




--posts
ipblock.posts = { edit = 'edit', addIP = 'edit', autoIP = 'edit', generateIP = 'edit' }

--edit ip block
function ipblock:edit()
	if not request.post.name or not request.post.device or not request.post.group or not request.post.prefix or not request.post.mask then
		return template:error( 'Please complete all fields' )
	end

	--fix numbers
	request.post.device = tonumber( request.post.device ) or 0
	request.post.group = tonumber( request.post.group ) or 0
	--check we can use this device
    if request.post.device ~= 0 and not network.device:permission( request.post.device, 'edit' ) then
        return template:error( 'You do not have permission to add the device to that device' )
    end
	--check we can use this group
    if request.post.group ~= 0 and not network.group:permission( request.post.group, 'edit' ) then
        return template:error( 'You do not have permission to add the device to that group' )
    end

    --validate the subnet
    local subnet = request.post.prefix .. '/' .. request.post.mask
	local status, err = network[self.type:lower()]:blockInfo( subnet )
	if not status then return header:redirect( '/ipblock/' .. self.id .. '/edit', 'error', err ) end

    --set
    self.name = request.post.name
    self.subnet = subnet
    self.device_id = request.post.device
    self.device_group_id = request.post.group

    --update service
    local update, err = database:update(
        'network_ipblock',
        {
            name = request.post.name,
            subnet = subnet,
            device_id = request.post.device,
            device_group_id = request.post.group
        }, { id = self.id }
    )
    if not update then
        return header:redirect( '/ipblock/' .. self.id .. '/edit', 'error', err )
    else
        return header:redirect( '/ipblock/' .. self.id .. '/edit', 'success', 'IP Block updated' )
    end
end

--add IP's manually (ipv4 only)
function ipblock:addIP()
	--ipv6 type
	if self.type ~= 'IPv4' then
		return template:error( 'You can only add IPs manually to IPv4 blocks' )
	end
	--no ip
	if not request.post.ip then
		return template:error( 'Please complete all fields' )
	end

	--get block info for verifying ips inside it
	local block = network.ipv4:blockInfo( self.subnet )

	--split IP's by ,
	local ips = utils.explode( request.post.ip, ',' )

	--loop each ip/bit
	for k, v in pairs( ips ) do
		v = utils.trim( v )

		--work out ranges
		if v:find( '-' ) then
			local range = utils.explode( v, '-' )
			if #range ~= 2 then
				return header:redirect( '/ipblock/' .. self.id, 'error', 'Invalid range' )
			end
			--check each ip in block
			if not network.ipv4:isInBlock( utils.trim( range[1] ), block ) or not network.ipv4:isInBlock( utils.trim( range[2] ), block ) then
				return header:redirect( '/ipblock/' .. self.id, 'error', 'Range IPs not in subnet block' )
			end
			--list the ips
			local iplist, err = network.ipv4:listIPs( utils.trim( range[1] ), utils.trim( range[2] ) )
			if err then
				return header:redirect( '/ipblock/' .. self.id, 'error', 'Range invalid: ' .. err )
			end
			--apply ips to our list (as string from table representation)
			for c, d in pairs( iplist ) do
				table.insert( ips, d[1] .. '.' .. d[2] .. '.' .. d[3] .. '.' .. d[4] )
			end
			ips[k] = nil
		--fail on invalid ip
		elseif not network.ipv4:checkIP( utils.trim( v ) ) then
			return header:redirect( '/ipblock/' .. self.id, 'error', v .. ' is an invalid IP' )
		--fail on ip not in block
		elseif not network.ipv4:isInBlock( utils.trim( v ), block ) then
			return header:redirect( '/ipblock/' .. self.id, 'error', v .. ' is not in subnet block' )
		end
	end

	--setup data for db insert
	local data = {}
	for k, v in pairs( ips ) do
		table.insert( data, { self.id, v } )
	end
	--add ips to database
	local result, err = database:replace( 'network_ipblock_ip', { 'ipblock_id', 'address' }, data )
	if err then
		return header:redirect( '/ipblock/' .. self.id, 'error', err )
	end

	--return
	header:redirect( '/ipblock/' .. self.id, 'success', 'IP\'s Added' )
end

--auto add subnet ips (ipv4 only)
function ipblock:autoIP()
	--ipv6 type
	if self.type ~= 'IPv4' then
		return template:error( 'You can only add subnet IPs to IPv4 blocks' )
	end

	--get block info
	local block = network.ipv4:blockInfo( self.subnet )

	--list IP's
	local iplist, ips = network.ipv4:listIPs( block.start, block.finish ), {}
	--apply ips to our list (as string from table representation)
	for k, v in pairs( iplist ) do
		table.insert( ips, { self.id, v[1] .. '.' .. v[2] .. '.' .. v[3] .. '.' .. v[4] } )
	end

	--add ips to database
	local result, err = database:replace( 'network_ipblock_ip', { 'ipblock_id', 'address' }, ips )
	if err then
		return header:redirect( '/ipblock/' .. self.id, 'error', err )
	end

	--return
	header:redirect( '/ipblock/' .. self.id, 'success', 'IP\'s Added' )
end

--generate IP's (ipv6 only)
function ipblock:generateIP()
	--ipv6 type
	if self.type ~= 'IPv6' then
		return template:error( 'You can only generate IPs on IPv6 blocks' )
	end
	--check input
	if not request.post.bits or not request.post.count or tonumber( request.post.count ) == nil then
		return template:error( 'Please complete all fields' )
	end
	--bits must be multiple of 4 and less than 128 - mask
	local a, b, mask = self.subnet:find( '/(%d+)$' )
	if request.post.bits % 4 ~= 0 or tonumber( request.post.bits ) > 128 - mask then
		return template:error( 'Invalid bits' )
	end

	--get block info
	local block = network.ipv6:blockInfo( self.subnet )

	--generate some ips
	local iplist, ips = network.ipv6:generate( block.start, request.post.bits, request.post.count ), {}
	--apply ips to our list
	for k, v in pairs( iplist ) do
		table.insert( ips, { self.id, v[1] .. ':' .. v[2] .. ':' .. v[3] .. ':' .. v[4] .. ':' .. v[5] .. ':' .. v[6] .. ':' .. v[7] .. ':' .. v[8] } )
	end

	if #ips > 0 then
		--add ips to database
		local result, err = database:replace( 'network_ipblock_ip', { 'ipblock_id', 'address' }, ips )
		if err then
			return header:redirect( '/ipblock/' .. self.id, 'error', err )
		end
	end

	--return
	header:redirect( '/ipblock/' .. self.id, 'success', 'IP\'s Added' )
end

return ipblock