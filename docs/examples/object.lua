local object = {}

--object file is for SINGLE objects (lists/etc mysql only, handled by oxycore)


----------------------------------------------------------------------------- required
--prepare - used when fetching object internally w/ prepare enabled

----------------------------------------------------------------------------- GET-prepares
--GET
    --GET/view (prepareView) - API facing
        --would use getIPs, for example
    --GET/edit (prepareEdit)

----------------------------------------------------------------------------- POST-functions
--POST - API facing (list of allowed functions added somewhere in object.posts)
    --individualCommands
    --namedAsWanted
    --setData
    --edit

----------------------------------------------------------------------------- generic-functions
--generic
    --server/getParent
    --server|ipblock/getIPs
        --eg: assigning ip to vm: load parent server object:getIPs( type = 'ipv4', status = 'unused' )
    --ticket/getRelatedObject



----------------------------------------------------------------------------- required
--prepare object internally
function object:prepare()
end
--prepare GET/view
function object:prepareView()
end
--prepare GET/edit
function object:prepareEdit()
end






----------------------------------------------------------------------------- POST-functions
object.posts = { 'edit', 'setData' }

--basic edit
function object:edit()
end

--set some data
function object:setData()
end


----------------------------------------------------------------------------- generic-functions
--get IP's
function object:getIPs()
end

--get parent (presumably object of same type)
function object:getParent()
end

--get related object
function object:getRelatedObject()
end