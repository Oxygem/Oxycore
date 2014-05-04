-- Oxypanel Core
-- File: app/get/module.lua
-- Pass module requests to module

local oxy, luawa, header, request, user, template = oxy, luawa, luawa.header, luawa.request, luawa.user, oxy.template

--try to load the module in question
local module = oxy:loadModule(request.get.module)
--module exists & we have permission
if not module or not user:checkPermission('Module' .. request.get.module) then
    return template:error('You don\'t have permission to do that')
end

local req
--we have a request & it matches up
if request.get.module_request then
    if not module.config.requests.get[request.get.module_request] then
        return template:error('Invalid request for this module')
    end
    req = module.config.requests.get[request.get.module_request]
--default
else
    req = module.config.requests.get.default
end

local file, public, args = req.file, req.public, req.args or {}
request.args = args

return luawa:processFile('modules/' .. request.get.module .. '/' .. file)