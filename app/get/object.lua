--[[
    file: app/get/object.lua
    desc: Pass object requests to the module
]]

local oxy, luawa, header, request, user, template = oxy, luawa, luawa.header, luawa.request, luawa.user, oxy.template

--id not set?
if not request.get.id or not request.get.type then return header:redirect( '/' ) end

--find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then return header:redirect( '/' ) end

--not logged in and not public type?
if not user:checkLogin() and not type.public then return header:redirect( '/login' ) end

--try to load the module in question
local module = oxy:loadModule( type.module )
--fail? cya!
if not module then
    return header:redirect( '/' )
end

--set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'
--default template = view
local action = 'view'
--edit template?
if request.get.action == 'edit' then
	action = 'edit'
	--LOAD USER GROUPS FOR EDIT PAGE?
end

--get our object
local object, err = module[request.get.type]:get( request.get.id, action )
if not object then
	template:set( 'error', err )
	--page title
	template:set( 'page_title', 'Error' )
	template:set( 'page_title_meta', '' )
	template:load( 'core/header' )
	return template:load( 'core/footer' )
else
	--run get on object if we're not editing
	if action == 'view' and object.get then object:get() end
	--add to template
	template:set( request.get.type, object, true )
	--set page title
	template:set( 'page_title', object.name )
	if oxy.config.objects[request.get.type].title_meta then
		template:set( 'page_title_meta', object[oxy.config.objects[request.get.type].title_meta] )
		--view/edit buttons
		if action == 'view' and module[request.get.type]:permission( object.id, 'edit' ) then
			template:add( 'page_title_buttons', { { text = 'Edit', link = './' .. object.id .. '/edit' } } )
		elseif action == 'edit' then
			template:add( 'page_title_buttons', { { text = 'View', link = '../' .. object.id } } )
		end
	else
		template:set( 'page_title_meta', '' )
	end
end

--templates
template:load( 'core/header' )
template:loadModule( type.module, request.get.type .. '/' .. action )
template:load( 'core/footer' )