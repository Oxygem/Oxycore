-- File: app/get/object.lua
-- Desc: Pass object requests to the module

-- Locals
local oxy, luawa, header, request, user, template, utils = oxy, luawa, luawa.header, luawa.request, luawa.user, oxy.template, luawa.utils

-- Id not set?
if not request.get.id or not request.get.type then return template:error( 'Invalid ID or type' ) end

-- Find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then return template:error( 'Invalid object type' ) end

-- Not logged in and not public type?
if not user:checkLogin() and not type.public then return template:error( 'You need to be logged in to do that' ) end

--try to load the module in question
local module = oxy:loadModule( type.module )
-- No module? cya!
if not module then
    return template:error( 'Could not find module' )
end

-- Set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'

-- Defaults
local action, permission, wrap = 'view', 'view', true
-- Edit?
if request.get.action == 'edit' then
	action, permission = 'edit', 'edit'
-- Change owner?
elseif request.get.action == 'owner' then
	action, permission = 'owner', 'owner'
-- Custom action?
else
	if type.actions and type.actions[request.get.action] then
		action, permission = request.get.action, type.actions[request.get.action].permission
		if type.actions[request.get.action].wrap ~= nil then wrap = type.actions[request.get.action].wrap end
	end
end

-- Get our object
local object, err = module[request.get.type]:get( request.get.id, permission )
if not object then
	return template:error( err )
else
	--prepare function?
	if object['prepare' .. utils.capitalizeFirst( action )] then object['prepare' .. utils.capitalizeFirst( action )]( object ) end

	--add to template
	template:set( request.get.type, object, true )

	--set page title
	template:set( 'page_title', object.name )
	if oxy.config.objects[request.get.type].title_meta then
		local title_meta = oxy.config.objects[request.get.type].title_meta:gsub( '{([aA-zZ0-9]+)}', function( key ) return object[key] end )
		template:set( 'page_title_meta', title_meta )
	end

	--view/edit buttons
	if action == 'view' and module[request.get.type]:permission( object.id, 'edit' ) then
		template:add( 'page_title_buttons', {{ text = 'Edit', link = './' .. object.id .. '/edit' }})
	elseif action == 'edit' then
		template:add( 'page_title_buttons', {{ text = 'View', link = '../' .. object.id } } )
	end
	--change owner?
	if module[request.get.type]:permission( object.id, 'owner' ) then
		template:add( 'page_title_buttons', {{ text = 'Change Owner', link = '', class = 'admin' }})
	end
end

-- Load templates
if wrap then
	template:wrap( request.get.type .. '/' .. action, type.module )
else
	template:loadModule( type.module, request.get.type .. '/' .. action )
end