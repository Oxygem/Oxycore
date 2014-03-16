-- Oxypanel Core
-- File: app/get/object.lua
-- Desc: Process object related requests using the object factory from the module

-- Locals
local header, request, user, utils, database = luawa.header, luawa.request, luawa.user, luawa.utils, luawa.database
local oxy, template, users = oxy, oxy.template, oxy.users

-- Id not set?
if not request.get.id or not request.get.type then
    return template:error( 'Invalid ID or type' )
end

-- Find our object type
local type = oxy.config.objects[request.get.type]
if not type or type.hidden then
    return template:error( 'Invalid object type' )
end

-- Not logged in and not public type?
if not user:checkLogin() then
    return template:error( 'You need to be logged in to do that' )
end

--try to load the module in question
local module = oxy:loadModule( type.module )
-- No module? cya!
if not module then
    return template:error( 'Could not find module' )
end


-- Set our request module to the module (for header)
request.get.module = type.module
request.get.mreq = request.get.type .. 's'

-- Defaults
local action, permission
local wrap, api = true, ngx.ctx.api

-- View?
if not request.get.action then
    action, permission = 'view', 'view'

-- Edit?
elseif request.get.action == 'edit' then
    action, permission, api = 'edit', 'edit', false

-- Change owner?
elseif request.get.action == 'owner' then
    action, permission, api = 'owner', 'owner', false

-- Custom action?
elseif type.actions and type.actions[request.get.action] then
    action, permission = request.get.action, type.actions[request.get.action].permission
    --wrap the template?
    if type.actions[request.get.action].wrap ~= nil then
        wrap = type.actions[request.get.action].wrap
    end
    --explicitly force api on/off
    if type.actions[request.get.action].api ~= nil then
        api = type.actions[request.get.action].api
    end
else
    return template:error( 'Invalid action' )
end
--enforce api mode
luawa.template:setApi( api )

-- Get our object
local object, err = module[request.get.type]:get( request.get.id, permission )
if not object then
    return template:error( err )
else
    --prepare function?
    local action_permission = utils.capitalizeFirst( action )
    if object['prepare' .. action_permission] then
        object['prepare' .. action_permission]( object )
    end

    --add to template
    template:set( request.get.type, object, true )

    --set page title
    template:set( 'page_title', ( action ~= 'view' and utils.capitalizeFirst( action ) .. ' ' or '' ) .. object.name )
    if oxy.config.objects[request.get.type].title_meta then
        local title_meta = oxy.config.objects[request.get.type].title_meta:gsub(
            '{([aA-zZ0-9]+)}',
            function( key ) return object[key] end
        )
        template:set( 'page_title_meta', title_meta )
    end

    --not view, show view link
    if action ~= 'view' then
        template:add( 'page_title_buttons', {{ text = 'View', link = '../' .. object.id }})
    end

    --not edit, w/ permission to edit
    if action ~= 'edit' and module[request.get.type]:permission( object.id, 'edit' ) then
        template:add( 'page_title_buttons', {{ text = 'Edit', link = '/' .. object._type .. '/' .. object.id .. '/edit' }})
    end

    --not owner w/ permission to owner
    if action ~= 'owner' and module[request.get.type]:permission( object.id, 'owner' ) then
        template:add( 'page_title_buttons', {{ text = 'Change Owner', link = '/' .. object._type .. '/' .. object.id .. '/owner', class = 'admin' }})
    end
end

-- Load templates
if action == 'owner' then
    --get users
    local users = database:select( 'user', { 'id', 'name' })
    template:set( 'users', users )
    --get groups
    local groups = database:select( 'user_groups', { 'id', 'name' })
    template:set( 'groups', groups )

    template:set( 'object', object )
    template:wrap( false, 'owner' )
elseif not api then
    if wrap then
        template:wrap( type.module, request.get.type .. '/' .. action )
    else
        template:loadModule( type.module, request.get.type .. '/' .. action )
    end
end