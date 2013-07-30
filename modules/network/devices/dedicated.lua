--[[
    file: service/services/dedicated.lua
    desc: adds hardware info for dedicated Linux
]]
local config = {
    parent = 'linux',
    group = 'dedicated',
	name = 'Dedicated',

    --javascript file(s) to load on service page
    js = {
        'server.dedicated.js'
    },

    tabs = {
        {
            name = 'Control',
            js = 'control',
            buttons = {
                { name = 'Status', command = 'status', color = 'black' },
                { name = 'Reboot', command = 'reboot', color = 'lightblue', confirm = 'Are you sure you wish to reboot this server' },
                { name = 'Shutdown', command = 'shutdown', color = 'red', confirm = 'You will not be able to reboot the server via Oxypanel' }
            },
            default = true
        },
        {
            name = 'Hardware',
            js = 'hardware',
            permission = 'view',
            order = 7,
            buttons = {
                { name = 'List CPUs', command = 'list_cpu', color = 'black' },
                { name = 'List Memory', command = 'list_memory', color = 'black' },
                { name = 'List Disks', command = 'list_disks', color = 'black' }
            }
        }
	},

    --list of our commands
    commands = {
        --list cpu
        list_cpu = {
            permission = 'view',
            ssh = {
                --all distros
                all = {
                    { input = 'cat /proc/cpuinfo', output = 'cpuinfo' }
                }
            }
        },
        --list memory
        list_memory = {
            permission = 'view',
            ssh = {
                --all distros
                all = {
                    { input = 'cat /proc/meminfo', output = 'meminfo' }
                }
            }
        },
        --list disks
        list_disks = {
            permission = 'view',
            ssh = {
                --all distros
                all = {
                    { input = 'cat /proc/partitions', output = 'partitions' }
                }
            }
        },

        --shutdown
        shutdown = {
            permission = 'edit',
            ssh = {
                --all distros
                all = {
                    { input = 'shutdown', output = 'shutdown' }
                }
            }
        },
        --reboot
        reboot = {
            permission = 'edit',
            ssh = {
                --all distros
                all = {
                    { input = 'shutdown -r', output = 'reboot' }
                }
            }
        }
    }
}

return config