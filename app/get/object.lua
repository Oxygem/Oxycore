--[[
    file: app/get/object.lua
    desc: Pass object requests to the module
]]

local oxy, luawa, header, request, user, template = oxy, luawa, luawa.header, luawa.request, luawa.user, oxy.template

--id not set?
if not request.get.id or not request.get.type then return template:error( 'Invalid ID or type' ) end

--find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then return template:error( 'Invalid object type' ) end

--not logged in and not public type?
if not user:checkLogin() and not type.public then return template:error( 'You need to be logged in to do that' ) end

--try to load the module in question
local module = oxy:loadModule( type.module )
--fail? cya!
if not module then
    return template:error( 'Could not find module' )
end

--set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'
--default template = view
local action = 'view'
--edit template?
if request.get.action == 'edit' then
	action = 'edit'
end
if request.get.action == 'owner' then
	action = 'owner'
	--get GROUPS for OWNER CHANGE PAGE?
end

--get our object
local object, err = module[request.get.type]:get( request.get.id, action )
if not object then
	return template:error( err )
else
	--run prepare on object if we're viewing
	if action == 'view' and object.prepareView then object:prepareView() end
	--run prepare on object if we're editing
	if action == 'edit' and object.prepareEdit then object:prepareEdit() end

	--add to template
	template:set( request.get.type, object, true )

	--set page title
	template:set( 'page_title', object.name )
	if oxy.config.objects[request.get.type].title_meta then
		template:set( 'page_title_meta', object[oxy.config.objects[request.get.type].title_meta] )
	end

	--view/edit buttons
	if action == 'view' and module[request.get.type]:permission( object.id, 'edit' ) then
		template:add( 'page_title_buttons', { { text = 'Edit', link = './' .. object.id .. '/edit' } } )
	elseif action == 'edit' then
		template:add( 'page_title_buttons', { { text = 'View', link = '../' .. object.id } } )
	end
	--change owner?
	if module[request.get.type]:permission( object.id, 'owner' ) then
		template:add( 'page_title_buttons', { { text = 'Change Owner', link = '', class = 'admin' } } )
	end
end

--templates
template:load( 'core/header' )
template:loadModule( type.module, request.get.type .. '/' .. action )
template:load( 'core/footer' )