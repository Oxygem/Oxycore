-- Oxypanel Core
-- File: app/get/login.lua
-- Desc: login

local template, user, header = oxy.template, luawa.user, luawa.header

--already logged in?
if user:checkLogin() then
    return header:redirect( '/' )
end

--load templates
template:load( 'head' )
template:load( 'login' )