--[[
    file: <service module>/get/groups
    desc: admin users
]]

local template, database, request, user = oxy.template, luawa.database, luawa.request, luawa.user

--add group?
if request.get.action == 'add' then
	if not user:cookiePermission( 'AddUserGroup' ) then return template:error( 'You don\'t have permission to do that' ) end
	return template:wrap( template:loadModule( 'admin', 'groups/add', true ) )

--edit
elseif request.get.action == 'edit' then
	if not user:checkPermission( 'EditUserGroup' ) then return template:error( 'You don\'t have permission to do that' ) end
	if not request.get.id then return template:error( 'You must specify a group ID' ) end

	--select group
	local group, err = database:select( 'user_groups', '*', { id = request.get.id } )
	if err then return template:error( err ) end
	template:set( 'group', group[1] )

	return template:wrap( template:loadModule( 'admin', 'groups/edit', true ) )
end


--default: list groups

--permission?
if not user:checkPermission( 'ViewUserGroup' ) then
	return template:error( 'You don\'t have permission to do that' )
end

local groups = database:select( 'user_groups', '*' )

template:set( 'page_title', 'User Groups' )
template:set( 'groups', groups )
template:add( 'page_title_buttons', { { text = 'Add Group', link = '/admin/groups/add', class = 'admin' } } )
--header+footer+template
template:wrap( template:loadModule( 'admin', 'groups/list', true ) )