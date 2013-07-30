local config = {
	parent = 'dedicated',
    group = 'dedicated',
	name = 'Dedicated: Xen',

    --allowed os's (centos only for ovz)
    os = {
        'centos'
    },

    --commands we can run
    commands = {
        --EXAMPLE FOR VZ OWNER
        vzrestart = {
            parent = true, --act on parent service
            permission = 'edit',
            ssh = function( args )
                if not args.vzid then return false end
                return {
                    { input = 'vzctl restart ' .. args.vzid, expected = 'vz ' .. args.vzid .. ' rebooted', hidden = true },
                    { input = 'vzlist', output = 'vzlist' }
                }
            end
        }
    }
}

return config