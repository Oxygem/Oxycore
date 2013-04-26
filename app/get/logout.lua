local template, user, header = luawa.template, luawa.user, luawa.header

--logout the user
if user:logout() then
    return header:redirect( '/login' )
else
    return header:redirect( '/' )
end