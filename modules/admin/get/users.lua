--[[
    file: <service module>/get/users
    desc: admin users
]]

local template, database, request, user, users = oxy.template, luawa.database, luawa.request, luawa.user, oxy.users

--groups
local groups = database:select( 'user_groups', '*' )
template:set( 'groups', groups )

--add user?
if request.get.action == 'add' then
	if not user:checkPermission( 'AddUser' ) then return template:error( 'You don\'t have permission to do that' ) end
	return template:wrap( template:loadModule( 'admin', 'users/add', true ) )

--edit
elseif request.get.action == 'edit' then
	if not user:checkPermission( 'EditUser' ) then return template:error( 'You don\'t have permission to do that' ) end
	if not request.get.id then return template:error( 'You must specify a group ID' ) end

	template:set( 'user', users:get( request.get.id ) )

	return template:wrap( template:loadModule( 'admin', 'users/edit', true ) )
end


--default: list users

--permission?
if not user:checkPermission( 'ViewUser' ) then
	return template:error( 'You don\'t have permission to do that' )
end


--filters
local wheres = {}

--group
if request.get.group then
	for k, v in pairs( groups ) do
		if tonumber( v.id ) == tonumber( request.get.group ) then
			template:set( 'page_title_meta', 'in group ' .. v.name )
			break
		end
	end
	wheres.group = ( type( request.get.group ) == 'string' and request.get.group ~= '' ) and request.get.group or nil
end

--id
if request.get.id then
	wheres.id = request.get.id
end


--get users
local users = database:select( 'user', '*', wheres )

template:set( 'page_title', 'Users' )
template:set( 'users', users )

template:wrap( 'users/list', 'admin' )