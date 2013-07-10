--[[
    file: <service module>/ssh.lua
    desc: ssh connection management
]]
local user, socket = luawa.user, ngx.socket
local json = require( 'cjson.safe' )

local ssh = {}

--make a request to node, return the request ID
function ssh:request( request )
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
		--allow user to write back?
		interactive = request.interactive,
		--commands to run
		commands = request.commands,
		--user info (just keys)
		user = {},
		--server info
		server = {
			host = request.host,
			port = request.port,
			user = request.user,
			key = oxy.config.oxyngx.ssh_key
		}
	}
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
--[[
	request = {
		key = key,
		share_key = 'thisisasharedkey'
	}

	node = socket.tcp()
	local status, err = node:connect( '127.0.0.1', 9003 )
	if not status then
		return false, err
	end
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

	return luawa.utils:tableString( lines )
]]
end

return ssh