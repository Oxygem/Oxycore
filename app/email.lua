--[[
    file: app/object.lua
    desc: Manage object storage
]]

--our email class
local email = {}
--set our email to inherit luawa.email's methods
luawa.email.__index = luawa.email
setmetatable( email, luawa.email )

return email