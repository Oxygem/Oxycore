--[[
    file: <service module>/get/users
    desc: admin users
]]

local template, database, request, user = oxy.template, luawa.database, luawa.request, luawa.user

--groups
local groups = database:select( 'user_groups', '*' )
template:set( 'groups', groups )

--add user?
if request.get.action == 'add' then
	if not user:cookiePermission( 'AddUser' ) then return template:error( 'You don\'t have permission to do that' ) end
	return template:wrap( template:loadModule( 'admin', 'users/add', true ) )

--edit
elseif request.get.action == 'edit' then
	if not user:checkPermission( 'EditUser' ) then return template:error( 'You don\'t have permission to do that' ) end
	if not request.get.id then return template:error( 'You must specify a group ID' ) end

	--select user
	local user, err = database:select( 'user', '*', { id = request.get.id } )
	if err then return template:error( err ) end
	template:set( 'user', user[1] )

	return template:wrap( template:loadModule( 'admin', 'users/edit', true ) )
end


--default: list users

--permission?
if not user:checkPermission( 'ViewUser' ) then
	return template:error( 'You don\'t have permission to do that' )
end


--group user filter
local wheres = {}
if request.get.group then wheres.group = request.get.group end
--get users
local users = database:select( 'user', '*', wheres )

template:set( 'page_title', 'Users' )
template:set( 'users', users )

template:load( 'core/header' )
template:loadModule( 'admin', 'users/list' )
template:load( 'core/footer' )