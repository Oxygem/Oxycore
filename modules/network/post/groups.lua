local request, template, database, user, header = luawa.request, oxy.template, luawa.database, luawa.user, luawa.header

if request.get.action == 'add' then
    --permission
    if not user:checkPermission( 'AddGroup' ) then
        return template:error( 'You do not have permission to add groups' )
    end

    --details
    if not request.post.name then
        return template:error( 'Please fill out all fields' )
    end

    --add to database
    local result, err = database:insert( 'network_group',
        { 'user_id', 'name' },
        { { user:getData().id, request.post.name } }
    )
    if not result or not result.insert_id then
        template:error( err )
    end
    
    --redirect to new block
    header:redirect( '/group/' .. result.insert_id, 'success', 'Group added' )
end