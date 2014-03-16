-- File: app/post/profile
-- Desc: update profile

-- Modules
local user, header, request, template, countries, session = luawa.user, luawa.header, luawa.request, oxy.template, require( oxy.config.root .. 'app/countries' ).iso, luawa.session

-- Login? or invalid request (update type MUST be set)
if not user:checkLogin() or not request.post.update then
    return header:redirect( '/' )
end

-- Token?
if not request.post.token or not session:checkToken( request.post.token ) then
    return template:error( 'Invalid token' )
end

-- Update SSH key?
if request.post.update == 'ssh' then

-- Update address?
elseif request.post.update == 'address' then
    --make sure we have stuff
    if not request.post.address or not request.post.country or not countries[request.post.country] then
        return template:error( 'Please fill out all details' )
    end

    --update
    local status, err = user:setData({
        real_name = request.post.real_name,
        address = request.post.address,
        country = request.post.country
    })
    if not status then
        return header:redirect( '/profile', 'error', err )
    else
        return header:redirect( '/profile', 'success', 'Address updated' )
    end

-- Update details?
else
    --make sure we have stuff
    if not request.post.name or not request.post.email then
        return template:error( 'Please provide an email and a name' )
    elseif not request.post.email:find( '^[^@]+@' ) then
        return header:redirect( '/profile', 'error', 'Please use a valid email address' )
    elseif request.post.phone and not tonumber( request.post.phone ) then
        return header:redirect( '/profile', 'error', 'Please enter a valid phone number' )
    else
        --update
        local status, err = user:setData({
            name = request.post.name,
            email = request.post.email,
            phone = tonumber( request.post.phone ),
            password = request.post.password,
            two_factor = request.post.two_factor == 'on' and 1 or 0
        })
        if not status then
            return header:redirect( '/profile', 'error', err )
        else
            return header:redirect( '/profile', 'success', 'Profile updated' )
        end
    end
end