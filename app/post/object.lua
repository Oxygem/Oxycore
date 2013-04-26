--[[
    file: app/post/object.lua
    desc: Pass object requests to the module
]]

local oxy, luawa, header, request, user, session = oxy, luawa, luawa.header, luawa.request, luawa.user, luawa.session

--id not set?
if not request.get.id or not request.get.type then return header:redirect( '/' ) end

--find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then return header:redirect( '/' ) end

--not logged in and not public type?
if not user:checkLogin() and not type.public then return header:redirect( '/login' ) end

--token?
if not request.post.token or not session:checkToken( request.post.token ) then
    return header:redirect( '/' )
end

--try to load the module in question
local module = oxy:loadModule( type.module )
--fail? cya!
if not module then
    return header:redirect( '/' )
end

--set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'

--get our object
local object, err = module[request.get.type]:get( request.get.id, action )
if err or not object.posts[request.get.action] or not object[request.get.action] then
    return header:redirect( '/' )
else
    local func = object[request.get.action]
    return func( object )
end