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
            { name = 'Refresh Status', command = 'status', color = 'lightgreen' },
            { name = 'Process List', command = 'list_process', color = 'green' },
            { name = 'Open Console', js = 'console', command = 'console', color = 'black' }
        } },

        { name = 'Power', js = 'power', permission = 'edit', buttons = {
                { name = 'Reboot', command = 'reboot', color = 'lightblue', confirm = 'Are you sure you wish to reboot this server' },
                { name = 'Shutdown', command = 'shutdown', color = 'red', confirm = 'You will not be able to reboot the server via Oxypanel' }
        } },

        { name = 'Users', js = 'users', permission = 'edit', buttons = {
                { name = 'List Users', command = 'status', color = 'black' },
                { name = 'Add User', command = 'status', color = 'green', data = { name = 'IP or subnet', id = 'ip' } }
        } },

        { name = 'Firewall', js = 'firewall', permission = 'edit', buttons = {
                { name = 'List Rules', command = 'list_firewall', color = 'black' },
                { name = 'Allow IP', command = 'allow_firewall', color = 'green', data = { name = 'IP or subnet', id = 'ip' } },
                { name = 'Block IP', command = 'block_firewall', color = 'blue', data = { name = 'IP or subnet', id = 'ip' } },
                { name = 'Flush Rules', command = 'flush_firewall', color = 'red', confirm = 'This will delete all non-saved firewall rules' }
        } }
    },



    --list of our commands
    commands = {
        --add linux device
        add = {
            actions = function( args )
                --get ssh pubkey
                local f, err = io.open( oxy.config.oxyngx.ssh_key .. '.pub', 'r' )
                if not f then return false, err end
                local key, err = f:read( '*a' )
                f:close()
                if not key then return false, err end

                --list actions
                local out = {
                    --check if .ssh exists
                    { action = 'exec', command = 'find ~/.ssh/',
                        expect = { signal = 0, fail = {
                            { action = 'exec', command = 'mkdir ~/.ssh/', expect = { signal = 0, error = 'Could not create ~/.ssh' } }
                        }}
                    },

                    --check if .ssh/authorized_keys exists
                    { action = 'exec', command = 'find ~/.ssh/authorized_keys',
                        expect = { signal = 0, fail = {
                            { action = 'exec', command = 'touch ~/.ssh/authorized_keys', expect = { signal = 0, error = 'Could not create ~/.ssh/authorized_keys' } }
                        }}
                    },

                    --check if the key is already in .ssh/authorized_keys
                    { action = 'exec', command = 'grep -q "' .. key .. '" ~/.ssh/authorized_keys',
                        expect = { signal = 0, fail = {
                            { action = 'exec', command = 'echo "' .. key .. '" >> ~/.ssh/authorized_keys', expect = { signal = 0, error = 'Could not add key to ~/.ssh/authorized_keys' } }
                        }}
                    }
                }

                return out
            end
        },

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