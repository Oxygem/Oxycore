--oxypanel app config file
local config = {

    ------- Core
    ---

    --basics
    hostname = 'oxypanel.dev', --only when host header not set
    cache = false, --cache template + app files (speeeeeed)
    shm_prefix = 'oxypanel_', --shared memory prefix for nginx

    --get requests
    gets = {
        --core requests
        dashboard = { file = 'app/get/dashboard' },
        login = { file = 'app/get/login' },
        register = { file = 'app/get/register' },
        resetpw = { file = 'app/get/resetpw' },
        profile = { file = 'app/get/profile' },
        logout = { file = 'app/get/logout' },

        --module requests
        module = { file = 'app/get/module' },

        --object requests
        object = { file = 'app/get/object' }
    },

    --post requests
    posts = {
        --core requests
        login = { file = 'app/post/login' },
        register = { file = 'app/post/register' },
        resetpw = { file = 'app/post/resetpw' },
        profile = { file = 'app/post/profile' },

        --module requests
        module = { file = 'app/post/module' },

        --object requests
        object = { file = 'app/post/object' }
    },



    ------- Modules
    ---

    --debug
    debug = {
        enabled = true
    },

    --template
    template = {
        dir = '',
        api = true,
        minimize = false
    },

    --database
    database = {
        driver = 'mysql',
        host = '127.0.0.1',
        port = 3306,
        name = 'oxypanel',
        user = 'root',
        pass = 'root'
    },

    --user
    user = {
        keys = 3,
        stretching = 32,
        secret = 'FnJPZQ3hwlIM5pzJwUc8my1uS8xjsC84bFaPU4SoscymEvlbZprZx1oLcveNNV1ROlXCgRqsgSV4BIjTlezQ73WSh',
        dbprefix = 'admin_'
    },

    --email (not in use yet)
    email = {
        server = '',
        port = 25,
        user = '',
        pass = '',
        from = ''
    },

    --oxynode (this file is used when building oxynode.js)
    oxynode = {
        client_port = 9001,
        server_port = 9003,
        share_key = 'M9LkaVeNMAIIUhvN5xDKa1NORmU8TkO3p7IBNA27ArAso7wVySm1wUwxnQHILD8dPvR91akZNqU6UYjCdwbqvrmqN'
    },

    --oxyngx (for config.nginx and oxynode.lua)
    oxyngx = {
        port = 8084,
        template = 'oxypanel',
        ssh_key = '/path/id.rsa' --needs valid private key where all the servers you add have it's public key
    }
}

--return
return config