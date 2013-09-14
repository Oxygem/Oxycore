--[[
    file: <service module>/post/users
    desc: admin users
]]

local template, database, request, session, user, header = oxy.template, luawa.database, luawa.request, luawa.session, luawa.user, luawa.header

--login & permission
if not user:checkLogin() or not user:checkPermission( 'EditPermission' ) then
	return template:error( 'You do not have permission to do that' )
end

--get ALL posts (lots of permissions)
request.post = ngx.req.get_post_args( 0 )

--work out permissions from POST
local permissions = {}
for k, v in pairs( request.post ) do
	if v == 'on' then
		local a, b, group, permission = k:find( '(%d)_([%w]+)')
		if a then
			table.insert( permissions, { group, permission } )
		end
	end
end

--delete all permissions
database:delete( 'user_permissions' )
--re-add new permissions
database:insert( 'user_permissions', { 'group', 'permission' }, permissions )

--flush the user shared memory, force permission reload
ngx.shared[luawa.shm_prefix .. 'user']:flush_all()

--redirect
header:redirect( '/admin/permissions', 'success', 'Permissions updated' )