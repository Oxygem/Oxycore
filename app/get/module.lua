--[[
    file: app/get/module.lua
    desc: Pass module requests on to the module
]]

local oxy, luawa, header, request, user, template = oxy, luawa, luawa.header, luawa.request, luawa.user, oxy.template

--try to load the module in question
local module = oxy:loadModule( request.get.module )
--fail? cya!
if not module or not user:checkPermission( 'Module' .. request.get.module ) then
    return template:error( 'You don\'t have permission to do that' )
end

local req
--we have a request & it matches up
if request.get.mreq and module.config.requests.get[request.get.mreq] then
    req = module.config.requests.get[request.get.mreq]
--default
else
    req = module.config.requests.get.default
end

local file, public, args = req.file, req.public, req.args or {}
request.args = args

--are we logged in or public?
if not user:checkLogin() and not public then
    header:redirect( '/login' )
end

return luawa:processFile( 'modules/' .. request.get.module .. '/' .. file )