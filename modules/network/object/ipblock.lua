--locals
local database = luawa.database

--service object
local ipblock = {}

--get
function ipblock:prepareView()
	--get ip's
	local ips, err = database:select(
		'network_ipblock_ip', 'device_id, address, status',
		{ ipblock_id = self.id }
	)
	self.ips = ips or {}
end

return ipblock