--oxypanel app config file
local config = {

    ------- Core
    ---

    --basics
    hostname = 'oxypanel.dev', --only when host header not set
    cache = true, --cache template + app files (speeeeeed)
    shm_prefix = 'oxypanel_', --shared memory prefix for nginx
    limit_post = 1000, --limit number of POST arguments to process (prevent DOS, 0 = unlimited)

    ------- Modules
    ---

    --database config
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
        stretching = 3,
        secret = 'SECRET_KEY',
        dbprefix = ''
    },

    --email SMTP config
    email = {
        server = '',
        port = 25,
        user = '',
        pass = '',
        from = ''
    },

    --oxynode (for oxynode.js and inc/js/oxypanel.js)
    oxynode = {
        client_port = 9001, --port the node listens on for SSH requests
        server_port = 9003, --server port, should be a socket
        share_key = 'ANOTHER_SECRET_KEY'
    },

    --oxyngx (for config.nginx and oxynode.lua)
    oxyngx = {
        port = 8084,
        template = 'oxypanel',
        ssh_key = '/root/.ssh/id_rsa'
    },

    --debug
    debug = {
        enabled = false
    },

    --template
    template = {
        dir = '',
        api = true,
        minimize = false
    },


    ------- Oxypanel Request Maps
    ---

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
    }
}

--return
return config