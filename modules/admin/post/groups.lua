--[[
    file: <service module>/post/groups
    desc: admin users
]]

local template, database, request, user, session = oxy.template, luawa.database, luawa.request, luawa.user, luawa.session

--action set?
if not request.get.action then return template:error( 'No action set' ) end

--token
if not request.post.token or not session:checkToken( request.post.token ) then return template:error( 'Invalid token' ) end


--adding
if request.get.action == 'add' then
	--check permission & post data
	if not request.post.name then return template:error( 'Please input a name' ) end
	if not user:checkPermission( 'AddUserGroup' ) then return template:error( 'You do not have permission to do that' ) end

	--add the group
	local status, err = database:insert( 'user_groups', { 'name' }, { { request.post.name } } )
	if err then return template:error( err ) end

	--show groups
	template:set( 'success', 'Group added' )
	request.get.action = nil

--edit
elseif request.get.action == 'edit' then
	--post & permissions
	if not request.post.name or not request.post.id then return template:error( 'ID and name must be set' ) end
	if not user:checkPermission( 'EditUserGroup' ) then return template:error( 'You do not have permission to do that' ) end

	--update group
	local status, err = database:update( 'user_groups', { name = request.post.name }, { id = request.post.id } )
	if err then
		template:set( 'error', err )
	else
		template:set( 'success', 'Group updated' )
		request.get.action = nil
	end

--delete group
elseif request.get.action == 'delete' then
	--id
	if not request.post.id then return template:error( 'No ID set' ) end
	--permission
	if not user:checkPermission( 'DeleteUserGroup' ) then return template:error( 'You do not have permission to do that' ) end

--invalid
else
	return template:error( 'Invalid action' )
end

luawa:processFile( 'modules/admin/get/groups' )