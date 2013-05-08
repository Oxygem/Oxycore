--[[
    file: app/object.lua
    desc: Manage object storage
]]

--localize luawa
local database, user = luawa.database, luawa.user

--oxy.object
local object = {}


--new object 'factory'
function object:new( type )
    if not oxy.config.objects[type] then return false end

    --create new object, set type
    local object = { type = type, module = oxy.config.objects[type].module, cache = {} }
    object.fields = oxy.config.objects[type].fields or '*'

    --make object use self as index
    self.__index = self
    setmetatable( object, self ) --this + above essentially makes object inherit self's methods

    --return the new object class w/ type set
    return object
end


--fetch an object as lua object (NO permission checks - ie internal)
function object:fetch( id, prepare )
    if self.cache[id] then return self.cache[id] end --cache so we can 'accidentally' load the same object multiple times w/o extra mysql

    --get object from mysql
    local object, err = database:select(
        self.module .. '_' .. self.type, self.fields,
        { id = id },
        order, limit, offset
    )
    --if we got none back
    if #object ~= 1 then
        err = 'No ' .. self.type .. ' found'
        return false, err
    end
    object = object[1]

    --load the object 'class' according to type
    local type = require( oxy.config.root .. 'modules/' .. self.module .. '/object/' .. self.type )

    --set our new objects index to that of the type
    type.__index = type
    setmetatable( object, type ) --this + above essentially makes object inherit type's methods

    --run any prepare function
    if prepare and object.prepare then object:prepare() end

    --add to our cache
    self.cache[id] = object

    return object
end

--get an object w/ permission check on active user
function object:get( id, permission )
    --permission
    permission = permission or 'view'
    --not logged in?
    if not user:checkLogin() then return false, 'You need to be logged in' end

    --we got permission?
    if not self:permission( id, permission ) then return false, 'You don\'t have permission to ' .. permission .. ' this ' .. self.type end

    --fetch!
    return self:fetch( id, true )
end

--check current user permissions on object (Admin, View, Edit)
function object:permission( id, permission )
    --not logged in?
    if not user:checkLogin() then return false end

    --permission to any
    if user:checkPermission( permission .. 'Any' .. self.type ) then
        return true
    end

    --permission to owned
    if user:checkPermission( permission .. 'Own' .. self.type ) then
        local test = database:select(
            self.module .. '_' .. self.type, 'id',
            { id = id, { user_id = user:getData().id, group_id = user:getData().group } },
            'id ASC', 1
        )
        if #test == 1 then
            return true
        end
    end

    --default response
    return false
end


--get all objects (mysql list only)
function object:getAll( wheres, order, limit, offset )
    return self:getList( wheres, order, limit, offset, true )
end

--get all owned objects (mysql list only)
function object:getOwned( wheres, order, limit, offset )
    return self:getList( wheres, order, limit, offset )
end

--get list of objects from mysql (DRY, see above)
function object:getList( wheres, order, limit, offset, all )
    --not logged in?
    if not user:checkLogin() then return false, 'You need to be logged in' end
    --type edit/delete permissions
    local type, edit, delete = self.type, false, false

    wheres = wheres or {}

    --are we looking for all objects, or just owned
    if all then
        --do we have permission to ViewAny<Object>
        if not user:checkPermission( 'ViewAny' .. type ) then return false, 'You don\'t have permission view all ' .. type .. 's' end
        if user:cookiePermission( 'EditAny' .. type ) then edit = true end
        if user:cookiePermission( 'DeleteAny' .. type ) then delete = true end
    else
        --do we have permission to ViewOwn<Object>
        if not user:checkPermission( 'ViewOwn' .. type ) then return false, 'You don\'t have permission view owned ' .. type .. 's' end
        if user:cookiePermission( 'EditOwn' .. type ) then edit = true end
        if user:cookiePermission( 'DeleteOwn' .. type ) then delete = true end
        --make sure we match user or group id
        table.insert( wheres, { user_id = user:getData().id, group_id = user:getData().group } )
    end

    --get objects from mysql
    local objects = database:select(
        self.module .. '_' .. self.type, self.fields,
        wheres,
        order, limit, offset
    )
    --assign edit & delete permissions
    for k, object in pairs( objects ) do
        object.permissions = { edit = edit, delete = delete }
    end
    return objects
end


return object