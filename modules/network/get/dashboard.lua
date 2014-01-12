--locals
local template, network, user = oxy.template, oxy.network, luawa.user

--owned services
template:set( 'devices', network.device:getOwned( {}, 'id DESC', 20  ), true )

--owned ip blocks
template:set( 'ipblocks', network.ipblock:getOwned( {}, 'id DESC', 20 ), true )

--owned groups
template:set( 'groups', network.group:getOwned( {}, 'id DESC', 20 ), true )

--page title
template:set( 'page_title', 'Network Devices' )
local buttons = {}
if user:checkPermission( 'ViewAnyDevice' ) then
	table.insert( buttons, { class = 'admin', link = '/network/devices/all', text = 'View All' } )
end
if user:checkPermission( 'AddDevice' ) then
    table.insert( buttons, { class = 'admin', link = '/network/devices/add', text = 'Add Device' } )
end
template:set( 'page_title_buttons', buttons )

--template
template:wrap( template:loadModule( 'network', 'dashboard', true ) )