--[[
    file: modules/service/services/linux/config.lua
    desc: most basic service with Linux commands available to all
]]
local config = {
    hidden = true, --no need to display anywhere
    parent = 'base',

    --javascript file(s) to load on service page
    js = {
        'service/service.linux.js'
    },

    --tabs
    tabs = {
        {
            name = 'Control',
            js = 'control',
            buttons = {
                { name = 'Status', command = 'status', color = 'black' },
                { name = 'Reboot', command = 'reboot', color = 'lightblue' },
                { name = 'Shutdown', command = 'shutdown', color = 'red', confirm = 'You will not be able to reboot the server via Oxypanel' }
            },
            default = true
        },
        {
            name = 'Firewall',
            js = 'firewall',
            buttons = {
                { name = 'List', command = 'list_firewall', color = 'black' },
                { name = 'Allow IPs', command = 'allow_firewall', color = 'green', data = { name = 'IP or subnet', id = 'ip' } },
                { name = 'Block IPs', command = 'block_firewall', color = 'blue', data = { name = 'IP or subnet', id = 'ip' } },
                { name = 'Flush', command = 'flush_firewall', color = 'red', confirm = 'This will delete all non-saved firewall rules' }
            },
            permission = 'edit'
        },
        {
            name = 'Packages',
            js = 'packages',
            buttons = {
                { name = 'Update', command = 'update_packages', color = 'green' },
                { name = 'Search', command = 'search_packages', color = 'lightblue', data = { name = 'Text to search', id = 'package' } },
                { name = 'Install', command = 'install_package', color = 'lightgreen', data = { name = 'Package to install', id = 'package' } }
            },
            permission = 'edit'
        },
        { name = 'Software', js = 'software', permission = 'edit' },
        { name = 'File Browser', js = 'files', permission = 'edit' },
        { name = 'Console', js = 'console', permission = 'console' }
    },

    --list of our commands
    commands = {
        --basic status
        status = {
            permission = 'view',
            ssh = {
                --all distros
                all = {
                    { input = 'uptime', output = 'uptime' },
                    { input = 'free -m', output = 'memory' },
                    { input = 'df -m', output = 'disk' }
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
        },

        --list firewall (iptables) rules
        list_firewall = {
            permission = 'view',
            ssh = {
                all = {
                    { input = 'iptables -n -L', output = 'firewall' }
                }
            }
        },
        --flush firewall rules
        flush_firewall = {
            permission = 'edit',
            ssh = {
                all = {
                    { input = 'iptables -F && echo "iptables flushed"', output = 'status' }
                }
            }
        },
        allow_firewall = {
            permission = 'edit',
            ssh = function( args )
               if not args.ip then return false, 'IP or subnet not set' end
                local out = {
                    all = {
                        { input = 'iptables -A INPUT -s ' .. args.ip .. ' -j ACCEPT && echo "INPUT allowed"', output = 'status' },
                        { input = 'iptables -A OUTPUT -d ' .. args.ip .. ' -j ACCEPT && echo "OUTPUT allowed"', output = 'status' }
                    }
                }
                return out
            end
        },
        block_firewall = {
            permission = 'edit',
            ssh = function( args )
                if not args.ip then return false, 'IP or subnet not set' end
                local out = {
                    all = {
                        { input = 'iptables -A INPUT -s ' .. args.ip .. ' -j DROP && echo "INPUT blocked"', output = 'status' },
                        { input = 'iptables -A OUTPUT -d ' .. args.ip .. ' -j DROP && echo "OUTPUT blocked"', output = 'status' }
                    }
                }
                return out
            end
        },

        --update installed packages
        update_packages = {
            permission = 'edit',
            ssh = {
                debian = {
                    { input = 'apt-get update && apt-get upgrade -y', output = 'update' }
                },

                centos = {
                    { input = 'yum update -y', output = 'update' }
                }
            }
        },
        --search packages
        search_packages = {
            permission = 'edit',
            ssh = function( args )
                if not args.package then return false, 'args.package not set' end
                local out =  {
                    debian = {
                        { input = 'apt-cache search ' .. args.package, output = 'status' }
                    },
                    centos = {
                        { input = 'yum search ' .. args.package, output = 'status' }
                    }
                }
                return out
            end
        },
        --install a package
        install_package = {
            permission = 'edit',
            ssh = function( args )
                if not args.package then return false, 'Package not set' end
                local out =  {
                    debian = {
                        { input = 'apt-get install ' .. args.package .. ' -y', output = 'status' }
                    },
                    centos = {
                        { input = 'yum install ' .. args.package .. ' -y', output = 'status' }
                    }
                }
                return out
            end
        }
    }
}

return config