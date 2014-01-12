-- File: node.lua
-- Desc: talks to node (auto & ngx)

local user, socket = luawa.user, ngx.socket
local json = require( 'cjson.safe' )

local ssh = {}

-- Make a request to node, return the request ID (oxyngx.js)
-- in: request table, password (default = use key)
function ssh:request( request, password )
	--open socket
	local node = socket.tcp()
	--port on local (NOT in production) or socket (good)?
	local host, port = '127.0.0.1', oxy.config.oxynode.server_port
	if type( oxy.config.oxynode.server_port ) == 'string' then
		host = 'unix:' .. port
		port = 0
	end
	--connect to node
	local status, err = node:connect( host, port )
	if not status then
		return false, err
	end

	--build request
	request = {
		share_key = oxy.config.oxynode.share_key,
		--commands to run
		commands = request.commands,
		--user info (just keys)
		user = {},
		--server info
		server = {
			host = request.host,
			port = request.port,
			user = request.user
		}
	}
	--password or key
	if password then
		request.server.password = password
	else
		request.server.key = oxy.config.oxyngx.ssh_key
	end
	--user keys
	for i = 1, luawa.user.config.keys do
		request.user['key' .. i] = user:getData()['key' .. i]
	end

	--send json payload
	local bytes, err = node:send( json.encode( request ) )
	if not bytes then
		node:close()
		return false, err
	end
	--receive response
	local data, err = node:receive( '*l' )
	if not data then
		node:close()
		return false, err
	end
	--accepted?, retrieve the key
	local key
	if data == 'ACCEPTED' then
		key, err = node:receive( '*l' )
		if not key then
			node:close()
			return false, err
		end
		node:close()
		return key
	else
		node:close()
		return false, data
	end
end

-- Capture a request (oxyngx.js)
-- in: request key
function ssh:capture( key )
	--open socket
	local node = socket.tcp()
	--port on local (NOT in production) or socket (good)?
	local host, port = '127.0.0.1', oxy.config.oxynode.server_port
	if type( oxy.config.oxynode.server_port ) == 'string' then
		host = 'unix:' .. port
		port = 0
	end
	--connect to node
	local status, err = node:connect( host, port )
	if not status then
		return false, err
	end

	--build request (to capture, not +request)
	request = {
		key = key,
		share_key = oxy.config.oxynode.share_key
	}

	--send json payload
	local bytes, err = node:send( json.encode( request ) )
	if not bytes then
		node:close()
		return false, err
	end

	local line, lines = '', {}
	repeat
		line = node:receive( '*l' )
		if line then table.insert( lines, line ) end
	until line == nil

	return lines
end

-- Capture stats (oxyauto.js)
-- in: device_id
function ssh:stat( id )
end

return ssh