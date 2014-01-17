--[[
    file: app/get/profile.lua
    desc: user profile settings
]]

--get template
local template, header, user, countries = oxy.template, luawa.header, luawa.user, require( oxy.config.root .. 'app/countries' ).list

--profile is not public
if not user:checkLogin() then
    return header:redirect( '/login' )
end

--page title
template:set( 'page_title', 'Your Profile' )
--country list
template:set( 'countries', countries )
--user data
template:set( 'user', user:getData() )

--load templates
template:load( 'header' )
template:load( 'profile' )
template:load( 'footer' )