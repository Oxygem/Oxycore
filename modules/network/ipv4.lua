-- File: ipv4.lua
-- Desc: ipv4 subnet parsing

local tonumber, type = tonumber, type

local ipv4 = {
	--mask list (1-7 ignored for being stupidly big / never assigned to small enough companies)
	masks = {
		{ 127, 255, 255, 255 }, --/1
		{ 63, 255, 255, 255 },
		{ 31, 255, 255, 255 },
		{ 15, 255, 255, 255 },
		{ 7, 255, 255, 255 },
		{ 3, 255, 255, 255 },
		{ 1, 255, 255, 255 },
		{ 0, 255, 255, 255 }, --/8
		{ 0, 127, 255, 255 },
		{ 0, 63, 255, 255 },
		{ 0, 31, 255, 255 },
		{ 0, 15, 255, 255 },
		{ 0, 7, 255, 255 },
		{ 0, 3, 255, 255 },
		{ 0, 1, 255, 255 }, --/15
		{ 0, 0, 255, 255 },
		{ 0, 0, 127, 255 },
		{ 0, 0, 63, 255 },
		{ 0, 0, 31, 255 },
		{ 0, 0, 15, 255 },
		{ 0, 0, 7, 255 },
		{ 0, 0, 3, 255 },
		{ 0, 0, 1, 255 },
		{ 0, 0, 0, 255 },
		{ 0, 0, 0, 127 },
		{ 0, 0, 0, 63 },
		{ 0, 0, 0, 31 },
		{ 0, 0, 0, 15 },
		{ 0, 0, 0, 7 },
		{ 0, 0, 0, 3 },
		{ 0, 0, 0, 1 } --/31
	}
}

--split ip into usable bits
function ipv4:toTable( ip )
	if type( ip ) == 'table' and #ip == 4 then return ip end
	local a, b, ip1, ip2, ip3, ip4 = ip:find( '^(%d+).(%d+).(%d+).(%d+)$' )
	if not a then return false, 'Invalid IP' end
	return { tonumber( ip1 ), tonumber( ip2 ), tonumber( ip3 ), tonumber( ip4 ) }
end

--is valid ip?
function ipv4:checkIP( ip )
	local ip, err = self:toTable( ip )
	if err then return false, err end

	--check valid up
	for k, v in pairs( ip ) do
		if v > 255 or v < 0 then
			return false, 'Invalid IP'
		end
	end

	return true
end

--return block information for a subnet
function ipv4:blockInfo( subnet )
	--parse input into something usable
	local a, b, ip1, ip2, ip3, ip4, mask = subnet:find( '^(%d+).(%d+).(%d+).(%d+)/(%d+)$')
	if not a then return false, 'Invalid IP' end
	local ip = { tonumber( ip1 ), tonumber( ip2 ), tonumber( ip3 ), tonumber( ip4 ) }

	--check valid ip
	local status, err = self:checkIP( ip )
	if err then return false, err end

	--get wildcard
	local wildcard = self.masks[tonumber(mask)]
	if not wildcard then return false, 'Invalid wildcard' end

	--get ip count (hosts)
	local hosts = math.pow( 2, ( 32 - mask ) )

	--network IP (route/bottom IP)
	local bottomip = {}
	for k, v in pairs( ip ) do
		--wildcard = 0?
		if wildcard[k] == 0 then
			bottomip[k] = v
		elseif wildcard[k] == 255 then
			bottomip[k] = 0
		else
			local mod = v % ( wildcard[k] + 1 )
			bottomip[k] = v - mod
		end
	end

	--use network ip + wildcard to get top ip
	local topip = {}
	for k, v in pairs( bottomip ) do
		topip[k] = v + wildcard[k]
	end

	--return output
	return {
		mask = mask,
		wildcard = wildcard,
		hosts = hosts,
		start = bottomip,
		finish = topip
	}
end

---list IP's in a range given start + end
function ipv4:listIPs( start, finish )
	--convert start & finish into useful, catch invalid ips
	local start, err = self:toTable( start )
	if err then return false, 'Start IP: ' .. err end
	local finish, err = self:toTable( finish )
	if err then return false, 'Finish IP: ' .. err end

	--table w/ start ip
	local ips = { { start[1], start[2], start[3], start[4] } }

	--loop and make our list between the two values
	--basically start at the end, +1, loop back when over 255
	repeat
		start[4] = start[4] + 1
		if start[4] > 255 then
			start[4] = 0
			start[3] = start[3] + 1
		end
		if start[3] > 255 then
			start[3] = 0
			start[2] = start[2] + 1
		end
		if start[2] > 255 then
			start[2] = 0
			start[1] = start[1] + 1
		end
		table.insert( ips, { start[1], start[2], start[3], start[4] } )
	until start[1] == finish[1] and start[2] == finish[2] and start[3] == finish[3] and start[4] == finish[4]

	return ips
end

--check if an IP is within a block/subnet
function ipv4:isInBlock( ip, block )
	local ip, err = self:toTable( ip )
	if err then return false, err end

	--loop each ip bit, check not outside our start/finish of block
	for i = 1, 4 do
		if ip[i] < block.start[i] or ip[i] > block.finish[i] then
			return false
		end
	end

	return true
end


return ipv4