--[[
    file: app/post/object.lua
    desc: Pass object requests to the module
]]

local oxy, luawa, header, request, user, session, template = oxy, luawa, luawa.header, luawa.request, luawa.user, luawa.session, oxy.template

--id not set?
if not request.get.id or not request.get.type then return template:error( 'Invalid ID or type' ) end

--find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then return template:error( 'Invalid object type' ) end

--not logged in and not public type?
if not user:checkLogin() and not type.public then return template:error( 'You need to be logged in to do that' ) end

--token?
if not request.post.token or not session:checkToken( request.post.token ) then
    return template:error( 'Invalid form token' )
end

--try to load the module in question
local module = oxy:loadModule( type.module )
--fail? cya!
if not module then
    return template:error( 'Could not find module' )
end

--set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'

--get our object
local object, err = module[request.get.type]:get( request.get.id, 'view' )
if err or not object.posts[request.get.action] or not object[request.get.action] then
    return template:error( 'Could not find action ' .. request.get.action .. ' for this object' )

--no permission (cant be done when GETTING as we need GET.post to get the permission to check)?
elseif not module[request.get.type]:permission( request.get.id, object.posts[request.get.action] ) then
	return template:error( 'You do not have permission to do that' )

else
    local func = object[request.get.action]
    return func( object, request )
end