--locals
local database = luawa.database

--service object
local ipblock = {}

--get
function ipblock:get()
	--get ip's
	local ips, err = database:select(
		'service_ipblock_ip', 'service_id, address, status',
		{ ipblock_id = self.id }
	)
	self.ips = ips or {}
	
end

return ipblock