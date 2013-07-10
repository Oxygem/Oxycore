--[[
    file: modules/service/services/linux/config.lua
    desc: most basic service with Linux commands available to all
]]
local config = {
    group = 'unix',
    parent = 'linux',
    name = 'Linux: CentOS',

    --javascript file(s) to load on service page
    js = {
    },


    --tabs
    tabs = {
        {
            name = 'Packages',
            js = 'packages',
            order = 8,
            buttons = {
                { name = 'Update', command = 'update_packages', color = 'green' },
                { name = 'Search', command = 'search_packages', color = 'lightblue', data = { name = 'Text to search', id = 'package' } },
                { name = 'Install', command = 'install_package', color = 'lightgreen', data = { name = 'Package to install', id = 'package' } },
                { name = 'List All', command = 'list_packages', color = 'black' }
            },
            permission = 'edit'
        }
    },



    --list of our commands
    commands = {
        --list installed packages
        list_packages = {
            permission = 'view',
            actions = {
                { action = 'exec', command = 'yum list installed', out = 'packages' }
            }
        },
        --update installed packages
        update_packages = {
            permission = 'edit',
            actions = {
                { action = 'exec', command = 'yum update -y', out = 'update' }
            }
        },
        --search packages
        search_packages = {
            permission = 'edit',
            actions = function( args )
                if not args.package then return false, 'args.package not set' end
                local out =  {
                    { action = 'exec', command = 'yum search ' .. args.package, out = 'packages' }
                }
                return out
            end
        },
        --install a package
        install_package = {
            permission = 'edit',
            actions = function( args )
                if not args.package then return false, 'Package not set' end
                local out =  {
                    { action = 'exec', command = 'yum install ' .. args.package .. ' -y', out = 'status' }
                }
                return out
            end
        }
    }
}

return config