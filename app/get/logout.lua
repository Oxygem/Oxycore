local user, header = luawa.user, luawa.header

--logout the user
if user:logout() then
    return header:redirect('/login')
else
    return header:redirect('/')
end