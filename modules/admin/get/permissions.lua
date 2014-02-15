-- Oxypanel Admin
-- File: get/permissions.lua
-- Display permissions set in table

local template, database, request, user = oxy.template, luawa.database, luawa.request, luawa.user

--login & permission check
if not user:checkPermission( 'ViewPermission' ) then
	return template:error( 'You do not have permission to do that' )
end

local action = 'user/list'


--select groups
local groups = database:select( 'user_groups' )

--select/build set permissions table
local set_permissions = {}
for k, v in pairs( database:select( 'user_permissions' )) do
	set_permissions[v.group .. v.permission] = true
end

--generate permissions list based on modules & objects
local full_permissions = {}
--add modules
for k, v in pairs( oxy.config.modules ) do
	local module = oxy.config[v]
	table.insert( full_permissions, 'Module' .. module.name )
	--custom permissions?
	if module.permissions then
		if not full_permissions[module.name] then full_permissions[module.name] = {} end
		full_permissions[module.name]['General'] = module.permissions
	end
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
	if v.permissions then
		for c, d in pairs( v.permissions ) do
			table.insert( full_permissions[v.module][v.name], d .. 'Own' .. v.permission )
			table.insert( full_permissions[v.module][v.name], d .. 'Any' .. v.permission )
		end
	end
end

--set data
template:set( 'page_title', 'User Permissions' )
template:set( 'full_permissions', full_permissions )
template:set( 'set_permissions', set_permissions )
template:set( 'groups', groups )

--load template
template:wrap( 'permissions', 'admin' )