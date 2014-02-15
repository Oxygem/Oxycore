-- Oxypanel Core
-- File: app/object.lua
-- Desc: generic object handler (mapped to <module>_<object-type> in db)

--localize luawa
local database, user = luawa.database, luawa.user

--oxy.object
local object = {}


--new object 'factory'
function object:new( type )
    if not oxy.config.objects[type] then return false end

    --create new object, set type
    local object = { type = type, module = oxy.config.objects[type].module, cache = {} }
    --if custom fields for lists
    object.fields = oxy.config.objects[type].fields or true

    --make object use self as index
    self.__index = self
    setmetatable( object, self ) --this + above essentially makes object inherit self/object's methods

    --return the new object class w/ type set
    return object
end


--fetch an object as lua object (NO permission checks - ie internal)
function object:fetch( id, prepare, fields )
    local tmp = luawa.request.tmp
    if tmp[self.type .. id] then
        return tmp[self.type .. id]
    end

    fields = fields or 'id, name'
    --get object from mysql (get all fields - assume need all on fetch)
    local object, err = database:select(
        self.module .. '_' .. self.type, fields,
        { id = id },
        { limit = 1 }
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

    --helper functions
    local this = self
    --edit object details in database
    object._edit = function( self, data )
        if not this:permission( self.id, 'edit' ) then return false, 'You do not have permission to edit this ' .. this.type end
        --update database
        local update, err = database:update(
            this.module .. '_' .. this.type, data,
            { id = self.id },
            1
        )
        return update, err
    end
    --delete the object
    object._delete = function( self )
        return this:delete( self.id )
    end

    --run any prepare function
    if prepare and object.prepare then object:prepare() end

    tmp[self.type .. id] = object
    return object
end

--get an object w/ permission check on active user
function object:get( id, permission )
    --permission
    permission = permission or 'view'
    --not logged in?
    if not user:checkLogin() then return false, 'You need to be logged in' end

    --we got permission?
    if not self:permission( id, permission ) then return false, 'You do not have permission to ' .. permission .. ' this ' .. self.type end

    --fetch!
    return self:fetch( id, true, '*' )
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
        local tmp, tmp_key = luawa.request.tmp, self.type .. id .. user:getData().id
        if tmp[tmp_key] ~= nil then
            return tmp[tmp_key]
        end

        local test = database:select(
            self.module .. '_' .. self.type, 'id',
            { id = id, { user_id = user:getData().id, group_id = user:getData().group } },
            'id ASC', 1
        )
        if #test == 1 then
            tmp[tmp_key] = true
            return true
        else
            tmp[tmp_key] = false
        end
    end

    --default response
    return false
end

--delete (mysql only)
function object:delete( id )
    --we got permission?
    if not self:permission( id, 'delete' ) then return false, 'You do not have permission to delete this ' .. self.type end

    --delete
    local delete, err = database:delete(
        self.module .. '_' .. self.type,
        { id = id },
        1
    )

    return delete, err
end


--get all objects (mysql list only)
function object:getAll( wheres, options )
    return self:getList( wheres, options, true )
end

--get all owned objects (mysql list only)
function object:getOwned( wheres, options )
    return self:getList( wheres, options )
end

--get list of objects from mysql (DRY, see above)
function object:getList( wheres, options, all )
    --not logged in?
    if not user:checkLogin() then return false, 'You need to be logged in' end
    --type edit/delete permissions
    local type, edit, delete, ownedit, owndelete = self.type, false, false, false, false

    wheres = wheres or {}

    --are we looking for all objects, or just owned
    if all then
        --do we have permission to ViewAny<Object>
        if not user:checkPermission( 'ViewAny' .. type ) then return false, 'You do not have permission view all ' .. type .. 's' end
        if user:checkPermission( 'EditAny' .. type ) then edit = true end
        if user:checkPermission( 'EditOwn' .. type ) then ownedit = true end
        if user:checkPermission( 'DeleteAny' .. type ) then delete = true end
        if user:checkPermission( 'DeleteOwn' .. type ) then owndelete = true end
    else
        --do we have permission to ViewOwn<Object>
        if not user:checkPermission( 'ViewOwn' .. type ) then return false, 'You do not have permission view owned ' .. type .. 's' end
        if user:checkPermission( 'EditOwn' .. type ) then edit = true end
        if user:checkPermission( 'DeleteOwn' .. type ) then delete = true end
        --make sure we match user or group id
        table.insert( wheres, { user_id = user:getData().id, group_id = user:getData().group } )
    end

    --get objects from mysql (only get fields needed for lists)
    local objects = database:select(
        self.module .. '_' .. self.type, self.fields,
        wheres,
        options
    )
    --assign edit & delete permissions
    for k, object in pairs( objects ) do
        object.permissions = { edit = edit, delete = delete }
        if all and ( object.user_id == user:getData().id or object.group_id == user:getData().group ) then
            if not delete then object.permissions.delete = owndelete end
            if not edit then object.permissions.edit = ownedit end
        end
    end
    return objects
end


return object