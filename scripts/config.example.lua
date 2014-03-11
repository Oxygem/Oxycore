-- Oxypanel
-- File: config.lua
-- Desc: Oxypanel configuration

local config = {
    ------- Basics

    hostname = 'oxypanel.dev', --only used when host header not set
    cache = true, --cache template + app files (speeeeeed)
    shm_prefix = 'oxypanel_', --shared memory prefix for nginx
    limit_post = 1000, --limit number of POST arguments to process (prevent DOS, 0 = unlimited)


    ------- Modules

    --oxypanel
    oxypanel = {
        ssh_key = 'SSH_KEY_LOCATION',
        ssh_key_pass = 'SSH_KEY_PASSPHRASE'
    },

    --database
    database = {
        driver = 'mysql',
        host = '127.0.0.1',
        port = 3306,
        name = 'DATABASE_NAME',
        user = 'DATABASE_USER',
        pass = 'DATABASE_PASS'
    },

    --user
    user = {
        keys = 3,
        stretching = 3,
        secret = 'USER_SECRET_KEY',
        dbprefix = ''
    },

    --node
    node = {
        --ports for ngx/auto nodes client/server listens
        --in production: always set server_port's to file string aka socket
        ngx = {
            client_port = 9001,
            server_port = 9003
        },
        auto = {
            client_port = 9005,
            server_port = 9007
        },
        share_key = 'NODE_SECRET_KEY'
    },

    --nginx
    nginx = {
        port = 9000
    },

    --debug
    debug = {
        enabled = true
    },

    --template
    template = {
        dir = '',
        minimize = false
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