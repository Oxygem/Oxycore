--[[
    file: modules/service/services/linux/config.lua
    desc: most basic service with Linux commands available to all
]]
local config = {
    group = 'linux',
    parent = 'base',
    name = 'Linux: Generic',

    --javascript file(s) to load on service page
    js = {
        'device.linux.js'
    },


    --tabs
    tabs = {
        { name = 'Overview', js = 'overview', permission = 'view', order = 0, default = true, buttons = {
            { name = 'Status', command = 'status', color = 'lightgreen' },
            { name = 'Process List', command = 'list_process', color = 'green' }
        } },

        {
            name = 'Power',
            js = 'power',
            permission = 'edit',
            buttons = {
                { name = 'Reboot', command = 'reboot', color = 'lightblue', confirm = 'Are you sure you wish to reboot this server' },
                { name = 'Shutdown', command = 'shutdown', color = 'red', confirm = 'You will not be able to reboot the server via Oxypanel' }
            }
        },
        {
            name = 'Firewall',
            js = 'firewall',
            buttons = {
                { name = 'List Rules', command = 'list_firewall', color = 'black' },
                { name = 'Allow IP', command = 'allow_firewall', color = 'green', data = { name = 'IP or subnet', id = 'ip' } },
                { name = 'Block IP', command = 'block_firewall', color = 'blue', data = { name = 'IP or subnet', id = 'ip' } },
                { name = 'Flush Rules', command = 'flush_firewall', color = 'red', confirm = 'This will delete all non-saved firewall rules' }
            },
            permission = 'edit'
        },
        { name = 'File Browser', js = 'files', permission = 'edit' }
    },



    --list of our commands
    commands = {
        --basic status
        status = {
            permission = 'view',
            actions = {
                { action = 'exec', out = 'uptime', command = 'uptime' },
                { action = 'exec', out = 'memory', command = 'free -m' },
                { action = 'exec', out = 'disk', command = 'df -m' }
            }
        },
        list_process = {
            permission = 'view',
            actions = {
                { action = 'exec', out = 'processes', command = 'ps aux' }
            }
        },

        --shutdown
        shutdown = {
            permission = 'edit',
            actions = {
                { action = 'exec', out = 'status', command = 'shutdown now && echo "ok"' }
            }
        },
        --reboot
        reboot = {
            permission = 'edit',
            actions = {
                { action = 'exec', out = 'status', command = 'shutdown -r && echo "ok"' }
            }
        },

        --list firewall (iptables) rules
        list_firewall = {
            permission = 'view',
            actions = {
                { action = 'exec', out = 'rules', command = 'iptables -n -L' }
            }
        },
        --flush firewall rules
        flush_firewall = {
            permission = 'edit',
            actions = {
                { action = 'exec', out = 'status', command = 'iptables -F && echo "ok"' }
            }
        },
        allow_firewall = {
            permission = 'edit',
            actions = function( args )
               if not args.ip then return false, 'IP or subnet not set' end
                local out = {
                    { action = 'exec', out = 'statusin', command = 'iptables -A INPUT -s ' .. args.ip .. ' -j ACCEPT && echo "ok"' },
                    { action = 'exec', out = 'statusout', command = 'iptables -A OUTPUT -d ' .. args.ip .. ' -j ACCEPT && echo "ok"' }
                }
                return out
            end
        },
        block_firewall = {
            permission = 'edit',
            actions = function( args )
               if not args.ip then return false, 'IP or subnet not set' end
                local out = {
                    { action = 'exec', out = 'statusin', command = 'iptables -A INPUT -s ' .. args.ip .. ' -j DROP && echo "ok"' },
                    { action = 'exec', out = 'statusout', command = 'iptables -A OUTPUT -d ' .. args.ip .. ' -j DROP && echo "ok"' }
                }
                return out
            end
        }
    }
}

return config