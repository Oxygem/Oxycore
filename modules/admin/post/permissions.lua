--[[
    file: <service module>/post/users
    desc: admin users
]]

local template, database, request, session, user = oxy.template, luawa.database, luawa.request, luawa.session, luawa.user

--token?
if not request.post.token or not session:checkToken( request.post.token ) then
    return template:error( 'Invalid form token' )
end

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

template:set( 'success', 'Permissions updated' )

--end
luawa:processFile( 'modules/admin/get/permissions' )