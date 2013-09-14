--[[
    file: <service module>/post/users
    desc: admin users
]]

local template, database, request, user, session, header = oxy.template, luawa.database, luawa.request, luawa.user, luawa.session, luawa.header

--action set?
if not request.get.action then return template:error( 'No action set') end

--add user?
if request.get.action == 'add' then
	--check variables
	if not request.post.email or not request.post.name or not request.post.password then return template:error( 'Please fill out all fields' ) end
	--permission
	if not user:checkPermission( 'AddUser' ) then return template:error( 'You do not have permission to do that' ) end

	--register user
	local status, err = user:register( request.post.email, request.post.password, request.post.name )
	if err then
		return header:redirect( '/admin/users/add', 'error', err )
	else
		return header:redirect( '/admin/users', 'success', 'User added' )
	end

--edit user
elseif request.get.action == 'edit' then
	--id or bits
	if not request.post.id or not request.post.name or not request.post.email then return template:error( 'No ID set' ) end
	--permission
	if not user:checkPermission( 'EditUser' ) then return template:error( 'You do not have permission to do that' ) end

	--fix group
	request.post.group = request.post.group or 1

	--update our user
	local status, err = database:update( 'user', {
		name = request.post.name,
		email = request.post.email,
		group = request.post.group
	}, { id = request.post.id } )
	if err then
		return header:redirect( '/admin/users/edit?id=' .. request.post.id, 'error', err )
	else
		return header:redirect( '/admin/users', 'success', 'User updated' )
	end

--delete user
elseif request.get.action == 'delete' then
	--id
	if not request.post.id then return template:error( 'No ID set' ) end
	--permission
	if not user:checkPermission( 'DeleteUser' ) then return template:error( 'You do not have permission to do that' ) end

	--delete the user
	local status, err = database:delete( 'user', { id = request.post.id } )
	if err then
		return header:redirect( '/admin/users', 'error', err )
	else
		return header:redirect( '/admin/users', 'success', 'User deleted' )
	end
--invalid
else
	return template:error( 'Invalid action' )
end