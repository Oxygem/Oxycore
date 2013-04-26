--locals
local template, service, user = oxy.template, oxy.service, luawa.user

--owned services
template:set( 'services', service.service:getOwned( {}, 'id DESC', 20  ), true )

--owned ip blocks
template:set( 'ipblocks', service.ipblock:getOwned( {}, 'id DESC', 20 ), true )

--owned groups
template:set( 'groups', service.group:getOwned( {}, 'id DESC', 20 ), true )

--page title
template:set( 'page_title', 'Services' )
template:set( 'page_title_meta', 'owned by you' )
if user:cookiePermission( 'ViewAnyService' ) then
	template:set( 'page_title_buttons', { { class = 'admin', link = '/service/services/all', text = 'View All' } } )
end

--template
template:load( 'core/header' )
template:loadModule( 'service', 'dashboard' )
template:load( 'core/footer' )