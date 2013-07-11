--[[
    file: <service module>/get/users
    desc: admin users
]]

local template, database, request = oxy.template, luawa.database, luawa.request
local action = 'user/list'

--permissions page
if request.get.action == 'permissions' then
	--select groups
	local groups = database:select( 'user_groups', '*' )

	--select/build set permissions table
	local set_permissions = {}
	for k, v in pairs( database:select( 'user_permissions', '*' ) ) do
		set_permissions[v.group .. v.permission] = true
	end

	--generate permissions list based on modules & objects
	local full_permissions = {}
	--add modules
	for k, v in pairs( oxy.config.modules ) do
		table.insert( full_permissions, 'Module' .. oxy.config[k].name )
	end
	--add objects
	for k, v in pairs( oxy.config.objects ) do
		v.module = oxy.config[v.module].name
		if not full_permissions[v.module] then full_permissions[v.module] = {} end
		full_permissions[v.module][v.name] = {
			'Add' .. v.permission,
			'ViewOwn' .. v.permission,
			'ViewAny' .. v.permission,
			'EditOwn' .. v.permission,
			'EditAny' .. v.permission,
			'OwnerOwn' .. v.permission,
			'OwnerAny' .. v.permission,
			'DeleteOwn' .. v.permission,
			'DeleteAny' .. v.permission
		}
	end

	template:set( 'page_title', 'User Permissions' )
	template:set( 'full_permissions', full_permissions )
	template:set( 'set_permissions', set_permissions )
	template:set( 'groups', groups )
	action = 'user/permissions'

--groups page
elseif request.get.action == 'groups' then

--add user page
elseif request.get.action == 'add' then

--list
else

end

template:load( 'core/header' )
template:loadModule( 'admin', action )
template:load( 'core/footer' )