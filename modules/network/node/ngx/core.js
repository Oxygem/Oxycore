// File: node/ngx/core.js
// Desc: server for browser/client ssh requests (created by luawa/nginx)

'use strict';

// Import global config
module.config = module.parent._autoconf;

// Import server, client & make shared requests table
var server = require( './server.js' ),
    client = require( './client.js' ),
    requests = {};

// Start server & client
server.start( requests, module.config.server_port );
client.start( requests, module.config.client_port );