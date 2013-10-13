--[[
    file: app/post/login.lua
    desc: login users
]]

--modules
local request, user, header, template, session = luawa.request, luawa.user, luawa.header, luawa.template, luawa.session

--check token
if not session:checkToken( request.post.token ) then
    return header:redirect( '/' )
end

--already logged in?
if user:checkLogin() then
    return header:redirect( '/' )
end

--login user
status, err = user:login( request.post.email, request.post.password )
if status then
    --redirect
    return header:redirect( '/' )
end

--login failed
err = err or 'Invalid email or password'
header:redirect( '/', 'error', err )