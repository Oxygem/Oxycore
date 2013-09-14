--[[
    file: app/post/module.lua
    desc: Pass module requests on to the module
]]

local oxy, luawa, header, request, user, session, template = oxy, luawa, luawa.header, luawa.request, luawa.user, luawa.session, oxy.template

--try to load the module in question
local module = oxy:loadModule( request.get.module )
--fail? cya!
if not module then
    header:redirect( '/' )
end

--token?
if not request.post.token or not session:checkToken( request.post.token ) then
    return template:error( 'Invalid form token' )
end

local file, public = false, false

--we have a request & it matches up
if request.get.mreq and module.config.requests.post[request.get.mreq] then
    file = module.config.requests.post[request.get.mreq].file
    public = module.config.requests.post[request.get.mreq].public
end

--are we logged in or public?
if not user:checkLogin() and not public then
    header:redirect( '/login' )
end
--no file?
if not file then
	header:redirect( '/' .. request.get.module, 'error', 'Invalid request' )
end

return luawa:processFile( 'modules/' .. request.get.module .. '/' .. file )