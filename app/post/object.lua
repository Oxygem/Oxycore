-- Oxypanel Core
-- File: app/post/object.lua
-- Desc: post to object

-- Locals
local ngx = ngx
local luawa, header, request, user, session = luawa, luawa.header, luawa.request, luawa.user, luawa.session
local oxy, template = oxy, oxy.template

-- Id not set?
if not request.get.id or not request.get.type then
    return template:error( 'Invalid ID or type' )
end

-- Find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then
    return template:error( 'Invalid object type' )
end

-- Not logged in and not public type?
if not user:checkLogin() and not type.public then
    return template:error( 'You need to be logged in to do that' )
end

-- Token?
if not request.post.token or not session:checkToken( request.post.token ) then
    return template:error( 'Invalid form token' )
end

-- Try to load the module in question
local module = oxy:loadModule( type.module )
-- Fail? cya!
if not module then
    return template:error( 'Could not find module' )
end


-- Set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'

-- Post action exists?
if not type.posts or not type.posts[request.get.action] then
    return template:error( 'Invalid action' )
end

-- Get our object
local object, err = module[request.get.type]:get( request.get.id, 'view' )
if err then return template:error( err ) end

-- Check permission
if not module[request.get.type]:permission( request.get.id, type.posts[request.get.action].permission ) then
    return template:error( 'You do not have permission to do that' )
end

--enforce api mode
template:setApi( type.posts[request.get.action].api or ngx.ctx.api )

--run the object func
local func = object[request.get.action]
return func( object, request )