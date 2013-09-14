local utils = luawa.utils

local ipv6 = {
	characters = {
		1, 2, 3, 4, 5, 6, 7, 8, 9,
		'a', 'b', 'c', 'd', 'e', 'f'
	}
}

--return block information for a subnet
function ipv6:blockInfo( subnet )
	local a, b, ip, mask = subnet:find( '^([%w:]+)/(%d+)$')
	if not a then return false, 'Invalid IP' end
	if mask % 4 ~= 0 then return false, 'Invalid mask' end

	--get ip bits
	local ipbits = utils.explode( ip, ':' )

	--now to build an expanded ip
	local zeroblock
	for k, v in pairs( ipbits ) do
		--length 0? we're at the :: bit
		if v:len() == 0 then
			zeroblock = k

		--length not 0 but not 4, prepend 0's
		elseif v:len() < 4 then
			local padding = 4 - v:len()
			for i = 1, padding do
				ipbits[k] = 0 .. ipbits[k]
			end
		end
	end
	if zeroblock and #ipbits < 8 then
		--remove zeroblock
		ipbits[zeroblock] = '0000'
		local padding = 8 - #ipbits
		
		for i = 1, padding do
			table.insert( ipbits, zeroblock, '0000' )
		end
	end

	--generate wildcard from mask
	local indent = mask / 4
	local wildcardbits = {}
	for i = 0, indent - 1 do
		table.insert( wildcardbits, 'f' )
	end
	for i = 0, 31 - indent do
		table.insert( wildcardbits, '0' )
	end
	--convert into 8 string array each w/ 4 chars
	local count, index, wildcard = 1, 1, {}
	for k, v in pairs( wildcardbits ) do
		if count > 4 then
			count = 1
			index = index + 1
		end
		if not wildcard[index] then wildcard[index] = '' end
		wildcard[index] = wildcard[index] .. v
		count = count + 1
	end

	--loop each letter in each ipbit group
	local topip = {}
	local bottomip = {}
	for k, v in pairs( ipbits ) do
		local topbit = ''
		local bottombit = ''
		for i = 1, 4 do
			local wild = wildcard[k]:sub( i, i )
			local norm = v:sub( i, i )
			if wild == 'f' then
				bottombit = bottombit .. norm
				topbit = topbit .. norm
			else
				bottombit = bottombit .. '0'
				topbit = topbit .. 'f'
			end
		end
		topip[k] = topbit
		bottomip[k] = bottombit
	end

	local ipcount = math.pow( 2, 128 - mask )

	--return output
	return {
		mask = mask,
		widlcard = wildcard,
		hosts = ipcount,
		start = bottomip,
		finish = topip
	}
end

--random character generation for ipv6
function ipv6:randomCharacters( count )
	local string = ''
	for i = 1, count do
		string = string .. self.characters[math.random( 1, #self.characters )]
	end
	return string
end

--generate some random ips
function ipv6:generate( prefix, bits, count )
	local ips = {}

	--loop till count
	for i = 1, count do
		local characters, ip = bits / 4, {}

		--loop each of 8 blocks
		for j = 1, 8 do
			--entire block is same as prefix
			if 32 - characters >= j * 4 then
				ip[j] = prefix[j]
			--entire block is random (36 for +4 characters)
			elseif 36 - characters <= j * 4 then
				ip[j] = self:randomCharacters( 4 )
			--some of block is random
			else
				local chars = characters % 4
				ip[j] = prefix[j]:sub( 1, 4 - chars ) .. self:randomCharacters( chars )
			end
		end

		table.insert( ips, ip )
	end

	return ips
end

return ipv6