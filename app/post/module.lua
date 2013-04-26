--[[
    file: app/post/module.lua
    desc: Pass module requests on to the module
]]

local oxy, luawa, header, request, user = oxy, luawa, luawa.header, luawa.request, luawa.user

--try to load the module in question
local module = oxy:loadModule( request.get.module )
--fail? cya!
if not module then
    header:redirect( '/' )
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

return luawa:processFile( 'modules/' .. request.get.module .. '/' .. file )