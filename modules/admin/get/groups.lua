-- Oxypanel Core/Admin
-- File: get/groups.lua
-- Desc: add/edit/list user groups

local template, database, request, user = oxy.template, luawa.database, luawa.request, luawa.user

--add group?
if request.get.action == 'add' then
    if not user:checkPermission( 'AddUserGroup' ) then return template:error( 'You don\'t have permission to do that' ) end
    return template:wrap( 'admin', 'groups/add' )

--edit
elseif request.get.action == 'edit' then
    if not user:checkPermission( 'EditUserGroup' ) then return template:error( 'You don\'t have permission to do that' ) end
    if not request.get.id then return template:error( 'You must specify a group ID' ) end

    --select group
    local group, err = database:select( 'user_groups', '*', { id = request.get.id } )
    if err then return template:error( err ) end
    template:set( 'group', group[1] )

    return template:wrap( 'admin', 'groups/edit' )
end


--default: list groups

--permission?
if not user:checkPermission( 'ViewUserGroup' ) then
    return template:error( 'You don\'t have permission to do that' )
end

--filters
local wheres = {}

if request.get.id then
    wheres.id = request.get.id
end

local groups = database:select( 'user_groups', '*', wheres )

template:set( 'page_title', 'User Groups' )
template:set( 'groups', groups )
if user:checkPermission( 'AddUserGroup' ) then
    template:add( 'page_title_buttons', { { text = 'Add Group', link = '/admin/groups/add', class = 'admin' } } )
end
--header+footer+template
template:wrap( 'admin', 'groups/list' )