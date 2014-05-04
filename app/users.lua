-- Oxypanel Core
-- File: app/users.lua
-- Desc: helper functions to list users

local database = luawa.database

local users = {
    user_cache = {},
    group_cache = {}
}

--get a user
function users:get(id)
    --cached?
    if self.user_cache[id] then return self.user_cache[id] end

    --select user
    local user, err = database:select('user', 'id, email, `group`, name, login_time, register_time, real_name, address, country, credit', { id = id })
    if err then return false, err end

    --get group
    user[1].group_name = self:getGroup(user[1].group).name

    --cache & return
    self.user_cache[id] = user[1]
    return user[1]
end

--get a group
function users:getGroup(id)
    --cached?
    if self.group_cache[id] then return self.group_cache[id] end

    --select group
    local group, err = database:select('user_groups', 'id, name', { id = id })
    if err then return false, err end
    self.group_cache[id] = group[1]
    return group[1]
end

return users