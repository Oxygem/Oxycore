-- Oxypanel
-- File: config.lua
-- Desc: Oxypanel/Luawa configuration

local config = {
    ------- Basics

    hostname = 'oxypanel.dev',
    cache = true,
    shm_prefix = 'oxypanel_',
    limit_post = 1000,


    ------- Modules

    --oxypanel
    oxypanel = {
        ssh_key = 'SSH_KEY_LOCATION',
        ssh_key_pass = ''
    },

    --database
    database = {
        driver = 'mysql',
        host = '127.0.0.1',
        port = 3306,
        name = 'oxypanel',
        user = 'oxypanel',
        pass = 'DATABASE_PASS'
    },

    --user
    user = {
        keys = 3,
        stretching = 1024,
        secret = 'USER_SECRET_KEY',
        dbprefix = '',
        super = 1,
        reload_key = true
    },

    --node
    node = {
        ngx = {
            client_port = 9000,
            server_port = '/opt/oxypanel/tmp/ngx_server.sock'
        },
        auto = {
            client_port = 9001,
            server_port = '/opt/oxypanel/tmp/auto_server.sock'
        },
        share_key = 'NODE_SHARE_KEY'
    },

    --nginx
    nginx = {
        port = 80
    },

    --debug
    debug = {
        enabled = false
    },

    --template
    template = {
        dir = ''
    },


    ------- Oxypanel Request Maps

    --get requests
    gets = {
        --core requests
        dashboard = 'app/get/dashboard',
        login = 'app/get/login',
        register = 'app/get/register',
        resetpw = 'app/get/resetpw',
        profile = 'app/get/profile',
        logout = 'app/get/logout',

        --module requests
        module = 'app/get/module',

        --object requests
        object = 'app/get/object'
    },

    --post requests
    posts = {
        --core requests
        login = 'app/post/login',
        resetpw = 'app/post/resetpw',
        profile = 'app/post/profile',

        --module requests
        module = 'app/post/module',

        --object requests
        object = 'app/post/object'
    }
}

--return
return config