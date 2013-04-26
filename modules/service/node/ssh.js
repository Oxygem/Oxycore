//import global config
var config = module.parent._autoconf;
//import modules
var randomstring = require( 'randomstring' ), net = require( 'net' ), socketio = require( 'socket.io' ), ssh = require( 'ssh2' ), fs = require( 'fs' );
//store requests (each stores a client [socket.io] and a server [ssh2] socket)
var requests = [];





//our 'event loop'
var evloop = {
    //step in our ssh2 <=> client
    step: function( key ) {
        //setup some bits
        var request = requests[key];
        if( request.commands.length > 0 ) {
            var command = requests[key].commands.shift();
            //expect?
            if( command.expect ) {
                request.expect = command.expect;
            } else {
                request.expect = false;
            }
            //execute command via ssh
            request.server.socket.exec( command.input, function( err, stream ) {
                if( err )
                    return request.client.socket.emit( 'command_error', err );

                request.client.socket.emit( 'command_start', command.output );
                //grab output
                stream.on( 'data', function( data, status ) {
                    data = String( data );
                    var lines = data.split( '\n' );
                    request.lastline = lines[lines.length - 2];
                    request.client.socket.emit( 'command_data', data );
                });
                //when done, do next step
                stream.on( 'exit', function( code, signal ) {
                    //expect?
                    if( request.expect ) {
                        console.log( request.expect );
                    }
                    //output result
                    var result = code == 0 ? 'SUCCESS' : 'ERROR';
                    request.client.socket.emit( 'command_end', result );
                    console.log( '[' + key + '] "' + command.input + '" complete' );
                    setTimeout( function() {
                        evloop.step( key );
                    }, 100 );
                });
            });
        //no more commands
        } else {
            //ended?
            request.client.socket.emit( 'request_end', 'ENDED' );
            if( request.client.socket.server )
                request.client.socket.end();

            request.server.socket.end();
            requests[key] = undefined;
            console.log( '[' + key + '] Complete, removed' );
        }
    },

    //setup the server (ssh) side
    setupServer: function( key ) {
        var request = requests[key];
        //build server socket
        var server = new ssh();
        server.on( 'ready', function() {
            console.log( '[' + key + '] SSH connection established' );
            //start it up
            evloop.step( key );
        });
        server.on( 'error', function( err ) {
            console.log( '[' + key + '] SSH connection error: ' + err );
        })
        //work out params
        var server_params = {
            host: request.server.host,
            port: request.server.port,
            username: request.server.user
        };
        if( request.server.key )
            server_params.privateKey = require('fs').readFileSync( request.server.key );
        else if( request.server.password )
            server_params.password = request.server.password;
        //connect & return
        server.connect( server_params );
        return server;
    }
}





//simple net listen for nginx to issue commands (add request or capture request)
var listen_nginx = net.createServer( function( ngx ) {
    //text > binary
    ngx.setEncoding( 'utf8' );
    //receive json bundle
    ngx.on( 'data', function( data ) {
        //try to convert to json, if not valid w/e (up to lua to format correctly)
        try {
            //get data
            var data = JSON.parse( data );
            //validate
            if( !data.share_key )
                throw( 'Missing share_key' );
            //are we making a request for ssh using a request key?
            if( data.key && requests[data.key] ) {
                //setup SSH server socket
                requests[data.key].server.socket = evloop.setupServer( data.key );
                //setup local ngx server as cient
                requests[data.key].client.socket.server = true; //know to end/terminate socket (rather than keeping websocket open) after action complete
                requests[data.key].client.socket.emit = function( type, message ) {
                    ngx.write( JSON.stringify( { type: type, message: message } ) + '\n' );
                }
                //end it
                requests[data.key].client.socket.end = function() {
                    ngx.end();
                }
                //step
                evloop.step( data.key );
                //and odne!
                return true;
            }

            //adding user request
            if( !data.user || !data.commands || !data.server )
                throw( 'Missing user, commands or server' );
            if( data.share_key != config.share_key )
                throw( 'share_key mismatch' );
            for( i = 1; i <= config.user_strength; i++ )
                if( !data.user['key' + i] )
                    throw( 'Missing user key: ' + i );
            //generate key for request
            var key = randomstring.generate( 64 );
            //build our request
            requests[key] = {
                interactive: data.interactive,
                commands: data.commands,
                user: data.user,
                server: data.server,
                client: { socket: {} }
            }
            //drop connection once data added
            ngx.write( 'ACCEPTED\n' + key + '\n' );
            ngx.end();
            console.log( '[Nginx Listen]: Request added ' + key );
        } catch( e ) {
            //cya!
            ngx.write( 'INVALID REQUEST\n' );
            ngx.end();
            console.log( '[Nginx Listen]: Invalid Request: ' + e );
        }
    });
});
listen_nginx.on( 'error', function( e ) {
    console.log( e );
});
listen_nginx.listen( config.server_port, function() { console.log( '[Nginx Listen]: Started' ) });





//socket.io listen for clients, add to valid request
var listen_clients = socketio.listen( config.client_port, { 'log level': 1 });
if( listen_clients ) console.log( '[Client Listen]: Started' );
listen_clients.sockets.on( 'connection', function( client ) {
    //make request
    client.on( 'capture_request', function( data ) {
        //try to convert to json
        try {
            //get data
            var data = JSON.parse( data );
            //validate
            if( !data.key || !data.user )
                throw( 'Missing key or user' );
            if( !requests[data.key] )
                throw( 'Invalid request key' );
            var request = requests[data.key];
            //user matches?
            if( request.user.id != data.user.id )
                throw( 'User id mismatch' );
            for( i = 1; i <= config.user_strength; i++ )
                if( !data.user['key' + i] || data.user['key' + i] != request.user['key' + i] )
                    throw( 'Invalid user keys' );
            console.log( '[' + data.key + '] Client connected' );
            client.emit( 'request_start', 'ACCEPTED' );
            //interactive?
            if( request.interactive ) {
                //add command to existing request
                client.on( 'add_command', function( data ) {
                    request.commands[request.commands.length] = data
                    client.emit( 'add_command', 'ACCEPTED' );
                });
            }
            //assign client socket
            requests[data.key].client.socket = client;
            //assign server socket
            var server = evloop.setupServer( data.key );

            //assign server socket
            requests[data.key].server.socket = server;
        } catch( e ) {
            client.emit( 'request_start', 'INVALID REQUEST: ' + e );
        }
    });
});